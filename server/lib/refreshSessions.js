import { createHash } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../routes/auth/shared.js';

export class RefreshSessionError extends Error {
  constructor(message, code = 'invalid') {
    super(message);
    this.name = 'RefreshSessionError';
    this.code = code;
  }
}

export function hashRefreshToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ id: string, userId: string, refreshToken: string, familyId: string, rotatedFrom?: string | null }} params
 */
export async function insertRefreshSession(pool, {
  id,
  userId,
  refreshToken,
  familyId,
  rotatedFrom = null,
}) {
  const tokenHash = hashRefreshToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  await pool.query(
    `INSERT INTO refresh_sessions (id, user_id, token_hash, family_id, rotated_from, expires_at)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [id, userId, tokenHash, familyId, rotatedFrom, expiresAt],
  );
}

/**
 * Issue a new access + refresh token pair and persist the refresh session.
 * @param {import('pg').Pool} pool
 * @param {string} userId
 * @param {string} email
 */
export async function issueTokenPair(pool, userId, email) {
  const familyId = uuidv4();
  const sessionId = uuidv4();
  const refreshToken = signRefreshToken(userId, email, sessionId);
  await insertRefreshSession(pool, {
    id: sessionId,
    userId,
    refreshToken,
    familyId,
  });
  const accessToken = signAccessToken(userId, email);
  return { accessToken, refreshToken };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} userId
 */
export async function revokeAllUserRefreshSessions(pool, userId) {
  await pool.query(
    `UPDATE refresh_sessions
        SET revoked_at = NOW()
      WHERE user_id = $1
        AND revoked_at IS NULL`,
    [userId],
  );
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} familyId
 */
export async function revokeRefreshSessionFamily(pool, familyId) {
  await pool.query(
    `UPDATE refresh_sessions
        SET revoked_at = NOW()
      WHERE family_id = $1
        AND revoked_at IS NULL`,
    [familyId],
  );
}

/**
 * Validate refresh JWT, rotate session, and return new token pair.
 * Detects reuse of revoked refresh tokens and revokes the session family.
 * @param {import('pg').Pool} pool
 * @param {string} refreshToken
 */
export async function rotateRefreshToken(pool, refreshToken) {
  const payload = verifyRefreshToken(refreshToken);
  const tokenHash = hashRefreshToken(refreshToken);

  const result = await pool.query(
    `SELECT id, user_id, token_hash, family_id, revoked_at, expires_at
       FROM refresh_sessions
      WHERE id = $1`,
    [payload.sid],
  );

  if (result.rows.length === 0) {
    throw new RefreshSessionError('Invalid or expired refresh token');
  }

  const session = result.rows[0];

  if (session.user_id !== payload.id) {
    throw new RefreshSessionError('Invalid or expired refresh token');
  }

  if (new Date(session.expires_at) <= new Date()) {
    throw new RefreshSessionError('Invalid or expired refresh token');
  }

  if (session.revoked_at) {
    if (session.token_hash === tokenHash) {
      await revokeRefreshSessionFamily(pool, session.family_id);
      throw new RefreshSessionError('Refresh token reuse detected', 'reuse');
    }
    throw new RefreshSessionError('Invalid or expired refresh token');
  }

  if (session.token_hash !== tokenHash) {
    throw new RefreshSessionError('Invalid or expired refresh token');
  }

  const newSessionId = uuidv4();
  const newRefreshToken = signRefreshToken(payload.id, payload.email, newSessionId);
  const newTokenHash = hashRefreshToken(newRefreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await pool.query(
    'UPDATE refresh_sessions SET revoked_at = NOW() WHERE id = $1',
    [session.id],
  );

  await pool.query(
    `INSERT INTO refresh_sessions (id, user_id, token_hash, family_id, rotated_from, expires_at)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [newSessionId, payload.id, newTokenHash, session.family_id, session.id, expiresAt],
  );

  const accessToken = signAccessToken(payload.id, payload.email);
  return { accessToken, refreshToken: newRefreshToken };
}
