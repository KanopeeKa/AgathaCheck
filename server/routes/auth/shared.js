import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';
import { isActiveMember } from '../../lib/orgRoles.js';

export const FORGOT_PASSWORD_MESSAGE = 'If that email exists, a reset code has been sent.';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isValidUuid(value) {
  return typeof value === 'string' && UUID_RE.test(value);
}

export function isProduction() {
  return process.env.NODE_ENV === 'production';
}

export const TOKEN_TYPE_ACCESS = 'access';
export const TOKEN_TYPE_REFRESH = 'refresh';

export function signAccessToken(id, email) {
  return jwt.sign({ id, email, typ: TOKEN_TYPE_ACCESS }, JWT_SECRET, { expiresIn: '30m' });
}

export function signRefreshToken(id, email, sid) {
  return jwt.sign({ id, email, typ: TOKEN_TYPE_REFRESH, sid }, JWT_SECRET, { expiresIn: '30d' });
}

export function verifyAccessToken(token) {
  const payload = jwt.verify(token, JWT_SECRET);
  if (payload.typ !== TOKEN_TYPE_ACCESS) {
    const err = new Error('Invalid token type');
    err.name = 'JsonWebTokenError';
    throw err;
  }
  return payload;
}

export function verifyRefreshToken(token) {
  const payload = jwt.verify(token, JWT_SECRET);
  if (payload.typ !== TOKEN_TYPE_REFRESH) {
    const err = new Error('Invalid token type');
    err.name = 'JsonWebTokenError';
    throw err;
  }
  if (!payload.sid) {
    const err = new Error('Invalid refresh token');
    err.name = 'JsonWebTokenError';
    throw err;
  }
  return payload;
}

/** @deprecated Use verifyAccessToken — kept for profile/password routes. */
export function verifyToken(token) {
  return verifyAccessToken(token);
}

export function extractToken(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
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
