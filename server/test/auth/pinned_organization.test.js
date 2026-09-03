import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  userId,
  userRow,
  buildMockPool,
  makeToken,
  mockComparePassword,
} from './helpers.js';

const orgId = 'a2000001-0001-4001-8001-000000000001';

describe('Auth Routes — pinned organization preference', () => {
  function buildPoolWithMembership(role, userOverrides = {}) {
    const { userRow: rowOverrides = {}, clearPinnedOrg, ...poolOverrides } = userOverrides;
    return buildMockPool({
      ...poolOverrides,
      selectUserById: async () => ({
        rows: [{ ...userRow, ...rowOverrides }],
      }),
      selectOrgMembership: async () => ({
        rows: role ? [{ role }] : [],
      }),
      updateUser: async (sql, params) => ({
        rows: [{
          ...userRow,
          ...rowOverrides,
          pinned_organization_id: params[0] ?? null,
        }],
      }),
      clearPinnedOrg: clearPinnedOrg || (async () => ({ rows: [] })),
    });
  }

  describe('GET /api/auth/me', () => {
    it('returns pinned_organization_id when user has an active membership pin', async () => {
      const pool = buildPoolWithMembership('admin', {
        userRow: { pinned_organization_id: orgId },
      });
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pinned_organization_id', orgId);
    });

    it('returns null and clears stale pin when membership is missing', async () => {
      const clearCalls = [];
      const pool = buildPoolWithMembership(null, {
        userRow: { pinned_organization_id: orgId },
        clearPinnedOrg: async (sql, params) => {
          clearCalls.push({ sql, params });
          return { rows: [] };
        },
      });
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pinned_organization_id', null);
      expect(clearCalls).toHaveLength(1);
      expect(clearCalls[0].params).toEqual([userId]);
    });

    it('returns null and clears stale pin when membership is pending', async () => {
      const clearCalls = [];
      const pool = buildPoolWithMembership(null, {
        userRow: { pinned_organization_id: orgId },
        selectOrgMembership: async () => ({ rows: [{ role: 'pending_admin' }] }),
        clearPinnedOrg: async (sql, params) => {
          clearCalls.push({ sql, params });
          return { rows: [] };
        },
      });
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pinned_organization_id', null);
      expect(clearCalls).toHaveLength(1);
    });
  });

  describe('PUT /api/auth/me', () => {
    it('round-trips pinned_organization_id for an active member', async () => {
      const pool = buildPoolWithMembership('associate');
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ pinned_organization_id: orgId });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pinned_organization_id', orgId);
    });

    it('allows unpinning with null', async () => {
      const pool = buildPoolWithMembership('admin', {
        userRow: { pinned_organization_id: orgId },
      });
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ pinned_organization_id: null });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pinned_organization_id', null);
    });

    it('returns 400 for invalid pinned_organization_id format', async () => {
      const pool = buildPoolWithMembership('admin');
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ pinned_organization_id: 'not-a-uuid' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid pinned_organization_id');
    });

    it('returns 403 when user is not an active member of the org', async () => {
      const pool = buildPoolWithMembership(null);
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ pinned_organization_id: orgId });
      expect(res.statusCode).toBe(403);
      expect(res.body).toHaveProperty('error', 'Not an active member of this organization');
    });

    it('returns 403 when membership is pending', async () => {
      const pool = buildPoolWithMembership(null, {
        selectOrgMembership: async () => ({ rows: [{ role: 'pending_associate' }] }),
      });
      const app = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ pinned_organization_id: orgId });
      expect(res.statusCode).toBe(403);
      expect(res.body).toHaveProperty('error', 'Not an active member of this organization');
    });
  });
});
