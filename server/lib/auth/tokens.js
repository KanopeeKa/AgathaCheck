import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';

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
  if (payload.typ === TOKEN_TYPE_REFRESH) {
    const err = new Error('Invalid token type');
    err.name = 'JsonWebTokenError';
    throw err;
  }
  if (payload.typ !== undefined && payload.typ !== TOKEN_TYPE_ACCESS) {
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

export function extractToken(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}
