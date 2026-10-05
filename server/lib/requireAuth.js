/**
 * Central JWT auth helpers for Pet Care routes (F-08) and auth routers (H.4).
 */
import { errorDetails } from '../config/security.js';
import { verifyAccessToken, extractToken } from './auth/tokens.js';

/**
 * @param {string | undefined} authHeader
 * @returns {string | null} user id
 */
export function userIdFromAuthHeader(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  try {
    const payload = verifyAccessToken(authHeader.substring(7));
    return payload?.id ?? null;
  } catch (_) {
    return null;
  }
}

/**
 * @param {import('express').Request} req
 * @returns {string | null}
 */
export function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  return userIdFromAuthHeader(auth);
}

/**
 * @param {{ invalidTokenAsServerError?: string }} [options]
 */
export function createRequireAuth(options = {}) {
  const { invalidTokenAsServerError } = options;

  return function requireAuthMiddleware(req, res, next) {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyAccessToken(token);
      if (!payload?.id) {
        const err = new Error('missing subject');
        if (invalidTokenAsServerError) {
          err.exposeProdMessage = invalidTokenAsServerError;
          return next(err);
        }
        return res.status(401).json({
          error: 'Invalid or expired token',
          ...errorDetails(err),
        });
      }
      req.principal = { id: payload.id, email: payload.email };
      req.userId = payload.id;
      return next();
    } catch (err) {
      if (invalidTokenAsServerError) {
        err.exposeProdMessage = invalidTokenAsServerError;
        return next(err);
      }
      return res.status(401).json({ error: 'Invalid or expired token', ...errorDetails(err) });
    }
  };
}

/** Default principal middleware for auth routes (401 on invalid bearer). */
export const requireAuth = createRequireAuth();

/**
 * @param {import('express').Request} req
 * @returns {string | null}
 */
export function getRequestUserId(req) {
  return req.userId ?? extractUserId(req);
}
