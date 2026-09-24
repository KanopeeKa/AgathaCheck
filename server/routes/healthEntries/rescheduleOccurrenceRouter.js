import { publicError } from '../../config/security.js';
import {
  normalizeCalendarDateInput,
  todayCalendarIso,
} from '../../lib/calendarDate.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { rescheduleOccurrence } from '../../lib/care/schedule/rescheduleOccurrence.js';
import {
  loadLastClosedOccurrenceDateIso,
  validateReschedule,
} from '../../lib/care/schedule/validateReschedule.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { occurrenceToMap } from '../../lib/occurrenceScheduling.js';
import { extractUserId } from './shared.js';
import { loadOccurrence } from './occurrencesRouter.js';

async function loadEntry(pool, entryId, userId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return null;
  }
  const result = await pool.query(
    'SELECT * FROM health_entries WHERE id = $1',
    [entryId],
  );
  return result.rows[0] || null;
}

export function registerRescheduleOccurrenceRoutes(router, pool) {
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
      const todayIso = todayCalendarIso();
      const occurrenceScheduledDate = dateToIsoDate(occ.scheduled_date);
      const lastClosedDate = await loadLastClosedOccurrenceDateIso(pool, entry);
      const validation = validateReschedule({
        entry,
        occurrenceScheduledDate,
        newDate: scheduledDate,
        todayIso,
        lastClosedDate,
      });
      if (!validation.ok) {
        return res.status(400).json({ error: validation.error });
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
      res.json({
        occurrence: occurrenceToMap(result.occurrence),
        warnings: validation.warnings,
        next_due_date: result.nextDueDate,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
