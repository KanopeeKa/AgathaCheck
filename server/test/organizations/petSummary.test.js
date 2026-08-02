import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

function buildPetSummaryPool({ memberRole = 'associate', rows = [] } = {}) {
  const captured = { sql: null, params: null };
  const query = async (sql, params) => {
    if (sql.includes('SELECT role') && sql.includes('organization_users')) {
      return { rows: memberRole ? [{ role: memberRole }] : [] };
    }
    if (sql.includes('FROM organization_permissions')) {
      return { rows: [] };
    }
    if (sql.includes('COALESCE(p.last_activity_at, p.created_at)')) {
      captured.sql = sql;
      captured.params = params;
      return { rows };
    }
    return { rows: [] };
  };

  return {
    pool: {
      query,
      connect: async () => ({ query, release: () => {} }),
      end: async () => {},
    },
    captured,
  };
}

describe('GET /:orgId/pets/summary', () => {
  it('requires view_org_pets and returns summary rows for an associate', async () => {
    const summaryRows = [
      {
        id: 'pet-1',
        name: 'Buddy',
        species: 'dog',
        breed: 'Labrador',
        photo_path: '/photos/buddy.jpg',
        organization_id: orgId,
        last_activity_at: new Date('2026-07-01T12:00:00Z'),
        created_at: new Date('2024-01-01T00:00:00Z'),
      },
    ];
    const { pool, captured } = buildPetSummaryPool({ memberRole: 'associate', rows: summaryRows });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual([
      {
        id: 'pet-1',
        name: 'Buddy',
        species: 'dog',
        breed: 'Labrador',
        photo_path: '/photos/buddy.jpg',
        organization_id: orgId,
        last_activity_at: '2026-07-01T12:00:00.000Z',
      },
    ]);
    expect(captured.sql).toContain('COALESCE(p.last_activity_at, p.created_at) DESC');
    expect(captured.params[0]).toBe(orgId);
    expect(captured.params[1]).toBe(12);
  });

  it('sorts by COALESCE(last_activity_at, created_at) descending (no-backfill fallback)', async () => {
    const { pool, captured } = buildPetSummaryPool({
      memberRole: 'admin',
      rows: [
        {
          id: 'pet-recent-activity',
          name: 'Active',
          species: 'cat',
          breed: '',
          photo_path: null,
          organization_id: orgId,
          last_activity_at: new Date('2026-07-20T10:00:00Z'),
          created_at: new Date('2020-01-01T00:00:00Z'),
        },
        {
          id: 'pet-no-activity',
          name: 'Legacy',
          species: 'dog',
          breed: 'Mix',
          photo_path: null,
          organization_id: orgId,
          last_activity_at: null,
          created_at: new Date('2026-06-15T08:00:00Z'),
        },
      ],
    });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary?sort=last_activity`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(captured.sql).toMatch(/ORDER BY COALESCE\(p\.last_activity_at, p\.created_at\) DESC/);
    expect(res.body[0].id).toBe('pet-recent-activity');
    expect(res.body[1].id).toBe('pet-no-activity');
    expect(res.body[1].last_activity_at).toBeNull();
  });

  it('applies limit query param (default 12, capped)', async () => {
    const { pool, captured } = buildPetSummaryPool({ memberRole: 'foster', rows: [] });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary?limit=5`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(captured.params[1]).toBe(5);
  });

  it('caps limit at 50', async () => {
    const { pool, captured } = buildPetSummaryPool({ memberRole: 'super_admin', rows: [] });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary?limit=999`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(200);
    expect(captured.params[1]).toBe(50);
  });

  it('returns 400 for unsupported sort', async () => {
    const { pool } = buildPetSummaryPool({ memberRole: 'admin', rows: [] });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary?sort=name`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/sort/i);
  });

  it('returns 403 without view_org_pets membership', async () => {
    const { pool } = buildPetSummaryPool({ memberRole: null, rows: [] });
    const app = createApp(pool);

    const res = await request(app)
      .get(`/api/organizations/${orgId}/pets/summary`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toBe(403);
  });

  it('returns 401 without auth', async () => {
    const { pool } = buildPetSummaryPool({ rows: [] });
    const app = createApp(pool);

    const res = await request(app).get(`/api/organizations/${orgId}/pets/summary`);

    expect(res.statusCode).toBe(401);
  });
});
