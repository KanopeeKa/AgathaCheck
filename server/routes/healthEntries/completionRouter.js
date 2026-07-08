import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { nextOccurrence } from '../../lib/recurrenceHelper.js';
import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../../lib/calendarDate.js';
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
      const hist = await pool.query(
        `SELECT * FROM health_history WHERE health_entry_id = $1 AND status = 'completed'
         ORDER BY changed_at DESC LIMIT 1`,
        [entryId]
      );
      if (hist.rows.length > 0) {
        await pool.query(
          "UPDATE health_history SET status = 'undone' WHERE id = $1",
          [hist.rows[0].id]
        );
      }
      const existing = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const row = existing.rows[0];
      const last = hist.rows[0];
      const restoreDue = dateToIsoDate(last?.due_date || row.start_date);
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
         WHERE hh.health_entry_id = $1 AND hh.status = 'completed'
         ORDER BY hh.changed_at DESC`,
        [req.params.id]
      );
      res.json(result.rows.map(historyToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
