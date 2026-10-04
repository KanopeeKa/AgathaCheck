import {
  canAttachContactToPet,
  contactInEditableDirectoriesForPet,
  getPetOwnerUserId,
} from './access.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} userId
 */
export async function userOwnsContact(pool, contactId, userId) {
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
 * Contact in caller's directory or the pet record owner's directory.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} callerUserId
 * @param {string} petOwnerUserId
 */
export async function contactUsableForPet(pool, contactId, callerUserId, petOwnerUserId) {
  return contactInEditableDirectoriesForPet(
    pool,
    contactId,
    callerUserId,
    petOwnerUserId,
  );
}

export { getPetOwnerUserId, canAttachContactToPet };
