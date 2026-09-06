import jwt from 'jsonwebtoken';
import {
  extractUserId,
  getRequestUserId,
  requireAuth,
  userIdFromAuthHeader,
} from '../lib/requireAuth.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

describe('requireAuth', () => {
  const userId = 'user-auth-1';
  const token = jwt.sign({ id: userId, email: 'a@example.com' }, JWT_SECRET, { expiresIn: '1h' });

  it('userIdFromAuthHeader returns id for valid bearer token', () => {
    expect(userIdFromAuthHeader(`Bearer ${token}`)).toBe(userId);
  });

  it('userIdFromAuthHeader returns null for missing or invalid token', () => {
    expect(userIdFromAuthHeader(undefined)).toBeNull();
    expect(userIdFromAuthHeader('Bearer bad')).toBeNull();
    expect(userIdFromAuthHeader('Basic x')).toBeNull();
  });

  it('extractUserId reads Authorization header from request', () => {
    const req = { headers: { authorization: `Bearer ${token}` } };
    expect(extractUserId(req)).toBe(userId);
  });

  it('requireAuth middleware sets req.userId and calls next', () => {
    const req = { headers: { Authorization: `Bearer ${token}` } };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    const next = jest.fn();
    requireAuth(req, res, next);
    expect(req.userId).toBe(userId);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('requireAuth middleware returns 401 when unauthenticated', () => {
    const req = { headers: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    const next = jest.fn();
    requireAuth(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
    expect(next).not.toHaveBeenCalled();
  });

  it('getRequestUserId prefers req.userId when set', () => {
    const req = { userId: 'cached-id', headers: {} };
    expect(getRequestUserId(req)).toBe('cached-id');
  });
});
