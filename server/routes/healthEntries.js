import express from 'express';
import fs from 'fs';
import path from 'path';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import { nextOccurrence, assertAtLeastOneDate } from '../lib/recurrenceHelper.js';
import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../lib/calendarDate.js';
import {
  accessiblePetSql,
  userCanManagePet,
  userCanManageHealthEntry,
} from '../lib/petAccess.js';

const MAX_HEALTH_DOCUMENT_BYTES = 2 * 1024 * 1024;
const HEALTH_DOCUMENT_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.pdf']);
const HEALTH_DOCUMENT_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'application/pdf',
]);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_HEALTH_DOCUMENT_BYTES },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (
      HEALTH_DOCUMENT_EXTENSIONS.has(ext) &&
      HEALTH_DOCUMENT_MIME_TYPES.has(file.mimetype)
    ) {
      cb(null, true);
      return;
    }
    cb(new Error('Only JPG, PNG, and PDF documents are allowed'));
  },
});

function healthUploadDir() {
  return process.env.HEALTH_UPLOAD_DIR || path.resolve(process.cwd(), 'uploads', 'health_documents');
}

function saveHealthDocument(file, id) {
  const ext = path.extname(file.originalname).toLowerCase();
  const dir = healthUploadDir();
  fs.mkdirSync(dir, { recursive: true });
  const filename = `${id}${ext}`;
  fs.writeFileSync(path.join(dir, filename), file.buffer);
  return `/uploads/health_documents/${filename}`;
}

function handleDocumentUpload(req, res, next) {
  upload.single('photo')(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'Document must be 2 MB or smaller' });
    }
    return res.status(400).json({ error: err.message });
  });
}

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
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
    start_date: row.start_date ? dateToIsoDate(row.start_date) : null,
    next_due_date: row.next_due_date ? dateToIsoDate(row.next_due_date) : null,
    completed_on: row.completed_on
      ? dateToIsoDate(row.completed_on)
      : null,
    recurrence_anchor: row.recurrence_anchor || 'from_completion',
    repeat_end_date: row.repeat_end_date ? dateToIsoDate(row.repeat_end_date) : null,
    notes: row.notes || '',
    health_issue_id: row.health_issue_id || null,
    remind_days_before: row.remind_days_before ?? 1,
    status: row.status || 'active',
    completed_at: row.completed_at ? row.completed_at.toISOString?.() || String(row.completed_at) : null,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
    updated_at: row.updated_at ? row.updated_at.toISOString?.() || String(row.updated_at) : null,
  };
}

function historyToMap(row) {
  return {
    id: row.id,
    health_entry_id: row.health_entry_id,
    entry_id: row.health_entry_id,
    status: row.status,
    notes: row.notes || '',
    due_date: row.due_date ? dateToIsoDate(row.due_date) : null,
    completed_on: row.completed_on ? dateToIsoDate(row.completed_on) : null,
    changed_at: row.changed_at,
    marked_at: row.changed_at,
    taken_at: row.changed_at,
    marked_by_user_id: row.marked_by_user_id || null,
    marked_by_name: row.marked_by_name?.trim() || null,
  };
}

// Renders a single CSV cell safely: neutralizes spreadsheet formula injection
// (cells beginning with = + - @ tab/CR are prefixed with a single quote) and
// applies RFC-4180 quoting when the value contains a comma, quote, or newline.
function csvCell(value) {
  if (value === null || value === undefined) return '';
  let s = String(value);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  if (/[",\n\r]/.test(s)) s = `"${s.replace(/"/g, '""')}"`;
  return s;
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
      const result = await pool.query(
        `INSERT INTO health_entries (id, pet_id, user_id, name, type, dosage, frequency, frequency_days, frequency_interval, start_date, next_due_date, completed_on, recurrence_anchor, repeat_end_date, notes, health_issue_id, remind_days_before, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18) RETURNING *`,
        [
          id, petId, userId,
          data.name || '',
          data.type || 'vet_visit',
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
      const result = await pool.query(
        `UPDATE health_entries SET name = $1, type = $2, dosage = $3, frequency = $4, frequency_days = $5,
          frequency_interval = $6, start_date = $7, next_due_date = $8, completed_on = $9,
          recurrence_anchor = $10, repeat_end_date = $11, notes = $12,
          health_issue_id = $13, remind_days_before = $14, status = $15, updated_at = NOW()
         WHERE id = $16 RETURNING *`,
        [
          data.name || '',
          data.type || 'vet_visit',
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

  router.get('/:id/photos', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
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
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/photos', handleDocumentUpload, async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const id = uuidv4();
      const url = req.file
        ? saveHealthDocument(req.file, id)
        : req.body?.url || `/uploads/health_photos/${id}.jpg`;
      const result = await pool.query(
        'INSERT INTO health_event_photos (id, health_entry_id, url) VALUES ($1, $2, $3) RETURNING *',
        [id, req.params.id, url]
      );
      res.status(201).json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:entryId/photos/:photoId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      await pool.query(
        'DELETE FROM health_event_photos WHERE id = $1 AND health_entry_id = $2',
        [req.params.photoId, req.params.entryId]
      );
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
