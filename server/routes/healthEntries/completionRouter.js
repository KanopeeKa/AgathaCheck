import { publicError } from '../../config/security.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { extractUserId, healthEntryToMap, historyToMap } from './shared.js';
import { completeOldestPendingOccurrence } from './occurrencesRouter.js';
import { closeHealthEntrySeries } from '../../lib/occurrenceLifecycle.js';
import { syncNextDueDateFromOccurrences } from '../../lib/occurrenceScheduling.js';
import {
  isWeightMonitoringEntry,
  WEIGHT_GENERIC_COMPLETE_ERROR,
} from './weightOccurrenceCompletion.js';

const NO_PENDING_OCCURRENCE_ERROR = 'No pending occurrence; use occurrence complete API';

export function registerCompletionRoutes(router, pool) {
  router.post('/:id/mark-taken', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const body = req.body || {};
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const existing = await pool.query(
        'SELECT he.* FROM health_entries he WHERE he.id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];
      const occPending = await pool.query(
        `SELECT id FROM health_occurrences WHERE health_entry_id = $1 AND status = 'pending' LIMIT 1`,
        [entryId]
      );
      if (occPending.rows.length === 0) {
        return res.status(400).json({ error: NO_PENDING_OCCURRENCE_ERROR });
      }
      if (isWeightMonitoringEntry(row)) {
        return res.status(400).json({ error: WEIGHT_GENERIC_COMPLETE_ERROR });
      }
      const closed = await completeOldestPendingOccurrence(pool, entryId, userId, body, req);
      if (!closed) {
        return res.status(400).json({ error: NO_PENDING_OCCURRENCE_ERROR });
      }
      const updated = await pool.query('SELECT * FROM health_entries WHERE id = $1', [entryId]);
      const entry = updated.rows[0];
      entry.pet_name = null;
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.marked_complete',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type, frequency: row.frequency || 'once', via: 'mark-taken' },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: row.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'complete', entry_type: row.type },
      });
      return res.json(healthEntryToMap(entry));
    } catch (err) {
      if (err.statusCode === 400) {
        return res.status(400).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/undo-complete', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const latestHist = await pool.query(
        `SELECT * FROM health_history WHERE health_entry_id = $1
         ORDER BY changed_at DESC LIMIT 1`,
        [entryId]
      );
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];

      if (latestHist.rows.length === 0 || latestHist.rows[0].status !== 'completed') {
        const closedOcc = await pool.query(
          `SELECT * FROM health_occurrences
           WHERE health_entry_id = $1 AND status = 'completed'
           ORDER BY marked_at DESC NULLS LAST LIMIT 1`,
          [entryId]
        );
        if (closedOcc.rows.length === 0) {
          return res.status(400).json({ error: 'No completed occurrence to unmark' });
        }
        const occ = closedOcc.rows[0];
        await pool.query(
          `UPDATE health_occurrences SET status = 'pending', completed_on = NULL,
            marked_at = NULL, marked_by_user_id = NULL, notes = '', updated_at = NOW()
           WHERE id = $1`,
          [occ.id]
        );
        const restoreDue = dateToIsoDate(occ.scheduled_date || row.start_date);
        const result = await pool.query(
          `UPDATE health_entries SET status = 'active', completed_on = NULL, completed_at = NULL,
            next_due_date = CASE WHEN frequency = 'once' THEN $1 ELSE COALESCE($1, next_due_date) END,
            updated_at = NOW()
           WHERE id = $2 RETURNING *`,
          [restoreDue, entryId]
        );
        await syncNextDueDateFromOccurrences(pool, entryId);
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'health_entry.completion_undone',
          resourceType: 'health_entry',
          resourceId: entryId,
          petId: row.pet_id,
          metadata: { entry_type: row.type, via: 'occurrence' },
          req,
        });
        recordPetActivityForPet(pool, {
          petId: row.pet_id,
          actorUserId: userId,
          eventType: 'health_log',
          metadata: { action: 'undo_complete', entry_type: row.type },
        });
        const entry = result.rows[0];
        entry.pet_name = null;
        return res.json(healthEntryToMap(entry));
      }

      const lastCompleted = latestHist.rows[0];
      await pool.query(
        "UPDATE health_history SET status = 'undone' WHERE id = $1",
        [lastCompleted.id]
      );
      const restoreDue = dateToIsoDate(lastCompleted.due_date || row.start_date);
      const result = await pool.query(
        `UPDATE health_entries SET status = 'active', completed_on = NULL, completed_at = NULL,
          next_due_date = CASE WHEN frequency = 'once' THEN $1 ELSE COALESCE($1, next_due_date) END,
          updated_at = NOW()
         WHERE id = $2 RETURNING *`,
        [restoreDue, entryId]
      );
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.completion_undone',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: row.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'undo_complete', entry_type: row.type },
      });
      const entry = result.rows[0];
      entry.pet_name = null;
      res.json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/close', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = await closeHealthEntrySeries(pool, existing.rows[0], userId);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.closed',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: {
          entry_type: row.type,
          repeat_end_date: dateToIsoDate(row.repeat_end_date),
        },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: row.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'close', entry_type: row.type },
      });
      row.pet_name = null;
      res.json(healthEntryToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/reopen', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const result = await pool.query(
        `UPDATE health_entries SET status = 'active', repeat_end_date = NULL,
          next_due_date = NULL, updated_at = NOW()
         WHERE id = $1 RETURNING *`,
        [entryId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = result.rows[0];
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.reopened',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: row.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'reopen', entry_type: row.type },
      });
      row.pet_name = null;
      res.json(healthEntryToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const result = await pool.query(
        `SELECT hh.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM health_history hh
         LEFT JOIN users u ON u.id = hh.marked_by_user_id
         WHERE hh.health_entry_id = $1 AND hh.status IN ('completed', 'skipped')
         ORDER BY hh.changed_at DESC`,
        [req.params.id]
      );
      res.json(result.rows.map(historyToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
