import { getPersonalDirectoryId } from './directory.js';

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
  if (await userOwnsContact(pool, contactId, callerUserId)) return true;
  if (petOwnerUserId && petOwnerUserId !== callerUserId) {
    return userOwnsContact(pool, contactId, petOwnerUserId);
  }
  return false;
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
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 */
export async function assertPersonalDirectoryOwner(pool, userId) {
  const directoryId = await getPersonalDirectoryId(pool, userId);
  return directoryId;
}
