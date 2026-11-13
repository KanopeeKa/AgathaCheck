/**
 * Grant or revoke support staff flag (D-005). Only via ops script — never profile or tokens.
 */

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} email
 * @param {boolean} isStaff
 */
export async function setSupportStaffFlagByEmail(pool, email, isStaff) {
  const trimmed = typeof email === 'string' ? email.trim() : '';
  if (!trimmed) {
    return { ok: false, reason: 'invalid_email' };
  }
  const normalised = trimmed.toLowerCase();
  const result = await pool.query(
    `UPDATE users
     SET is_support_staff = $1
     WHERE lower(trim(email)) = $2
     RETURNING id, email, is_support_staff`,
    [Boolean(isStaff), normalised],
  );
  if (result.rowCount === 0) {
    return { ok: false, reason: 'not_found' };
  }
  return { ok: true, user: result.rows[0] };
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 */
export async function userIsSupportStaff(pool, userId) {
  const result = await pool.query(
    'SELECT is_support_staff FROM users WHERE id = $1',
    [userId],
  );
  if (result.rows.length === 0) {
    return null;
  }
  return Boolean(result.rows[0].is_support_staff);
}
