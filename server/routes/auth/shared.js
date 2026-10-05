import { isActiveMember } from '../../lib/orgRoles.js';
export { extractToken } from '../../lib/auth/tokens.js';
export { isProduction } from '../../lib/auth/runtime.js';

export const FORGOT_PASSWORD_MESSAGE = 'If that email exists, a reset code has been sent.';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isValidUuid(value) {
  return typeof value === 'string' && UUID_RE.test(value);
}

export function userRowToMap(row) {
  return {
    id: row.id,
    email: row.email,
    first_name: row.first_name || '',
    last_name: row.last_name || '',
    category: row.category || 'pet_carer',
    bio: row.bio || '',
    photo_url: row.photo_url || '',
    locale: row.locale || 'en',
    timezone: row.timezone || 'UTC',
    weight_unit: row.weight_unit || 'kg',
    pinned_organization_id: row.pinned_organization_id || null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

/**
 * Returns active membership role for org, or null when not an active member.
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {string} orgId
 */
export async function getActiveOrgMembershipRole(pool, userId, orgId) {
  const result = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, userId],
  );
  if (result.rows.length === 0) return null;
  const role = result.rows[0].role;
  return isActiveMember(role) ? role : null;
}

/**
 * Clears a stale pin when the user is no longer an active member.
 * @returns {Promise<string|null>} effective pinned org id
 */
export async function reconcilePinnedOrganizationId(pool, userId, pinnedOrgId) {
  if (!pinnedOrgId) return null;
  const role = await getActiveOrgMembershipRole(pool, userId, pinnedOrgId);
  if (role) return pinnedOrgId;
  await pool.query(
    'UPDATE users SET pinned_organization_id = NULL, updated_at = NOW() WHERE id = $1 AND pinned_organization_id = $2',
    [userId, pinnedOrgId],
  );
  return null;
}
