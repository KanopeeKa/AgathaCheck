import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { assertAtLeastOneDate } from '../../lib/recurrenceHelper.js';
import { dateToIsoDate, normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import {
  accessiblePetSql,
  userCanManagePet,
  userCanManageHealthEntry,
} from '../../lib/petAccess.js';
import {
  extractUserId,
  healthEntryToMap,
  csvCell,
  validateHealthEntryTypeForWrite,
} from './shared.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';

export function registerCrudRoutes(router, pool) {
  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      let result;
      if (petId) {
        if (!(await userCanManagePet(pool, petId, userId))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        result = await pool.query(
          `SELECT he.*, p.name as pet_name FROM health_entries he
           JOIN pets p ON he.pet_id = p.id
           WHERE he.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
           ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC`,
          [petId, userId]
        );
      } else {
        result = await pool.query(
          `SELECT he.*, p.name as pet_name FROM health_entries he
           JOIN pets p ON he.pet_id = p.id
           WHERE ${accessiblePetSql('p', '$1')}
           ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC`,
          [userId]
        );
      }
      res.json(result.rows.map(healthEntryToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/export', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT he.*, p.name as pet_name FROM health_entries he
         JOIN pets p ON he.pet_id = p.id
         WHERE ${accessiblePetSql('p', '$1')}
         ORDER BY he.created_at DESC`,
        [userId]
      );
      let csv = 'id,pet_name,name,type,dosage,frequency,start_date,next_due_date,completed_on,recurrence_anchor,notes\n';
      for (const row of result.rows) {
        csv += [
          row.id, row.pet_name, row.name, row.type, row.dosage,
          row.frequency,
          dateToIsoDate(row.start_date),
          dateToIsoDate(row.next_due_date),
          dateToIsoDate(row.completed_on),
          row.recurrence_anchor, row.notes,
        ].map(csvCell).join(',') + '\n';
      }
      res.setHeader('Content-Type', 'text/csv');
      res.send(csv);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT he.*, p.name as pet_name FROM health_entries he
         JOIN pets p ON he.pet_id = p.id
         WHERE he.id = $1 AND ${accessiblePetSql('p', '$2')}`,
        [req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      res.json(healthEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const nextDueDate = normalizeCalendarDateInput(data.next_due_date || data.nextDueDate);
      const completedOn = normalizeCalendarDateInput(data.completed_on || data.completedOn);
      const repeatEndDate = normalizeCalendarDateInput(data.repeat_end_date || data.repeatEndDate);
      const recurrenceAnchor = data.recurrence_anchor || data.recurrenceAnchor || 'from_completion';
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      try {
        assertAtLeastOneDate(nextDueDate, completedOn);
      } catch (e) {
        return res.status(400).json({ error: e.message });
      }
      const typeValidation = validateHealthEntryTypeForWrite(data.type || 'vet_visit');
      if (!typeValidation.ok) {
        return res.status(400).json({ error: typeValidation.error });
      }
      const result = await pool.query(
        `INSERT INTO health_entries (id, pet_id, user_id, name, type, dosage, frequency, frequency_days, frequency_interval, start_date, next_due_date, completed_on, recurrence_anchor, repeat_end_date, notes, health_issue_id, remind_days_before, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18) RETURNING *`,
        [
          id, petId, userId,
          data.name || '',
          typeValidation.type,
          data.dosage || '',
          data.frequency || 'once',
          data.frequency_days || data.frequencyDays || null,
          data.frequency_interval || data.frequencyInterval || 1,
          startDate, nextDueDate, completedOn,
          recurrenceAnchor, repeatEndDate,
          data.notes || '',
          healthIssueId,
          data.remind_days_before || data.remindDaysBefore || 1,
          completedOn ? 'completed' : (data.status || 'active'),
        ]
      );
      const entry = result.rows[0];
      entry.pet_name = null;
      recordPetActivityForPet(pool, {
        petId: petId,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'create', entry_type: typeValidation.type },
      });
      res.status(201).json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error creating entry', `Error creating entry: ${err.message}`) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const data = req.body;
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const nextDueDate = normalizeCalendarDateInput(data.next_due_date || data.nextDueDate);
      const completedOn = normalizeCalendarDateInput(data.completed_on || data.completedOn);
      const repeatEndDate = normalizeCalendarDateInput(data.repeat_end_date || data.repeatEndDate);
      const recurrenceAnchor = data.recurrence_anchor || data.recurrenceAnchor || 'from_completion';
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      try {
        assertAtLeastOneDate(nextDueDate, completedOn);
      } catch (e) {
        return res.status(400).json({ error: e.message });
      }
      const typeValidation = validateHealthEntryTypeForWrite(data.type || 'vet_visit');
      if (!typeValidation.ok) {
        return res.status(400).json({ error: typeValidation.error });
      }
      const result = await pool.query(
        `UPDATE health_entries SET name = $1, type = $2, dosage = $3, frequency = $4, frequency_days = $5,
          frequency_interval = $6, start_date = $7, next_due_date = $8, completed_on = $9,
          recurrence_anchor = $10, repeat_end_date = $11, notes = $12,
          health_issue_id = $13, remind_days_before = $14, status = $15, updated_at = NOW()
         WHERE id = $16 RETURNING *`,
        [
          data.name || '',
          typeValidation.type,
          data.dosage || '',
          data.frequency || 'once',
          data.frequency_days || data.frequencyDays || null,
          data.frequency_interval || data.frequencyInterval || 1,
          startDate, nextDueDate, completedOn,
          recurrenceAnchor, repeatEndDate,
          data.notes || '',
          healthIssueId,
          data.remind_days_before || data.remindDaysBefore || 1,
          completedOn ? 'completed' : (data.status || 'active'),
          req.params.id,
        ]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const entry = result.rows[0];
      entry.pet_name = null;
      recordPetActivityForPet(pool, {
        petId: entry.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'update', entry_type: typeValidation.type },
      });
      res.json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error updating entry', `Error updating entry: ${err.message}`) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      await pool.query('DELETE FROM health_entries WHERE id = $1', [req.params.id]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
