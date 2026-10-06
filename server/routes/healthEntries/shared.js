import multer from 'multer';

import {
  CARE_FAMILIES,
  CARE_SOURCES,
} from '../../lib/care/enums.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { healthEntryToMap as careItemHealthEntryToMap, normalizeHealthEntryTypeForRead } from '../../lib/care/item/index.js';
import { extensionForMime } from '../../lib/safeUpload.js';
import {
  HEALTH_DOCUMENT_EXTENSIONS,
  HEALTH_DOCUMENT_MIME_TYPES,
  MAX_HEALTH_DOCUMENT_BYTES,
  buildHealthFileApiPath,
  privateHealthDir,
  removePrivateHealthFile,
  savePrivateHealthFile,
} from '../../lib/privateHealthStorage.js';

export {
  HEALTH_DOCUMENT_EXTENSIONS,
  HEALTH_DOCUMENT_MIME_TYPES,
  MAX_HEALTH_DOCUMENT_BYTES,
  extractUserId,
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

/**
 * Insert a health_event_photos row; remove the on-disk file when the DB write fails.
 * @param {import('pg').Pool} pool
 */
export async function insertHealthEventPhoto(pool, {
  photoId,
  entryId,
  occurrenceId,
  file,
  bodyUrl,
}) {
  let url;
  try {
    url = file
      ? saveHealthDocument(file, photoId)
      : (bodyUrl || buildHealthFileApiPath(photoId));
    const result = await pool.query(
      `INSERT INTO health_event_photos
         (id, health_entry_id, url, health_occurrence_id)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [photoId, entryId, url, occurrenceId],
    );
    return result.rows[0];
  } catch (err) {
    if (url) removeHealthDocumentFromDisk(url);
    throw err;
  }
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
export const HEALTH_ENTRY_TYPES = new Set([
  'medication',
  'preventive',
  'vet_visit',
  'other',
]);

const LEGACY_HEALTH_ENTRY_TYPES = new Set(['family_event', 'procedure']);

export { normalizeHealthEntryTypeForRead };

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

export { CARE_FAMILIES, CARE_SOURCES };

export {
  validateCareFamilyForWrite,
  validateCareSourceForWrite,
  resolveEntryProviderForWrite,
} from '../../lib/health/healthEntryWriteSupport.js';

export const healthEntryToMap = careItemHealthEntryToMap;

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

export { csvCell } from '../../lib/health/healthEntryCsv.js';
