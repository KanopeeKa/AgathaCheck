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

/**
 * Care handover scope for absence guests (stub until s4 read models).
 * @param {import('pg').Pool|import('pg').PoolClient} _pool
 * @param {string} _userId
 * @param {string} _absenceId
 */
export async function careHandoverScope(_pool, _userId, _absenceId) {
  return { pet_ids: [], contact_ids: [], stub: true };
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
