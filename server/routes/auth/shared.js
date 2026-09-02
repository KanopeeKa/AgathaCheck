import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';

export const FORGOT_PASSWORD_MESSAGE = 'If that email exists, a reset code has been sent.';

export function isProduction() {
  return process.env.NODE_ENV === 'production';
}

export function signAccessToken(id, email) {
  return jwt.sign({ id, email }, JWT_SECRET, { expiresIn: '30m' });
}

export function signRefreshToken(id, email) {
  return jwt.sign({ id, email }, JWT_SECRET, { expiresIn: '30d' });
}

export function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
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
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}
