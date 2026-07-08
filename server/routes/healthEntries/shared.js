import fs from 'fs';
import path from 'path';
import multer from 'multer';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';

export const MAX_HEALTH_DOCUMENT_BYTES = 2 * 1024 * 1024;
export const HEALTH_DOCUMENT_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.pdf']);
export const HEALTH_DOCUMENT_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'application/pdf',
]);

const _upload = multer({
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

export function healthUploadDir() {
  return process.env.HEALTH_UPLOAD_DIR || path.resolve(process.cwd(), 'uploads', 'health_documents');
}

export function saveHealthDocument(file, id) {
  const ext = path.extname(file.originalname).toLowerCase();
  const dir = healthUploadDir();
  fs.mkdirSync(dir, { recursive: true });
  const filename = `${id}${ext}`;
  fs.writeFileSync(path.join(dir, filename), file.buffer);
  return `/uploads/health_documents/${filename}`;
}

export function handleDocumentUpload(req, res, next) {
  _upload.single('photo')(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'Document must be 2 MB or smaller' });
    }
    return res.status(400).json({ error: err.message });
  });
}

export function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

export function healthEntryToMap(row) {
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

export function historyToMap(row) {
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
export function csvCell(value) {
  if (value === null || value === undefined) return '';
  let s = String(value);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  if (/[",\n\r]/.test(s)) s = `"${s.replace(/"/g, '""')}"`;
  return s;
}
