import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

function nextOccurrence(row) {
  const freq = row.frequency || 'once';
  if (freq === 'once') return new Date('9999-12-31T00:00:00.000Z');
  const interval = Math.max(1, row.frequency_interval ?? 1);
  const customDays = Math.max(1, row.frequency_days || interval);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const next = row.next_due_date ? new Date(row.next_due_date) : new Date();
  const advance = (d) => {
    switch (freq) {
      case 'daily':
        d.setDate(d.getDate() + interval);
        break;
      case 'weekly':
        d.setDate(d.getDate() + 7 * interval);
        break;
      case 'monthly':
        d.setMonth(d.getMonth() + interval);
        break;
      case 'yearly':
        d.setFullYear(d.getFullYear() + interval);
        break;
      case 'custom':
        d.setDate(d.getDate() + customDays);
        break;
      default:
        d.setDate(d.getDate() + interval);
    }
  };
  do {
    advance(next);
  } while (next <= today);
  return next;
}

function healthEntryToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    pet_name: row.pet_name || null,
    name: row.name || '',
    type: row.type,
    dosage: row.dosage || '',
    frequency: row.frequency || 'once',
    frequency_days: row.frequency_days || null,
    frequency_interval: row.frequency_interval ?? 1,
    start_date: row.start_date ? row.start_date.toISOString?.() || String(row.start_date) : null,
    next_due_date: row.next_due_date ? row.next_due_date.toISOString?.() || String(row.next_due_date) : null,
    notes: row.notes || '',
    health_issue_id: row.health_issue_id || null,
    remind_days_before: row.remind_days_before ?? 1,
    status: row.status || 'active',
    completed_at: row.completed_at ? row.completed_at.toISOString?.() || String(row.completed_at) : null,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
    updated_at: row.updated_at ? row.updated_at.toISOString?.() || String(row.updated_at) : null,
  };
}

export default function healthEntriesRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      let result;
      if (petId) {
        result = await pool.query(
          'SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.pet_id = $1 AND he.user_id = $2 ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC',
          [petId, userId]
        );
      } else {
        result = await pool.query(
          'SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.user_id = $1 ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC',
          [userId]
        );
      }
      res.json(result.rows.map(healthEntryToMap));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/export', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.user_id = $1 ORDER BY he.created_at DESC',
        [userId]
      );
      let csv = 'id,pet_name,name,type,dosage,frequency,start_date,next_due_date,notes\n';
      for (const row of result.rows) {
        csv += `${row.id},${row.pet_name},${row.name},${row.type},${row.dosage},${row.frequency},${row.start_date},${row.next_due_date},${row.notes}\n`;
      }
      res.setHeader('Content-Type', 'text/csv');
      res.send(csv);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.id = $1 AND he.user_id = $2',
        [req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      res.json(healthEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      const startDate = data.start_date || data.startDate || null;
      const nextDueDate = data.next_due_date || data.nextDueDate || null;
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      const result = await pool.query(
        `INSERT INTO health_entries (id, pet_id, user_id, name, type, dosage, frequency, frequency_days, frequency_interval, start_date, next_due_date, notes, health_issue_id, remind_days_before, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) RETURNING *`,
        [
          id, petId, userId,
          data.name || '',
          data.type || 'vet_visit',
          data.dosage || '',
          data.frequency || 'once',
          data.frequency_days || data.frequencyDays || null,
          data.frequency_interval || data.frequencyInterval || 1,
          startDate, nextDueDate,
          data.notes || '',
          healthIssueId,
          data.remind_days_before || data.remindDaysBefore || 1,
          data.status || 'active',
        ]
      );
      const entry = result.rows[0];
      entry.pet_name = null;
      res.status(201).json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: `Error creating entry: ${err.message}` });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const startDate = data.start_date || data.startDate || null;
      const nextDueDate = data.next_due_date || data.nextDueDate || null;
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      const result = await pool.query(
        `UPDATE health_entries SET name = $1, type = $2, dosage = $3, frequency = $4, frequency_days = $5,
          frequency_interval = $6, start_date = $7, next_due_date = $8, notes = $9,
          health_issue_id = $10, remind_days_before = $11, status = $12, updated_at = NOW()
         WHERE id = $13 AND user_id = $14 RETURNING *`,
        [
          data.name || '',
          data.type || 'vet_visit',
          data.dosage || '',
          data.frequency || 'once',
          data.frequency_days || data.frequencyDays || null,
          data.frequency_interval || data.frequencyInterval || 1,
          startDate, nextDueDate,
          data.notes || '',
          healthIssueId,
          data.remind_days_before || data.remindDaysBefore || 1,
          data.status || 'active',
          req.params.id, userId,
        ]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const entry = result.rows[0];
      entry.pet_name = null;
      res.json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: `Error updating entry: ${err.message}` });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('DELETE FROM health_entries WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/mark-taken', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const existing = await pool.query(
        'SELECT he.* FROM health_entries he WHERE he.id = $1 AND he.user_id = $2',
        [entryId, userId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const newDueDate = nextOccurrence(existing.rows[0]);
      const result = await pool.query(
        "UPDATE health_entries SET status = 'completed', completed_at = NOW(), next_due_date = $1, updated_at = NOW() WHERE id = $2 AND user_id = $3 RETURNING *",
        [newDueDate, entryId, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const histId = uuidv4();
      await pool.query(
        "INSERT INTO health_history (id, health_entry_id, status, notes) VALUES ($1, $2, 'completed', 'Marked as taken')",
        [histId, entryId]
      );
      const entry = result.rows[0];
      entry.pet_name = null;
      res.json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/undo-complete', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryId = req.params.id;
      const result = await pool.query(
        "UPDATE health_entries SET status = 'active', completed_at = NULL, next_due_date = CASE WHEN frequency = 'once' THEN start_date ELSE next_due_date END, updated_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING *",
        [entryId, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      const entry = result.rows[0];
      entry.pet_name = null;
      res.json(healthEntryToMap(entry));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:id/history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT * FROM health_history WHERE health_entry_id = $1 ORDER BY changed_at DESC',
        [req.params.id]
      );
      res.json(result.rows.map(r => ({
        id: r.id,
        health_entry_id: r.health_entry_id,
        status: r.status,
        notes: r.notes || '',
        changed_at: r.changed_at,
      })));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:id/photos', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT * FROM health_event_photos WHERE health_entry_id = $1 ORDER BY created_at',
        [req.params.id]
      );
      res.json(result.rows.map(r => ({
        id: r.id,
        health_entry_id: r.health_entry_id,
        url: r.url,
        created_at: r.created_at,
      })));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/photos', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const id = uuidv4();
      const url = req.body.url || `/uploads/health_photos/${id}.jpg`;
      const result = await pool.query(
        'INSERT INTO health_event_photos (id, health_entry_id, url) VALUES ($1, $2, $3) RETURNING *',
        [id, req.params.id, url]
      );
      res.status(201).json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:entryId/photos/:photoId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query(
        'DELETE FROM health_event_photos WHERE id = $1 AND health_entry_id = $2',
        [req.params.photoId, req.params.entryId]
      );
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
}
