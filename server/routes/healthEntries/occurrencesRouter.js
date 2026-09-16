import { publicError } from '../../config/security.js';
import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../../lib/calendarDate.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { adjustCadence } from '../../lib/care/schedule/adjustCadence.js';
import { completeOccurrence } from '../../lib/care/schedule/completeOccurrence.js';
import { rescheduleOccurrence } from '../../lib/care/schedule/rescheduleOccurrence.js';
import {
  pauseSeries,
  resumeSeries,
} from '../../lib/care/schedule/pauseResumeSeries.js';
import {
  skipMissedOccurrences,
  skipOccurrence,
} from '../../lib/care/schedule/skipOccurrence.js';
import { undoLastAction } from '../../lib/care/schedule/undoLastAction.js';
import {
  listMissedOccurrenceIds,
  listOpenOccurrences,
  occurrenceToMap,
  resolveCompletedOn,
} from '../../lib/occurrenceScheduling.js';
import { tryAutoCloseRecurringWithEndDate } from '../../lib/occurrenceLifecycle.js';
import { extractUserId, healthEntryToMap } from './shared.js';
import {
  isWeightMonitoringEntry,
  WEIGHT_GENERIC_COMPLETE_ERROR,
} from './weightOccurrenceCompletion.js';

async function loadEntry(pool, entryId, userId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return null;
  }
  const result = await pool.query(
    'SELECT * FROM health_entries WHERE id = $1',
    [entryId]
  );
  return result.rows[0] || null;
}

export async function loadOccurrence(pool, entryId, occId) {
  const result = await pool.query(
    `SELECT ho.*,
      TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
     FROM health_occurrences ho
     LEFT JOIN users u ON u.id = ho.marked_by_user_id
     WHERE ho.id = $1 AND ho.health_entry_id = $2`,
    [occId, entryId]
  );
  return result.rows[0] || null;
}

function asOfFromRequest(req) {
  const body = req.body || {};
  const q = req.query || {};
  return (
    normalizeCalendarDateInput(body.as_of || body.asOf || q.as_of || q.asOf)
    || todayCalendarIso()
  );
}

export function registerOccurrenceRoutes(router, pool) {
  router.get('/:id/occurrences', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entry = await loadEntry(pool, req.params.id, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const asOf = asOfFromRequest(req);
      await tryAutoCloseRecurringWithEndDate(pool, entry, todayCalendarIso());
      const status = req.query.status || 'open';
      if (status === 'open') {
        const rows = await listOpenOccurrences(pool, entry.id, asOf);
        return res.json(rows);
      }
      const result = await pool.query(
        `SELECT ho.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM health_occurrences ho
         LEFT JOIN users u ON u.id = ho.marked_by_user_id
         WHERE ho.health_entry_id = $1 AND ho.status IN ('completed', 'skipped')
         ORDER BY ho.scheduled_date DESC,
           COALESCE(ho.scheduled_time, '00:00:00'::time) DESC`,
        [entry.id]
      );
      res.json(result.rows.map(occurrenceToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/occurrences/:occId/complete', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      if (isWeightMonitoringEntry(entry)) {
        return res.status(400).json({ error: WEIGHT_GENERIC_COMPLETE_ERROR });
      }
      const occ = await loadOccurrence(pool, entryId, req.params.occId);
      if (!occ || occ.status !== 'pending') {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      const body = req.body || {};
      const completedOn = resolveCompletedOn(body.completed_on || body.completedOn);
      const notes = body.notes || '';
      const markedAt = new Date();
      const skipEarlier = Boolean(body.skip_earlier_missed || body.skipEarlierMissed);

      if (skipEarlier) {
        const missedIds = await listMissedOccurrenceIds(pool, entryId, asOfFromRequest(req));
        const earlier = missedIds.filter((id) => id !== occ.id);
        if (earlier.length > 0) {
          await skipMissedOccurrences(pool, {
            entry,
            userId,
            occurrenceIds: earlier,
            markedAt,
            todayIso: asOfFromRequest(req),
          });
        }
      }

      const completion = await completeOccurrence(pool, {
        entry,
        occurrenceId: occ.id,
        userId,
        completedOn,
        notes,
        markedAt,
        todayIso: asOfFromRequest(req),
      });
      if (!completion) {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.completed',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { occurrence_id: occ.id },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: entry.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'complete_occurrence', entry_type: entry.type },
      });
      const row = completion.occurrence;
      row.marked_by_name = null;
      res.json({
        occurrence: occurrenceToMap(row),
        next_due_date: completion.nextDueDate,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/occurrences/:occId/reschedule', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const occ = await loadOccurrence(pool, entryId, req.params.occId);
      if (!occ || occ.status !== 'pending') {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      const body = req.body || {};
      const scheduledDate = normalizeCalendarDateInput(
        body.scheduled_date || body.scheduledDate,
      );
      if (!scheduledDate) {
        return res.status(400).json({ error: 'scheduled_date is required' });
      }
      const reasonCode = body.reason_code || body.reasonCode || null;
      const reasonNote = body.reason_note || body.reasonNote || body.notes || null;
      const rescheduledAt = new Date();
      const result = await rescheduleOccurrence(pool, {
        entry,
        occurrenceId: occ.id,
        userId,
        newScheduledDate: scheduledDate,
        reasonCode,
        reasonNote,
        rescheduledAt,
      });
      if (!result) {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.rescheduled',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { occurrence_id: occ.id, scheduled_date: scheduledDate },
        req,
      });
      res.json(occurrenceToMap(result.occurrence));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/occurrences/:occId/skip', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const occ = await loadOccurrence(pool, entryId, req.params.occId);
      if (!occ || occ.status !== 'pending') {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      const notes = (req.body || {}).notes || '';
      const markedAt = new Date();
      const skipped = await skipOccurrence(pool, {
        entry,
        occurrenceId: occ.id,
        userId,
        notes,
        markedAt,
        todayIso: asOfFromRequest(req),
      });
      if (!skipped) {
        return res.status(404).json({ error: 'Occurrence not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.skipped',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { occurrence_id: occ.id },
        req,
      });
      res.json(occurrenceToMap(skipped.occurrence));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/occurrences/skip-missed', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const asOf = asOfFromRequest(req);
      const missedIds = await listMissedOccurrenceIds(pool, entryId, asOf);
      if (missedIds.length === 0) {
        return res.json({ skipped: [], count: 0 });
      }
      const markedAt = new Date();
      const batch = await skipMissedOccurrences(pool, {
        entry,
        userId,
        occurrenceIds: missedIds,
        markedAt,
        todayIso: asOf,
      });
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.skip_missed',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { count: batch.count },
        req,
      });
      res.json({ skipped: batch.skipped, count: batch.count });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/adjust-cadence', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const body = req.body || {};
      const effectiveFrom = normalizeCalendarDateInput(
        body.effective_from || body.effectiveFrom,
      );
      if (!effectiveFrom) {
        return res.status(400).json({ error: 'effective_from is required' });
      }
      const adjusted = await adjustCadence(pool, {
        entry,
        userId,
        effectiveFrom,
        frequency: body.frequency,
        frequencyInterval: body.frequency_interval ?? body.frequencyInterval,
        frequencyDays: body.frequency_days ?? body.frequencyDays,
        recurrenceAnchor: body.recurrence_anchor ?? body.recurrenceAnchor,
        reasonCode: body.reason_code || body.reasonCode || null,
        reasonNote: body.reason_note || body.reasonNote || body.notes || null,
        todayIso: asOfFromRequest(req),
      });
      if (!adjusted) {
        return res.status(400).json({ error: 'Entry cadence cannot be adjusted' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.cadence_adjusted',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: {
          effective_from: effectiveFrom,
          schedule_event_id: adjusted.scheduleEventId,
        },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: entry.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'adjust_cadence', entry_type: entry.type },
      });
      adjusted.entry.pet_name = null;
      res.json({
        entry: healthEntryToMap(adjusted.entry),
        next_due_date: adjusted.nextDueDate,
        schedule_event_id: adjusted.scheduleEventId,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/pause', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const body = req.body || {};
      const paused = await pauseSeries(pool, {
        entry,
        userId,
        pausedFrom: body.paused_from || body.pausedFrom,
        reasonCode: body.reason_code || body.reasonCode || null,
        reasonNote: body.reason_note || body.reasonNote || body.notes || null,
      });
      if (!paused) {
        return res.status(400).json({ error: 'Entry cannot be paused' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.paused',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { paused_since: paused.pausedSince },
        req,
      });
      paused.entry.pet_name = null;
      res.json(healthEntryToMap(paused.entry));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/resume', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const body = req.body || {};
      const resumed = await resumeSeries(pool, {
        entry,
        userId,
        reasonCode: body.reason_code || body.reasonCode || null,
        reasonNote: body.reason_note || body.reasonNote || body.notes || null,
      });
      if (!resumed) {
        return res.status(400).json({ error: 'Entry cannot be resumed' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.resumed',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: {},
        req,
      });
      resumed.entry.pet_name = null;
      res.json(healthEntryToMap(resumed.entry));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/occurrences/:occId/undo', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const entry = await loadEntry(pool, entryId, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const occId = req.params.occId;

      const undone = await undoLastAction(pool, {
        entry,
        userId,
        occurrenceId: occId,
      });
      if (!undone || !undone.occurrence) {
        return res.status(400).json({
          error: 'No matching schedule action to undo for this occurrence; use POST /:id/schedule/undo',
        });
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.undone',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { occurrence_id: occId, action_type: undone.actionType },
        req,
      });
      const row = undone.occurrence;
      row.marked_by_name = null;
      res.json(occurrenceToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}

/**
 * Complete the oldest pending occurrence for mark-taken compatibility.
 */
export async function completeOldestPendingOccurrence(pool, entryId, userId, body = {}, req = null) {
  const entry = (await pool.query('SELECT * FROM health_entries WHERE id = $1', [entryId])).rows[0];
  if (isWeightMonitoringEntry(entry)) {
    const err = new Error(WEIGHT_GENERIC_COMPLETE_ERROR);
    err.statusCode = 400;
    throw err;
  }
  const pending = await pool.query(
    `SELECT id FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending'
     ORDER BY scheduled_date ASC,
       COALESCE(scheduled_time, '00:00:00'::time) ASC
     LIMIT 1`,
    [entryId]
  );
  if (pending.rows.length === 0) return null;
  const occId = pending.rows[0].id;
  const completedOn = resolveCompletedOn(body.completed_on || body.completedOn);
  const notes = body.notes || '';
  const markedAt = new Date();
  const todayIso = req?.query?.as_of
    ? normalizeCalendarDateInput(req.query.as_of) || todayCalendarIso()
    : todayCalendarIso();
  const completion = await completeOccurrence(pool, {
    entry,
    occurrenceId: occId,
    userId,
    completedOn,
    notes,
    markedAt,
    todayIso,
  });
  if (!completion) return null;
  if (req) {
    logAuditEventSafe(pool, {
      actorUserId: userId,
      action: 'health_occurrence.completed',
      resourceType: 'health_entry',
      resourceId: entryId,
      petId: entry.pet_id,
      metadata: { occurrence_id: occId, via: 'mark-taken' },
      req,
    });
  }
  return completion.occurrence;
}
