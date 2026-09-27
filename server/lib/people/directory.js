import { v4 as uuidv4 } from 'uuid';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @returns {Promise<string>} directory id
 */
export async function ensurePersonalDirectory(pool, userId) {
  const existing = await pool.query(
    'SELECT id FROM people_directories WHERE owner_user_id = $1',
    [userId],
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const id = uuidv4();
  const inserted = await pool.query(
    `INSERT INTO people_directories (id, owner_user_id, created_at, updated_at)
     VALUES ($1, $2, NOW(), NOW())
     ON CONFLICT (owner_user_id) DO UPDATE
       SET updated_at = people_directories.updated_at
     RETURNING id`,
    [id, userId],
  );
  return inserted.rows[0].id;
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
