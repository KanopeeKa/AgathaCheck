import { publicError } from '../../config/security.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { extractUserId, healthEntryToMap, historyToMap } from './shared.js';
import { completeOldestPendingOccurrence } from './occurrencesRouter.js';
import { closeHealthEntrySeries } from '../../lib/occurrenceLifecycle.js';
import { undoLastAction } from '../../lib/care/schedule/undoLastAction.js';
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

  router.post('/:id/schedule/undo', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId],
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];

      const undone = await undoLastAction(pool, { entry: row, userId });
      if (!undone) {
        return res.status(400).json({ error: 'No schedule action to undo' });
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.schedule_undone',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: {
          entry_type: row.type,
          action_type: undone.actionType,
          occurrence_id: undone.occurrence?.id ?? null,
        },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: row.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'schedule_undo', entry_type: row.type },
      });

      const entry = undone.entry;
      entry.pet_name = null;
      return res.json({
        action_type: undone.actionType,
        entry: healthEntryToMap(entry),
        occurrence: undone.occurrence ? {
          id: undone.occurrence.id,
          status: undone.occurrence.status,
          scheduled_date: dateToIsoDate(undone.occurrence.scheduled_date),
        } : null,
        next_due_date: undone.nextDueDate ?? dateToIsoDate(entry.next_due_date),
      });
    } catch (err) {
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
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId],
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];

      const undone = await undoLastAction(pool, { entry: row, userId });
      if (!undone) {
        return res.status(400).json({ error: 'No schedule action to undo' });
      }
      if (undone.actionType !== 'complete') {
        return res.status(400).json({
          error: 'Last action is not a completion; use POST /:id/schedule/undo instead',
        });
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.completion_undone',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type, via: 'undoLastAction' },
        req,
      });
      recordPetActivityForPet(pool, {
        petId: row.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'undo_complete', entry_type: row.type },
      });
      const entry = undone.entry;
      entry.pet_name = null;
      return res.json(healthEntryToMap(entry));
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
