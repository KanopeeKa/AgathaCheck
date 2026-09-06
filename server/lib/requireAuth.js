/**
 * Central JWT auth helpers for Pet Care routes (F-08).
 * Replaces duplicated extractUserId copies across route files.
 */
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';

/**
 * @param {string | undefined} authHeader
 * @returns {string | null} user id
 */
export function userIdFromAuthHeader(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  try {
    const payload = jwt.verify(authHeader.substring(7), JWT_SECRET);
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
 * Express middleware — sets req.userId or responds 401.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
export function requireAuth(req, res, next) {
  const userId = extractUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  req.userId = userId;
  return next();
}

/**
 * @param {import('express').Request} req
 * @returns {string | null}
 */
export function getRequestUserId(req) {
  return req.userId ?? extractUserId(req);
}
