import multer from 'multer';

import {
  CARE_FAMILIES,
  CARE_SOURCES,
  validateCareFamily as validateCareFamilyEnum,
  validateCareSource as validateCareSourceEnum,
} from '../../lib/care/enums.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { healthEntryToMap as careItemHealthEntryToMap, normalizeHealthEntryTypeForRead } from '../../lib/care/item/index.js';
import { validateProviderContactForPetWrite } from '../../lib/care/providerUsed.js';
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

export function validateCareFamilyForWrite(
  value,
  { recurring = false, requiredOnCreate = false } = {},
) {
  const required = requiredOnCreate || recurring;
  const requiredMessage = requiredOnCreate
    ? 'care_family is required'
    : 'care_family is required for recurring care';
  return validateCareFamilyEnum(value, { required, requiredMessage });
}

export function validateCareSourceForWrite(value) {
  return validateCareSourceEnum(value);
}

/** @param {object} data */
export function parseEntryProviderInput(data) {
  const hasContact = data.provider_contact_id !== undefined
    || data.providerContactId !== undefined;
  const hasTyped = data.provider_typed_name !== undefined
    || data.providerTypedName !== undefined;
  if (!hasContact && !hasTyped) {
    return { contactId: undefined, typedName: undefined };
  }
  let contactId = hasContact
    ? (data.provider_contact_id ?? data.providerContactId ?? null)
    : undefined;
  let typedName = hasTyped
    ? String(data.provider_typed_name ?? data.providerTypedName ?? '').trim()
    : undefined;
  if (contactId && typedName) {
    return { error: 'Provide either a provider contact or a typed name, not both' };
  }
  if (contactId === '') contactId = null;
  if (typedName === '') typedName = null;
  return { contactId, typedName };
}

/**
 * Parse provider fields and enforce attach policy (B12).
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {string} petId
 * @param {object} data
 * @param {object} [existing] health_entries row on update
 */
export async function resolveEntryProviderForWrite(pool, userId, petId, data, existing = null) {
  const providerInput = parseEntryProviderInput(data);
  if (providerInput.error) return { error: providerInput.error };
  if (!existing) {
    const providerContactId = providerInput.contactId ?? null;
    const providerTypedName = providerInput.typedName ?? null;
    const attachError = await validateProviderContactForPetWrite(
      pool,
      userId,
      petId,
      providerContactId,
    );
    if (attachError) return attachError;
    return { providerContactId, providerTypedName };
  }
  let providerContactId = existing.provider_contact_id;
  let providerTypedName = existing.provider_typed_name;
  if (providerInput.contactId !== undefined) {
    providerContactId = providerInput.contactId;
    if (providerContactId) providerTypedName = null;
  }
  if (providerInput.typedName !== undefined) {
    providerTypedName = providerInput.typedName;
    if (providerTypedName) providerContactId = null;
  }
  if (providerInput.contactId !== undefined && providerContactId) {
    const attachError = await validateProviderContactForPetWrite(
      pool,
      userId,
      petId,
      providerContactId,
    );
    if (attachError) return attachError;
  }
  return { providerContactId, providerTypedName };
}

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
