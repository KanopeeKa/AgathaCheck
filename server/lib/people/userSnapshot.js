import { userDisplayName } from '../notificationHelper.js';

/**
 * @param {object} userRow users row with id, first_name, last_name, email
 * @returns {{ user_id: string, display_name: string }}
 */
export function userRowToSnapshot(userRow) {
  if (!userRow?.id) return null;
  return {
    user_id: userRow.id,
    display_name: userDisplayName(userRow),
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 */
export async function fetchUserSnapshot(pool, userId) {
  if (!userId) return null;
  const result = await pool.query(
    'SELECT id, first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  if (result.rows.length === 0) return null;
  return userRowToSnapshot(result.rows[0]);
}
