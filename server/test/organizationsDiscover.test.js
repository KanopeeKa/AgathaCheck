import request from 'supertest';
import { createApp } from '../bin/server.js';
import { discoverRowToMap } from '../routes/organizations/discoverRouter.js';

const discoverableOrg = {
  id: 'org-discover-1',
  name: 'Rescue Hearts',
  logo_url: '/uploads/org_photos/logo.jpg',
  town: 'Springfield',
  administrative_area: 'IL',
  description: 'A caring rescue shelter',
};

const hiddenOrg = {
  id: 'org-hidden-1',
  name: 'Quiet Shelter',
  logo_url: '',
  town: 'Hidden',
  administrative_area: 'XX',
  description: 'Opted out',
};

function buildDiscoverPool(rows = [discoverableOrg], totalCount = rows.length) {
  return {
    query: async (sql) => {
      if (sql.includes('COUNT(*)::int AS total_count')) {
        return { rows: [{ total_count: totalCount }] };
      }
      if (sql.includes('WHERE is_discoverable = true')) {
        return { rows };
      }
      return { rows: [] };
    },
  };
}

describe('GET /organizations/discover', () => {
  it('returns paginated discoverable organisations without auth', async () => {
    const app = createApp(buildDiscoverPool());
    const res = await request(app).get('/api/organizations/discover');
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual({
      items: [discoverRowToMap(discoverableOrg)],
      page: 1,
      page_size: 20,
      total_count: 1,
    });
  });

  it('exposes only public discovery fields', async () => {
    const app = createApp(buildDiscoverPool());
    const res = await request(app).get('/api/organizations/discover');
    const org = res.body.items[0];
    expect(Object.keys(org).sort()).toEqual([
      'administrative_area',
      'description',
      'id',
      'logo_url',
      'name',
      'town',
    ]);
    expect(org).not.toHaveProperty('email');
    expect(org).not.toHaveProperty('phone');
    expect(org).not.toHaveProperty('legal_identifier_1');
  });

  it('respects page and page_size query params', async () => {
    let limit;
    let offset;
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('COUNT(*)::int AS total_count')) {
          return { rows: [{ total_count: 42 }] };
        }
        if (sql.includes('LIMIT $1 OFFSET $2')) {
          limit = params[0];
          offset = params[1];
          return { rows: [discoverableOrg] };
        }
        return { rows: [] };
      },
    };
    const app = createApp(pool);
    const res = await request(app).get('/api/organizations/discover?page=3&page_size=10');
    expect(res.statusCode).toBe(200);
    expect(limit).toBe(10);
    expect(offset).toBe(20);
    expect(res.body.page).toBe(3);
    expect(res.body.page_size).toBe(10);
    expect(res.body.total_count).toBe(42);
  });

  it('caps page_size at 50', async () => {
    let limit;
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('COUNT(*)::int AS total_count')) {
          return { rows: [{ total_count: 0 }] };
        }
        if (sql.includes('LIMIT $1 OFFSET $2')) {
          limit = params[0];
          return { rows: [] };
        }
        return { rows: [] };
      },
    };
    const app = createApp(pool);
    await request(app).get('/api/organizations/discover?page_size=100');
    expect(limit).toBe(50);
  });

  it('does not include opted-out organisations in results', async () => {
    const app = createApp(buildDiscoverPool([discoverableOrg], 1));
    const res = await request(app).get('/api/organizations/discover');
    expect(res.body.items.some((o) => o.name === hiddenOrg.name)).toBe(false);
    expect(res.body.items.some((o) => o.name === discoverableOrg.name)).toBe(true);
  });

  it('returns 500 with redacted error on database failure', async () => {
    const prev = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const pool = {
        query: async () => {
          throw new Error('secret db failure');
        },
      };
      const app = createApp(pool);
      const res = await request(app).get('/api/organizations/discover');
      expect(res.statusCode).toBe(500);
      expect(res.body.error).not.toContain('secret db failure');
      expect(res.body.error).toBe('Internal server error');
    } finally {
      process.env.NODE_ENV = prev;
    }
  });
});
