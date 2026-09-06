import multer from 'multer';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { extensionForMime } from '../../lib/safeUpload.js';
import {
  HEALTH_DOCUMENT_EXTENSIONS,
  HEALTH_DOCUMENT_MIME_TYPES,
  MAX_HEALTH_DOCUMENT_BYTES,
  privateHealthDir,
  removePrivateHealthFile,
  savePrivateHealthFile,
} from '../../lib/privateHealthStorage.js';

export {
  HEALTH_DOCUMENT_EXTENSIONS,
  HEALTH_DOCUMENT_MIME_TYPES,
  MAX_HEALTH_DOCUMENT_BYTES,
};

const _upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_HEALTH_DOCUMENT_BYTES },
  fileFilter: (_req, file, cb) => {
    try {
      extensionForMime(file.mimetype, HEALTH_DOCUMENT_EXTENSIONS);
      cb(null, true);
    } catch {
      cb(new Error('Only JPG, PNG, and PDF documents are allowed'));
    }
  },
});

export function healthUploadDir() {
  return privateHealthDir();
}

export function saveHealthDocument(file, id) {
  const { apiPath } = savePrivateHealthFile(file, id);
  return apiPath;
}

/** Best-effort removal of a persisted health document by its API or legacy URL path. */
export function removeHealthDocumentFromDisk(url) {
  removePrivateHealthFile(url);
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

export const HEALTH_ENTRY_TYPES = new Set([
  'medication',
  'preventive',
  'vet_visit',
  'other',
]);

const LEGACY_HEALTH_ENTRY_TYPES = new Set(['family_event', 'procedure']);

export function normalizeHealthEntryTypeForRead(type) {
  if (!type) return type;
  if (LEGACY_HEALTH_ENTRY_TYPES.has(type)) return 'other';
  return type;
}

export function validateHealthEntryTypeForWrite(type) {
  if (!type) {
    return { ok: false, error: 'Entry type is required' };
  }
  if (LEGACY_HEALTH_ENTRY_TYPES.has(type)) {
    return { ok: false, error: 'Deprecated entry type; use "other" instead' };
  }
  if (!HEALTH_ENTRY_TYPES.has(type)) {
    return { ok: false, error: `Invalid entry type: ${type}` };
  }
  return { ok: true, type };
}

export function healthEntryToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    pet_name: row.pet_name || null,
    name: row.name || '',
    type: normalizeHealthEntryTypeForRead(row.type),
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
    schedule_times: row.schedule_times ?? null,
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
