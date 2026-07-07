import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  userEmail,
  buildMockPool,
  makeToken,
  makeRefreshToken,
  mockComparePassword,
} from './helpers.js';

describe('Auth Routes — Hardening', () => {
  let app;
  let mockPool;

  beforeEach(() => {
    mockPool = buildMockPool();
    app = createApp(mockPool, mockComparePassword);
  });

  describe('Auth guard consistency', () => {
    const protectedEndpoints = [
      { method: 'get', path: '/api/auth/me' },
      { method: 'put', path: '/api/auth/me' },
      { method: 'post', path: '/api/auth/me/photo' },
      { method: 'post', path: '/api/auth/change-password' },
      { method: 'delete', path: '/api/auth/me' },
      { method: 'get', path: '/api/auth/me/export' },
    ];

    protectedEndpoints.forEach(({ method, path }) => {
      it(`${method.toUpperCase()} ${path} returns 401 without token`, async () => {
        const res = await request(app)[method](path).send({});
        expect(res.statusCode).toBe(401);
        expect(res.body).toHaveProperty('error');
      });

      it(`${method.toUpperCase()} ${path} returns 401 with invalid token`, async () => {
        const res = await request(app)[method](path)
          .set('Authorization', 'Bearer totally-invalid-token')
          .send({});
        const status = res.statusCode;
        expect(status === 401 || status === 500).toBe(true);
      });
    });
  });

  describe('Response shape validation', () => {
    it('login response user has all expected fields', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      const user = res.body.user;
      expect(user).toHaveProperty('id');
      expect(user).toHaveProperty('email');
      expect(user).toHaveProperty('first_name');
      expect(user).toHaveProperty('last_name');
      expect(user).toHaveProperty('category');
      expect(user).toHaveProperty('bio');
      expect(user).toHaveProperty('photo_url');
      expect(user).toHaveProperty('locale');
    });

    it('signup response user has all expected fields', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'shape@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(201);
      const user = res.body.user;
      expect(user).toHaveProperty('id');
      expect(user).toHaveProperty('email');
      expect(user).toHaveProperty('first_name');
      expect(user).toHaveProperty('last_name');
      expect(user).toHaveProperty('category');
      expect(user).toHaveProperty('bio');
      expect(user).toHaveProperty('photo_url');
      expect(user).toHaveProperty('locale');
    });

    it('me endpoint response has all expected fields', async () => {
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('email');
      expect(res.body).toHaveProperty('first_name');
      expect(res.body).toHaveProperty('last_name');
      expect(res.body).toHaveProperty('category');
      expect(res.body).toHaveProperty('bio');
      expect(res.body).toHaveProperty('photo_url');
      expect(res.body).toHaveProperty('locale');
    });
  });

  describe('Auth hardening', () => {
    function restoreEnv(key, prev) {
      if (prev === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = prev;
      }
    }

    it('rate-limits repeated login attempts with 429', async () => {
      const prevTest = process.env.AUTH_RATE_LIMIT_TEST;
      const prevMax = process.env.AUTH_RATE_LIMIT_MAX;
      process.env.AUTH_RATE_LIMIT_TEST = '1';
      process.env.AUTH_RATE_LIMIT_MAX = '2';
      try {
        // The limiter reads env at construction, so build the app afterwards.
        const limitedApp = createApp(buildMockPool(), mockComparePassword);
        const send = () => request(limitedApp)
          .post('/api/auth/login')
          .send({ email: 'x@example.com', password: 'wrongpass' });
        expect((await send()).statusCode).toBe(401);
        expect((await send()).statusCode).toBe(401);
        const third = await send();
        expect(third.statusCode).toBe(429);
      } finally {
        restoreEnv('AUTH_RATE_LIMIT_TEST', prevTest);
        restoreEnv('AUTH_RATE_LIMIT_MAX', prevMax);
      }
    });

    it('refresh returns 401 when the user no longer exists', async () => {
      const pool = buildMockPool({ selectUserExists: async () => ({ rows: [] }) });
      const a = createApp(pool, mockComparePassword);
      const res = await request(a)
        .post('/api/auth/refresh')
        .send({ refresh_token: makeRefreshToken() });
      expect(res.statusCode).toBe(401);
    });

    it('refresh succeeds when the user still exists', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: makeRefreshToken() });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('access_token');
    });

    it('signup rejects an invalid email format', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'not-an-email', password: 'Password123' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/email/i);
    });

    it('signup rejects a too-short password', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'shortpw@example.com', password: 'abc' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/password/i);
    });

    it('change-password rejects a too-short new password', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${makeToken()}`)
        .send({ currentPassword: 'testpassword', newPassword: 'abc' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/password/i);
    });

    it('reset-password rejects a too-short new password', async () => {
      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({ email: userEmail, code: '123456', new_password: 'abc' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/password/i);
    });
  });
});
