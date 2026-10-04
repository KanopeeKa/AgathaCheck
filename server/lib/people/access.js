import { CO_PARENT_ROLE, userCanManageProfile } from '../petAccess.js';
import { getPersonalDirectoryId } from './directory.js';
import { PeopleError, PEOPLE_ERROR_CODES } from './errors.js';

/**
 * Directory ids the viewer may list (personal only until household directories in s5).
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @returns {Promise<string[]>}
 */
export async function visibleDirectoryIds(pool, userId) {
  const id = await getPersonalDirectoryId(pool, userId);
  return id ? [id] : [];
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
async function isPersonalDirectoryOwner(pool, contactId, userId) {
  if (!contactId || !userId) return false;
  const result = await pool.query(
    `SELECT 1
     FROM people_contacts pc
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE pc.id = $1 AND pd.owner_user_id = $2`,
    [contactId, userId],
  );
  return result.rows.length > 0;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} viewerUserId
 */
export async function canViewContact(pool, contactId, viewerUserId) {
  if (await isPersonalDirectoryOwner(pool, contactId, viewerUserId)) {
    return true;
  }
  const related = await pool.query(
    `SELECT 1
     FROM pet_contact_relationships pcr
     INNER JOIN pets p ON p.id = pcr.pet_id
     WHERE pcr.contact_id = $1
       AND (
         p.user_id = $2
         OR EXISTS (
           SELECT 1 FROM pet_access pa
           WHERE pa.pet_id = p.id AND pa.user_id = $2
             AND pa.role = $3 AND COALESCE(pa.hidden, false) = false
         )
       )
     LIMIT 1`,
    [contactId, viewerUserId, CO_PARENT_ROLE],
  );
  return related.rows.length > 0;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
export async function canEditContact(pool, contactId, userId) {
  return isPersonalDirectoryOwner(pool, contactId, userId);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @returns {Promise<string|null>}
 */
export async function getPetOwnerUserId(pool, petId) {
  const result = await pool.query('SELECT user_id FROM pets WHERE id = $1', [petId]);
  return result.rows[0]?.user_id ?? null;
}

/**
 * Contact in caller's directory or the pet record owner's personal directory.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} callerUserId
 * @param {string|null} petOwnerUserId
 */
export async function contactInEditableDirectoriesForPet(
  pool,
  contactId,
  callerUserId,
  petOwnerUserId,
) {
  if (await isPersonalDirectoryOwner(pool, contactId, callerUserId)) return true;
  if (petOwnerUserId && petOwnerUserId !== callerUserId) {
    return isPersonalDirectoryOwner(pool, contactId, petOwnerUserId);
  }
  return false;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} contactId
 * @param {string} petId
 */
export async function canAttachContactToPet(pool, userId, contactId, petId) {
  if (!(await userCanManageProfile(pool, petId, userId))) return false;
  const petOwnerId = await getPetOwnerUserId(pool, petId);
  if (!petOwnerId) return false;
  return contactInEditableDirectoriesForPet(pool, contactId, userId, petOwnerId);
}

const HANDOVER_SLOT_KINDS = [
  'primary_vet',
  'out_of_hours_vet',
  'emergency_contact',
  'care_provider',
];

/**
 * Contacts visible in the care handover scope for one pet.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} petId
 */
export async function careHandoverScopeForPet(pool, userId, petId) {
  if (!petId || !userId) {
    return { pet_ids: [], contact_ids: [], starts_on: null, ends_on: null };
  }

  const relResult = await pool.query(
    `SELECT contact_id
     FROM pet_contact_relationships
     WHERE pet_id = $1
       AND active = true
       AND relationship_kind = ANY($2::text[])`,
    [petId, HANDOVER_SLOT_KINDS],
  );
  const contactIds = new Set(relResult.rows.map((r) => r.contact_id));

  const providerResult = await pool.query(
    `SELECT DISTINCT he.provider_contact_id AS contact_id
     FROM health_entries he
     WHERE he.pet_id = $1 AND he.provider_contact_id IS NOT NULL`,
    [petId],
  );
  for (const row of providerResult.rows) {
    if (row.contact_id) contactIds.add(row.contact_id);
  }

  let startsOn = null;
  let endsOn = null;
  const guestAbsence = await pool.query(
    `SELECT pa.starts_on, pa.ends_on
     FROM planned_absence_guest_grants g
     INNER JOIN planned_absences pa ON pa.id = g.planned_absence_id
     WHERE g.grantee_user_id = $1
       AND g.pet_id = $2
       AND g.status = 'active'
       AND pa.status = 'active'
       AND (CURRENT_TIMESTAMP AT TIME ZONE COALESCE(pa.timezone, 'UTC'))::date
           BETWEEN pa.starts_on AND pa.ends_on
     ORDER BY pa.starts_on
     LIMIT 1`,
    [userId, petId],
  );
  if (guestAbsence.rows.length > 0) {
    startsOn = guestAbsence.rows[0].starts_on;
    endsOn = guestAbsence.rows[0].ends_on;
  }

  return {
    pet_ids: [petId],
    contact_ids: [...contactIds],
    starts_on: startsOn ? String(startsOn).split(/[T ]/)[0] : null,
    ends_on: endsOn ? String(endsOn).split(/[T ]/)[0] : null,
  };
}

/**
 * Care handover scope for an absence (guest grants).
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} absenceId
 */
export async function careHandoverScope(pool, userId, absenceId) {
  if (!absenceId || !userId) {
    return { pet_ids: [], contact_ids: [], starts_on: null, ends_on: null };
  }

  const absenceResult = await pool.query(
    `SELECT pa.starts_on, pa.ends_on
     FROM planned_absences pa
     WHERE pa.id = $1`,
    [absenceId],
  );
  const absence = absenceResult.rows[0];
  if (!absence) {
    return { pet_ids: [], contact_ids: [], starts_on: null, ends_on: null };
  }

  const petsResult = await pool.query(
    `SELECT DISTINCT g.pet_id
     FROM planned_absence_guest_grants g
     WHERE g.planned_absence_id = $1
       AND g.grantee_user_id = $2
       AND g.status = 'active'`,
    [absenceId, userId],
  );
  const petIds = petsResult.rows.map((r) => r.pet_id);
  const contactIdSet = new Set();
  for (const petId of petIds) {
    const scope = await careHandoverScopeForPet(pool, userId, petId);
    for (const id of scope.contact_ids) contactIdSet.add(id);
  }

  return {
    pet_ids: petIds,
    contact_ids: [...contactIdSet],
    starts_on: absence.starts_on ? String(absence.starts_on).split(/[T ]/)[0] : null,
    ends_on: absence.ends_on ? String(absence.ends_on).split(/[T ]/)[0] : null,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
export async function assertCanViewContact(pool, contactId, userId) {
  if (!(await canViewContact(pool, contactId, userId))) {
    throw new PeopleError(PEOPLE_ERROR_CODES.FORBIDDEN, 403, 'Forbidden');
  }
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
export async function assertCanEditContact(pool, contactId, userId) {
  if (!(await canEditContact(pool, contactId, userId))) {
    throw new PeopleError(PEOPLE_ERROR_CODES.FORBIDDEN, 403, 'Forbidden');
  }
}
