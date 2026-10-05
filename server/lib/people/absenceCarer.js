import {
  CARER_KIND_NOTE_ONLY,
  CARER_KIND_SHARED_USER,
} from '../care/plannedAbsence.js';
import { PET_ACCESS_ROLES } from '../petAccess.js';
import {
  contactUsableForPet,
  getPetOwnerUserId,
} from './authz.js';
import {
  ensureLinkedUserContact,
  ensureNoteOnlyContact,
} from './contactsRepo.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

export const CARER_STATE_UNSET = 'unset';
export const CARER_STATE_SET = 'set';
export const CARER_STATE_UNAVAILABLE = 'unavailable';

/**
 * @param {object} row enriched pet row
 */
export function deriveCarerState(row) {
  const kind = row.carer_kind || null;
  const removed = kind === CARER_KIND_SHARED_USER && !row.carer_user_id;
  if (removed) {
    return CARER_STATE_UNAVAILABLE;
  }
  if (!kind) {
    return CARER_STATE_UNSET;
  }
  if (row.contact_inactive === true) {
    return CARER_STATE_UNAVAILABLE;
  }
  if (row.contact_id && row.contact_missing === true) {
    return CARER_STATE_UNAVAILABLE;
  }
  if (kind === CARER_KIND_NOTE_ONLY && !(row.carer_name || '').trim()) {
    return CARER_STATE_UNSET;
  }
  if (row.contact_id == null && kind != null && row.contact_was_expected === true) {
    return CARER_STATE_UNAVAILABLE;
  }
  return CARER_STATE_SET;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} carerUserId
 */
async function isCarerCandidate(pool, petId, carerUserId) {
  const result = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${PET_ACCESS_ROLES_SQL})
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, carerUserId],
  );
  return result.rows.length > 0;
}

/**
 * Load contact metadata for absence pet rows (inactive / missing).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object[]} petRows
 */
export async function enrichAbsencePetCarerContacts(pool, petRows) {
  if (!Array.isArray(petRows) || petRows.length === 0) return petRows;
  const contactIds = [
    ...new Set(petRows.map((row) => row.contact_id).filter(Boolean)),
  ];
  const metaById = new Map();
  if (contactIds.length > 0) {
    const result = await pool.query(
      `SELECT id, inactive_at FROM people_contacts WHERE id = ANY($1::uuid[])`,
      [contactIds],
    );
    for (const contact of result.rows) {
      metaById.set(contact.id, {
        inactive: contact.inactive_at != null,
      });
    }
  }
  return petRows.map((row) => {
    if (!row.contact_id) {
      return {
        ...row,
        contact_inactive: false,
        contact_missing: false,
        contact_was_expected: false,
      };
    }
    const meta = metaById.get(row.contact_id);
    return {
      ...row,
      contact_inactive: meta?.inactive === true,
      contact_missing: !meta,
      contact_was_expected: true,
    };
  });
}

/**
 * Resolve PATCH input to stored carer columns.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {string} params.declarerUserId
 * @param {string} params.petId
 * @param {object} params.item
 */
export async function resolveCarerWrite(pool, { declarerUserId, petId, item }) {
  const hasContactId = Object.hasOwn(item, 'contact_id') || Object.hasOwn(item, 'contactId');
  const hasCarerKind = Object.hasOwn(item, 'carer_kind') || Object.hasOwn(item, 'carerKind');

  if (hasContactId) {
    const rawContactId = item.contact_id ?? item.contactId ?? null;
    if (rawContactId === null || rawContactId === '') {
      return {
        ok: true,
        carer_kind: null,
        carer_user_id: null,
        carer_name: null,
        carer_note: null,
        contact_id: null,
      };
    }
    const contactId = String(rawContactId);
    const petOwnerId = await getPetOwnerUserId(pool, petId);
    if (!(await contactUsableForPet(pool, contactId, declarerUserId, petOwnerId))) {
      return { ok: false, status: 403, error: 'Forbidden' };
    }
    const contactResult = await pool.query(
      `SELECT pc.id, pc.name, pc.linked_user_id, pc.inactive_at,
              pcpn.note AS private_note
       FROM people_contacts pc
       LEFT JOIN people_contact_private_notes pcpn
         ON pcpn.contact_id = pc.id AND pcpn.user_id = $2
       WHERE pc.id = $1`,
      [contactId, declarerUserId],
    );
    const contact = contactResult.rows[0];
    if (!contact) {
      return { ok: false, status: 400, error: 'contact_id not found' };
    }
    if (contact.inactive_at) {
      return { ok: false, status: 400, error: 'Contact is inactive' };
    }

    if (contact.linked_user_id) {
      if (!(await isCarerCandidate(pool, petId, contact.linked_user_id))) {
        return { ok: false, status: 403, error: 'Forbidden' };
      }
      return {
        ok: true,
        carer_kind: CARER_KIND_SHARED_USER,
        carer_user_id: contact.linked_user_id,
        carer_name: null,
        carer_note: null,
        contact_id: contactId,
      };
    }

    return {
      ok: true,
      carer_kind: CARER_KIND_NOTE_ONLY,
      carer_user_id: null,
      carer_name: contact.name,
      carer_note: contact.private_note ?? null,
      contact_id: contactId,
    };
  }

  if (!hasCarerKind) {
    return null;
  }

  const kindRaw = item.carer_kind ?? item.carerKind ?? null;
  if (kindRaw === null || kindRaw === '') {
    return {
      ok: true,
      carer_kind: null,
      carer_user_id: null,
      carer_name: null,
      carer_note: null,
      contact_id: null,
    };
  }

  if (kindRaw !== CARER_KIND_SHARED_USER && kindRaw !== CARER_KIND_NOTE_ONLY) {
    return { ok: false, status: 400, error: 'carer_kind must be shared_user, note_only, or null' };
  }

  if (kindRaw === CARER_KIND_SHARED_USER) {
    const carerUserId = item.carer_user_id || item.carerUserId || null;
    if (!carerUserId) {
      return { ok: false, status: 400, error: 'carer_user_id is required for shared_user carers' };
    }
    if (!(await isCarerCandidate(pool, petId, carerUserId))) {
      return { ok: false, status: 403, error: 'Forbidden' };
    }
    const contactId = await ensureLinkedUserContact(pool, declarerUserId, carerUserId);
    return {
      ok: true,
      carer_kind: CARER_KIND_SHARED_USER,
      carer_user_id: String(carerUserId),
      carer_name: null,
      carer_note: null,
      contact_id: contactId,
    };
  }

  const name = (item.carer_name || item.carerName || '').trim();
  if (!name) {
    return { ok: false, status: 400, error: 'carer_name is required for note_only carers' };
  }
  const note = item.carer_note ?? item.carerNote ?? null;
  const contactId = await ensureNoteOnlyContact(
    pool,
    declarerUserId,
    name,
    note == null || note === '' ? null : String(note),
  );
  return {
    ok: true,
    carer_kind: CARER_KIND_NOTE_ONLY,
    carer_user_id: null,
    carer_name: name,
    carer_note: note == null || note === '' ? null : String(note),
    contact_id: contactId,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
export async function contactOnAbsenceCarerRow(pool, contactId, userId) {
  if (!contactId) return false;
  const result = await pool.query(
    `SELECT 1
     FROM planned_absence_pets pap
     INNER JOIN planned_absences pa ON pa.id = pap.planned_absence_id
     WHERE pap.contact_id = $1 AND pa.user_id = $2
     LIMIT 1`,
    [contactId, userId],
  );
  return result.rows.length > 0;
}
