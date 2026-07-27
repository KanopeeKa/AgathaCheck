import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { nextOccurrence } from '../../lib/recurrenceHelper.js';
import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso, yesterdayCalendarIso } from '../../lib/calendarDate.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { extractUserId, healthEntryToMap, historyToMap } from './shared.js';

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
      const dueDateIso = dateToIsoDate(row.next_due_date);
      const completedOnIso = normalizeCalendarDateInput(body.completed_on || body.completedOn)
        || todayCalendarIso();
      const anchor = row.recurrence_anchor || 'from_completion';
      if (anchor === 'from_due_date' && !dueDateIso && (row.frequency || 'once') !== 'once') {
        return res.status(400).json({ error: 'Due date is required for fixed-schedule recurring entries' });
      }
      const newDueDate = nextOccurrence(row, completedOnIso);
      const notes = body.notes || '';
      const histId = uuidv4();
      const markedAt = new Date();

      if ((row.frequency || 'once') === 'once') {
        const result = await pool.query(
          `UPDATE health_entries SET status = 'completed', completed_on = $1, completed_at = $2,
            next_due_date = NULL, updated_at = NOW()
           WHERE id = $3 RETURNING *`,
          [completedOnIso, markedAt, entryId]
        );
        await pool.query(
          `INSERT INTO health_history (id, health_entry_id, status, notes, due_date, completed_on, marked_by_user_id, changed_at)
           VALUES ($1, $2, 'completed', $3, $4, $5, $6, $7)`,
          [histId, entryId, notes, dueDateIso, completedOnIso, userId, markedAt]
        );
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'health_entry.marked_complete',
          resourceType: 'health_entry',
          resourceId: entryId,
          petId: row.pet_id,
          metadata: { entry_type: row.type, frequency: row.frequency || 'once' },
          req,
        });
        const entry = result.rows[0];
        entry.pet_name = null;
        return res.json(healthEntryToMap(entry));
      }

      const result = await pool.query(
        `UPDATE health_entries SET status = 'active', completed_on = NULL, completed_at = $1,
          next_due_date = $2, updated_at = NOW()
         WHERE id = $3 RETURNING *`,
        [markedAt, newDueDate, entryId]
      );
      await pool.query(
        `INSERT INTO health_history (id, health_entry_id, status, notes, due_date, completed_on, marked_by_user_id, changed_at)
         VALUES ($1, $2, 'completed', $3, $4, $5, $6, $7)`,
        [histId, entryId, notes, dueDateIso, completedOnIso, userId, markedAt]
      );
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.marked_complete',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type, frequency: row.frequency || 'once' },
        req,
      });
      const entry = result.rows[0];
      entry.pet_name = null;
      res.json(healthEntryToMap(entry));
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
      const latestHist = await pool.query(
        `SELECT * FROM health_history WHERE health_entry_id = $1
         ORDER BY changed_at DESC LIMIT 1`,
        [entryId]
      );
      if (latestHist.rows.length === 0 || latestHist.rows[0].status !== 'completed') {
        return res.status(400).json({ error: 'No completed occurrence to unmark' });
      }
      const lastCompleted = latestHist.rows[0];
      await pool.query(
        "UPDATE health_history SET status = 'undone' WHERE id = $1",
        [lastCompleted.id]
      );
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];
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
      const yesterday = yesterdayCalendarIso();
      const result = await pool.query(
        `UPDATE health_entries SET status = 'completed', repeat_end_date = $1, updated_at = NOW()
         WHERE id = $2 RETURNING *`,
        [yesterday, entryId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = result.rows[0];
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.closed',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type, repeat_end_date: yesterday },
        req,
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
      row.pet_name = null;
      res.json(healthEntryToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/skip', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const body = req.body || {};
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const dueDateIso = normalizeCalendarDateInput(body.due_date || body.dueDate);
      if (!dueDateIso) {
        return res.status(400).json({ error: 'due_date is required' });
      }
      const existing = await pool.query(
        'SELECT he.* FROM health_entries he WHERE he.id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];
      const dup = await pool.query(
        `SELECT id FROM health_history WHERE health_entry_id = $1 AND due_date = $2
         AND status IN ('completed', 'skipped') LIMIT 1`,
        [entryId, dueDateIso]
      );
      if (dup.rows.length > 0) {
        return res.status(400).json({ error: 'Occurrence already recorded for this due date' });
      }
      const histId = uuidv4();
      const markedAt = new Date();
      const notes = body.notes || '';
      await pool.query(
        `INSERT INTO health_history (id, health_entry_id, status, notes, due_date, completed_on, marked_by_user_id, changed_at)
         VALUES ($1, $2, 'skipped', $3, $4, NULL, $5, $6)`,
        [histId, entryId, notes, dueDateIso, userId, markedAt]
      );
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.iteration_skipped',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { entry_type: row.type, due_date: dueDateIso },
        req,
      });
      const histRow = await pool.query(
        `SELECT hh.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM health_history hh
         LEFT JOIN users u ON u.id = hh.marked_by_user_id
         WHERE hh.id = $1`,
        [histId]
      );
      res.status(201).json(historyToMap(histRow.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/unskip', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const body = req.body || {};
      const historyId = body.history_id || body.historyId;
      if (!historyId) {
        return res.status(400).json({ error: 'history_id is required' });
      }
      if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const hist = await pool.query(
        `SELECT * FROM health_history WHERE id = $1 AND health_entry_id = $2`,
        [historyId, entryId]
      );
      if (hist.rows.length === 0) {
        return res.status(404).json({ error: 'History record not found' });
      }
      if (hist.rows[0].status !== 'skipped') {
        return res.status(400).json({ error: 'Only skipped occurrences can be unskipped' });
      }
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];
      await pool.query('DELETE FROM health_history WHERE id = $1', [historyId]);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'health_entry.iteration_unskipped',
        resourceType: 'health_entry',
        resourceId: entryId,
        petId: row.pet_id,
        metadata: { history_id: historyId, due_date: dateToIsoDate(hist.rows[0].due_date) },
        req,
      });
      res.json({ deleted: true, history_id: historyId });
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
