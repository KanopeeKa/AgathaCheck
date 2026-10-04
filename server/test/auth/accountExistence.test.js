import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  isExemptPath,
  createAccountExistenceMiddleware,
} from '../../lib/auth/accountExistence.js';
import {
  buildMockPool,
  makeToken,
  makeRefreshToken,
  mockComparePassword,
  seedRefreshSession,
  userEmail,
  userId,
} from './helpers.js';

describe('accountExistence middleware', () => {
  describe('isExemptPath', () => {
    it('exempts DELETE /auth/me', () => {
      expect(isExemptPath('DELETE', '/auth/me')).toBe(true);
    });

    it('exempts GET /auth/erasure/:operationId', () => {
      expect(
        isExemptPath('GET', '/auth/erasure/123e4567-e89b-12d3-a456-426614174000'),
      ).toBe(true);
    });

    it('does not exempt other auth routes', () => {
      expect(isExemptPath('GET', '/auth/me')).toBe(false);
      expect(isExemptPath('POST', '/auth/login')).toBe(false);
    });
  });

  describe('HTTP behaviour (mock pool)', () => {
    it('passes through without Authorization', async () => {
      const app = createApp(buildMockPool(), mockComparePassword);
      const res = await request(app).get('/api/pets');
      expect(res.statusCode).toBe(401);
      expect(res.body.code).toBeUndefined();
    });

    it('passes through with invalid bearer token', async () => {
      const app = createApp(buildMockPool(), mockComparePassword);
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', 'Bearer not-a-jwt');
      expect(res.statusCode).toBe(401);
      expect(res.body.code).toBeUndefined();
    });

    it('returns account_unavailable when user row is missing', async () => {
      const pool = buildMockPool({
        selectUserExists: async () => ({ rows: [] }),
      });
      const app = createApp(pool, mockComparePassword);
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${makeToken()}`);
      expect(res.statusCode).toBe(401);
      expect(res.body).toEqual({
        error: 'Unauthorized',
        code: 'account_unavailable',
      });
    });

    it('allows DELETE /auth/me without user row (exempt)', async () => {
      const pool = buildMockPool({
        selectUserExists: async () => ({ rows: [] }),
      });
      const app = createApp(pool, mockComparePassword);
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${makeToken()}`)
        .send({ password: 'testpassword' });
      expect(res.statusCode).not.toBe(401);
      expect(res.body.code).not.toBe('account_unavailable');
    });

    it('runs exactly one users existence query per authed request', async () => {
      let existenceQueries = 0;
      const pool = buildMockPool();
      const baseQuery = pool.query.bind(pool);
      pool.query = async (sql, params) => {
        if (String(sql).includes('SELECT 1 FROM users WHERE id')) {
          existenceQueries += 1;
        }
        return baseQuery(sql, params);
      };
      const app = createApp(pool, mockComparePassword);
      await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${makeToken()}`);
      expect(existenceQueries).toBe(1);
    });
  });

  describe('session endpoints after erasure (F.3-5)', () => {
    it('login fails when the user row no longer exists', async () => {
      const pool = buildMockPool({
        selectUserByEmail: async () => ({ rows: [] }),
      });
      const app = createApp(pool, mockComparePassword);
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(401);
      expect(res.body.error).toMatch(/invalid/i);
    });

    it('refresh fails when the user row no longer exists', async () => {
      const pool = buildMockPool({
        selectUserExists: async () => ({ rows: [] }),
      });
      const app = createApp(pool, mockComparePassword);
      const refreshToken = makeRefreshToken();
      seedRefreshSession(pool, refreshToken);
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken });
      expect(res.statusCode).toBe(401);
    });
  });

  describe('factory unit', () => {
    it('invokes pool.query with SELECT 1 for verified access tokens', async () => {
      const queries = [];
      const pool = {
        query: async (sql, params) => {
          queries.push({ sql, params });
          return { rows: [{ '?column?': 1 }] };
        },
      };
      const mw = createAccountExistenceMiddleware(pool);
      const req = {
        method: 'GET',
        path: '/pets',
        headers: { authorization: `Bearer ${makeToken()}` },
      };
      const res = { status: () => res, json: () => res };
      let nextCalled = false;
      await mw(req, res, () => {
        nextCalled = true;
      });
      expect(nextCalled).toBe(true);
      expect(queries).toHaveLength(1);
      expect(queries[0].sql).toBe('SELECT 1 FROM users WHERE id = $1');
      expect(queries[0].params[0]).toBe(userId);
    });
  });
});
