import { ensurePersonalDirectory as ensurePersonalDirectoryRepo } from './contactsRepo.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @returns {Promise<string>} directory id
 */
export async function ensurePersonalDirectory(pool, userId) {
  return ensurePersonalDirectoryRepo(pool, userId);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @returns {Promise<string|null>}
 */
export async function getPersonalDirectoryId(pool, userId) {
  const result = await pool.query(
    'SELECT id FROM people_directories WHERE owner_user_id = $1',
    [userId],
  );
  return result.rows[0]?.id ?? null;
}
