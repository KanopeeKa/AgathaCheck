import { publicError } from '../../config/security.js';
import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../../lib/calendarDate.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import {
  listMissedOccurrenceIds,
  listOpenOccurrences,
  materialiseAfterOccurrenceClose,
  occurrenceToMap,
  resolveCompletedOn,
} from '../../lib/occurrenceScheduling.js';
import { tryAutoCloseRecurringWithEndDate } from '../../lib/occurrenceLifecycle.js';
import { extractUserId } from './shared.js';

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

async function loadOccurrence(pool, entryId, occId) {
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
      await tryAutoCloseRecurringWithEndDate(pool, entry, asOf);
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
          await pool.query(
            `UPDATE health_occurrences SET status = 'skipped', marked_at = $1,
              marked_by_user_id = $2, updated_at = NOW()
             WHERE id = ANY($3::uuid[]) AND health_entry_id = $4 AND status = 'pending'`,
            [markedAt, userId, earlier, entryId]
          );
        }
      }

      const result = await pool.query(
        `UPDATE health_occurrences SET status = 'completed', completed_on = $1,
          marked_at = $2, marked_by_user_id = $3, notes = $4, updated_at = NOW()
         WHERE id = $5 AND health_entry_id = $6 AND status = 'pending'
         RETURNING *`,
        [completedOn, markedAt, userId, notes, occ.id, entryId]
      );
      await materialiseAfterOccurrenceClose(pool, entry);
      const refreshed = await loadEntry(pool, entryId, userId);
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
      const row = result.rows[0];
      row.marked_by_name = null;
      res.json({
        occurrence: occurrenceToMap(row),
        next_due_date: dateToIsoDate(refreshed.next_due_date),
      });
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
      const result = await pool.query(
        `UPDATE health_occurrences SET status = 'skipped', marked_at = $1,
          marked_by_user_id = $2, notes = $3, updated_at = NOW()
         WHERE id = $4 AND health_entry_id = $5 AND status = 'pending'
         RETURNING *`,
        [markedAt, userId, notes, occ.id, entryId]
      );
      await materialiseAfterOccurrenceClose(pool, entry);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.skipped',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { occurrence_id: occ.id },
        req,
      });
      res.json(occurrenceToMap(result.rows[0]));
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
      await pool.query(
        `UPDATE health_occurrences SET status = 'skipped', marked_at = $1,
          marked_by_user_id = $2, updated_at = NOW()
         WHERE id = ANY($3::uuid[]) AND health_entry_id = $4 AND status = 'pending'`,
        [markedAt, userId, missedIds, entryId]
      );
      await materialiseAfterOccurrenceClose(pool, entry);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_occurrence.skip_missed',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: entry.pet_id,
        metadata: { count: missedIds.length },
        req,
      });
      res.json({ skipped: missedIds, count: missedIds.length });
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
      const occ = await loadOccurrence(pool, entryId, req.params.occId);
      if (!occ || !['completed', 'skipped'].includes(occ.status)) {
        return res.status(400).json({ error: 'Only closed occurrences can be undone' });
      }
      const result = await pool.query(
        `UPDATE health_occurrences SET status = 'pending', completed_on = NULL,
          marked_at = NULL, marked_by_user_id = NULL, notes = '', updated_at = NOW()
         WHERE id = $1 AND health_entry_id = $2
         RETURNING *`,
        [occ.id, entryId]
      );
      const { syncNextDueDateFromOccurrences } = await import('../../lib/occurrenceScheduling.js');
      await syncNextDueDateFromOccurrences(pool, entryId);
      res.json(occurrenceToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}

/**
 * Complete the oldest pending occurrence for mark-taken compatibility.
 */
export async function completeOldestPendingOccurrence(pool, entryId, userId, body = {}, req = null) {
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
  const entry = (await pool.query('SELECT * FROM health_entries WHERE id = $1', [entryId])).rows[0];
  const completedOn = resolveCompletedOn(body.completed_on || body.completedOn);
  const notes = body.notes || '';
  const markedAt = new Date();
  const result = await pool.query(
    `UPDATE health_occurrences SET status = 'completed', completed_on = $1,
      marked_at = $2, marked_by_user_id = $3, notes = $4, updated_at = NOW()
     WHERE id = $5 AND status = 'pending'
     RETURNING *`,
    [completedOn, markedAt, userId, notes, occId]
  );
  await materialiseAfterOccurrenceClose(pool, entry);
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
  return result.rows[0];
}
