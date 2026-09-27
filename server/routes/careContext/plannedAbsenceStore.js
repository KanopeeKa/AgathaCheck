import {
  PLANNED_ABSENCE_STATUS_CANCELLED,
  enrichSharedUserCarerNames,
  normalizePetNoteInput,
} from '../../lib/care/plannedAbsence.js';
import {
  enrichAbsencePetCarerContacts,
  resolveCarerWrite,
} from '../../lib/people/absenceCarer.js';
import { userCanManageCare } from '../../lib/petAccess.js';

export async function loadAbsencePets(pool, absenceId) {
  const result = await pool.query(
    `SELECT pet_id, carer_kind, carer_user_id, carer_name, carer_note, pet_note, contact_id
     FROM planned_absence_pets
     WHERE planned_absence_id = $1
     ORDER BY pet_id`,
    [absenceId],
  );
  const enrichedNames = await enrichSharedUserCarerNames(pool, result.rows);
  return enrichAbsencePetCarerContacts(pool, enrichedNames);
}

export async function loadPetsByAbsenceIds(pool, absenceIds) {
  const map = new Map();
  if (!absenceIds.length) return map;
  const result = await pool.query(
    `SELECT planned_absence_id, pet_id, carer_kind, carer_user_id, carer_name, carer_note, pet_note, contact_id
     FROM planned_absence_pets
     WHERE planned_absence_id = ANY($1::uuid[])
     ORDER BY pet_id`,
    [absenceIds],
  );
  if (result.rows.length === 0) return map;
  const enrichedNames = await enrichSharedUserCarerNames(pool, result.rows);
  const enriched = await enrichAbsencePetCarerContacts(pool, enrichedNames);
  for (const row of enriched) {
    const list = map.get(row.planned_absence_id) || [];
    list.push(row);
    map.set(row.planned_absence_id, list);
  }
  return map;
}

export async function loadAbsenceForUser(pool, absenceId, userId) {
  const result = await pool.query(
    'SELECT * FROM planned_absences WHERE id = $1 AND user_id = $2',
    [absenceId, userId],
  );
  return result.rows[0] || null;
}

export async function assertManageablePets(pool, userId, petIds) {
  if (!Array.isArray(petIds) || petIds.length === 0) {
    return { ok: false, status: 400, error: 'At least one pet_id is required' };
  }
  const unique = [...new Set(petIds)];
  for (const petId of unique) {
    if (!(await userCanManageCare(pool, petId, userId))) {
      return { ok: false, status: 403, error: 'Forbidden' };
    }
  }
  return { ok: true, petIds: unique };
}

export async function replaceAbsencePets(pool, absenceId, petIds) {
  await pool.query(
    `DELETE FROM planned_absence_pets
     WHERE planned_absence_id = $1
       AND NOT (pet_id = ANY($2::uuid[]))`,
    [absenceId, petIds],
  );
  if (petIds.length === 0) return;
  await pool.query(
    `INSERT INTO planned_absence_pets (planned_absence_id, pet_id)
     SELECT $1, unnest($2::uuid[])
     ON CONFLICT (planned_absence_id, pet_id) DO NOTHING`,
    [absenceId, petIds],
  );
}

export async function updateAbsenceCarers(
  pool,
  absenceId,
  petCarersInput,
  allowedPetIds,
  declarerUserId,
) {
  if (!Array.isArray(petCarersInput)) {
    return { ok: false, status: 400, error: 'pet_carers must be an array' };
  }
  const allowed = new Set(allowedPetIds);
  for (const item of petCarersInput) {
    const petId = item.pet_id || item.petId;
    if (!petId) {
      return { ok: false, status: 400, error: 'Each pet_carer entry requires pet_id' };
    }
    if (!allowed.has(petId)) {
      return { ok: false, status: 400, error: 'pet_id is not on this absence' };
    }

    const hasCarerKind = Object.hasOwn(item, 'carer_kind') || Object.hasOwn(item, 'carerKind');
    const hasContactId = Object.hasOwn(item, 'contact_id') || Object.hasOwn(item, 'contactId');
    const hasPetNote = Object.hasOwn(item, 'pet_note') || Object.hasOwn(item, 'petNote');
    if (!hasCarerKind && !hasContactId && !hasPetNote) {
      continue;
    }

    const columns = [];
    const values = [];

    if (hasCarerKind || hasContactId) {
      const resolved = await resolveCarerWrite(pool, {
        declarerUserId,
        petId,
        item,
      });
      if (resolved === null) {
        continue;
      }
      if (!resolved.ok) {
        return { ok: false, status: resolved.status, error: resolved.error };
      }
      columns.push(
        'carer_kind',
        'carer_user_id',
        'carer_name',
        'carer_note',
        'contact_id',
      );
      values.push(
        resolved.carer_kind,
        resolved.carer_user_id,
        resolved.carer_name,
        resolved.carer_note,
        resolved.contact_id,
      );
    }

    if (hasPetNote) {
      const rawPetNote = Object.hasOwn(item, 'pet_note') ? item.pet_note : item.petNote;
      columns.push('pet_note');
      values.push(normalizePetNoteInput(rawPetNote));
    }

    const setSql = columns.map((column, index) => `${column} = $${index + 1}`).join(', ');
    await pool.query(
      `UPDATE planned_absence_pets
       SET ${setSql}
       WHERE planned_absence_id = $${values.length + 1} AND pet_id = $${values.length + 2}`,
      [...values, absenceId, petId],
    );
  }
  return { ok: true };
}

const LIST_SCOPES = new Set(['upcoming', 'past', 'all']);

export function parseListScope(req) {
  const raw = req.query.scope;
  const scope = raw == null || raw === '' ? 'upcoming' : String(raw).trim().toLowerCase();
  if (!LIST_SCOPES.has(scope)) {
    return { ok: false, error: 'scope must be upcoming, past, or all' };
  }
  return { ok: true, scope };
}

export function listAbsencesSql(scope, todayIso) {
  const base = `SELECT * FROM planned_absences
     WHERE user_id = $1
       AND status != $2`;
  if (scope === 'upcoming') {
    return {
      sql: `${base}
         AND ends_on >= $3::date
         ORDER BY starts_on ASC`,
      params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
    };
  }
  if (scope === 'past') {
    return {
      sql: `${base}
         AND ends_on < $3::date
         ORDER BY starts_on DESC`,
      params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
    };
  }
  return {
    sql: `${base}
       ORDER BY (ends_on < $3::date)::int,
                CASE WHEN ends_on >= $3::date THEN starts_on END ASC NULLS LAST,
                CASE WHEN ends_on < $3::date THEN starts_on END DESC NULLS LAST`,
    params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
  };
}
