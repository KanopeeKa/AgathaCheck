import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import {
  JWT_SECRET,
  userEmail,
  buildMockPool,
  makeToken,
  makeRefreshToken,
  mockComparePassword,
  seedRefreshSession,
} from './helpers.js';

describe('Auth Routes — Session v2 (F-05, F-06)', () => {
  let app;
  let mockPool;

  beforeEach(() => {
    mockPool = buildMockPool();
    app = createApp(mockPool, mockComparePassword);
  });

  describe('Token typ claims (F-05)', () => {
    it('rejects refresh token on protected /me endpoint', async () => {
      const refreshToken = makeRefreshToken();
      seedRefreshSession(mockPool, refreshToken);
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${refreshToken}`);
      expect(res.statusCode).toBe(401);
    });

    it('rejects access token on refresh endpoint', async () => {
      const accessToken = makeToken();
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: accessToken });
      expect(res.statusCode).toBe(401);
    });

    it('login issues tokens with distinct typ claims', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      const access = jwt.verify(res.body.access_token, JWT_SECRET);
      const refresh = jwt.verify(res.body.refresh_token, JWT_SECRET);
      expect(access.typ).toBe('access');
      expect(refresh.typ).toBe('refresh');
      expect(access.sid).toBeUndefined();
      expect(refresh.sid).toBeDefined();
    });
  });

  describe('Refresh rotation and reuse detection (F-06)', () => {
    it('rotates refresh token on each refresh', async () => {
      const refreshToken = makeRefreshToken();
      seedRefreshSession(mockPool, refreshToken);
      const first = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken });
      expect(first.statusCode).toBe(200);
      expect(first.body.refresh_token).not.toBe(refreshToken);

      const second = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: first.body.refresh_token });
      expect(second.statusCode).toBe(200);
      expect(second.body.refresh_token).not.toBe(first.body.refresh_token);
    });

    it('detects reuse of a rotated refresh token and revokes the family', async () => {
      const refreshToken = makeRefreshToken();
      const session = seedRefreshSession(mockPool, refreshToken);
      const rotated = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken });
      expect(rotated.statusCode).toBe(200);

      const reuse = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken });
      expect(reuse.statusCode).toBe(401);

      const familyBlocked = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: rotated.body.refresh_token });
      expect(familyBlocked.statusCode).toBe(401);

      const revokedRows = [...mockPool._refreshSessions.values()]
        .filter((row) => row.family_id === session.family_id);
      expect(revokedRows.length).toBeGreaterThan(0);
      expect(revokedRows.every((row) => row.revoked_at)).toBe(true);
    });
  });

  describe('HttpOnly cookie refresh (F-07)', () => {
    it('login sets HttpOnly refresh cookie on /api/auth path', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      const setCookie = res.headers['set-cookie'];
      expect(setCookie).toBeDefined();
      const cookies = Array.isArray(setCookie) ? setCookie : [setCookie];
      expect(cookies.some((c) => c.includes('HttpOnly'))).toBe(true);
      expect(cookies.some((c) => c.includes('Path=/api/auth'))).toBe(true);
      expect(cookies.some((c) => c.includes('Path=/backend/api/auth'))).toBe(true);
    });

    it('refresh accepts HttpOnly cookie without body refresh_token', async () => {
      const login = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(login.statusCode).toBe(200);

      const setCookie = login.headers['set-cookie'];
      const cookieHeader = Array.isArray(setCookie) ? setCookie.join('; ') : setCookie;

      const refresh = await request(app)
        .post('/api/auth/refresh')
        .set('Cookie', cookieHeader)
        .send({});
      expect(refresh.statusCode).toBe(200);
      expect(refresh.body.access_token).toBeDefined();
      expect(refresh.body.refresh_token).toBeDefined();
    });

    it('logout clears refresh cookie', async () => {
      const login = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(login.statusCode).toBe(200);

      const setCookie = login.headers['set-cookie'];
      const cookieHeader = Array.isArray(setCookie) ? setCookie.join('; ') : setCookie;

      const logout = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${login.body.access_token}`)
        .set('Cookie', cookieHeader);
      expect(logout.statusCode).toBe(200);

      const cleared = logout.headers['set-cookie'];
      expect(cleared).toBeDefined();
      const clearedCookies = Array.isArray(cleared) ? cleared : [cleared];
      expect(clearedCookies.some((c) => c.includes('Max-Age=0'))).toBe(true);
    });

    it('cookie refresh works on /backend/api/auth path', async () => {
      const login = await request(app)
        .post('/backend/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(login.statusCode).toBe(200);

      const setCookie = login.headers['set-cookie'];
      const cookieHeader = Array.isArray(setCookie) ? setCookie.join('; ') : setCookie;

      const refresh = await request(app)
        .post('/backend/api/auth/refresh')
        .set('Cookie', cookieHeader)
        .send({});
      expect(refresh.statusCode).toBe(200);
      expect(refresh.body.access_token).toBeDefined();
    });
  });

  describe('Logout and password change revoke sessions (E2, E4)', () => {
    it('logout invalidates refresh tokens for all devices', async () => {
      const login = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(login.statusCode).toBe(200);

      const logout = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${login.body.access_token}`);
      expect(logout.statusCode).toBe(200);

      const refresh = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: login.body.refresh_token });
      expect(refresh.statusCode).toBe(401);
    });

    it('password change revokes all refresh sessions', async () => {
      const login = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(login.statusCode).toBe(200);

      const change = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${login.body.access_token}`)
        .send({ currentPassword: 'testpassword', newPassword: 'NewPassword123' });
      expect(change.statusCode).toBe(200);

      const refresh = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: login.body.refresh_token });
      expect(refresh.statusCode).toBe(401);
    });
  });
});
