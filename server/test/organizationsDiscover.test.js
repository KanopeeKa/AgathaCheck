import request from 'supertest';
import { createApp } from '../bin/server.js';
import { discoverRowToMap } from '../routes/organizations/discoverRouter.js';

const discoverableOrg = {
  id: 'org-discover-1',
  name: 'Rescue Hearts',
  type: 'charity',
  logo_url: '/uploads/org_photos/logo.jpg',
  photo_url: '/uploads/org_photos/hero.jpg',
  town: 'Springfield',
  administrative_area: 'IL',
  description: 'A caring rescue shelter',
  public_profile_metadata: {},
};

const secondDiscoverableOrg = {
  id: 'org-discover-2',
  name: 'Happy Tails Rescue',
  type: 'charity',
  logo_url: '',
  photo_url: '',
  town: 'Shelbyville',
  administrative_area: 'IL',
  description: 'Another rescue',
  public_profile_metadata: {},
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
      'display_locality',
      'id',
      'logo_url',
      'name',
      'photo_url',
      'town',
      'type',
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

  it('computes display_locality from postcode, town, or administrative_area', async () => {
    const withPostcode = {
      ...discoverableOrg,
      id: 'org-postcode',
      public_profile_metadata: { postcode: '62701' },
    };
    const townOnly = {
      ...discoverableOrg,
      id: 'org-town',
      town: 'Paris',
      administrative_area: 'IDF',
      public_profile_metadata: {},
    };
    const areaOnly = {
      ...discoverableOrg,
      id: 'org-area',
      town: '',
      administrative_area: 'TX',
      public_profile_metadata: {},
    };
    const app = createApp(buildDiscoverPool([withPostcode, townOnly, areaOnly], 3));
    const res = await request(app).get('/api/organizations/discover');
    expect(res.statusCode).toBe(200);
    const byId = Object.fromEntries(res.body.items.map((o) => [o.id, o]));
    expect(byId['org-postcode'].display_locality).toBe('62701');
    expect(byId['org-town'].display_locality).toBe('Paris');
    expect(byId['org-area'].display_locality).toBe('TX');
  });

  it('includes photo_url for hero imagery', async () => {
    const app = createApp(buildDiscoverPool());
    const res = await request(app).get('/api/organizations/discover');
    expect(res.body.items[0].photo_url).toBe('/uploads/org_photos/hero.jpg');
  });

  it('does not include opted-out organisations in results', async () => {
    const app = createApp(buildDiscoverPool([discoverableOrg], 1));
    const res = await request(app).get('/api/organizations/discover');
    expect(res.body.items.some((o) => o.name === hiddenOrg.name)).toBe(false);
    expect(res.body.items.some((o) => o.name === discoverableOrg.name)).toBe(true);
  });

  describe('name search (?q=)', () => {
    it.each([
      {
        q: 'rescue',
        expectedNames: ['Rescue Hearts', 'Happy Tails Rescue'],
      },
      {
        q: 'Hearts',
        expectedNames: ['Rescue Hearts'],
      },
      {
        q: '  hearts  ',
        expectedNames: ['Rescue Hearts'],
      },
      {
        q: 'nomatch',
        expectedNames: [],
      },
    ])('filters discoverable organisations by name ILIKE for q=$q', async ({ q, expectedNames }) => {
      const pool = {
        query: async (sql, params) => {
          if (sql.includes('COUNT(*)::int AS total_count')) {
            const filtered = [discoverableOrg, secondDiscoverableOrg].filter((org) =>
              org.name.toLowerCase().includes(q.trim().toLowerCase()),
            );
            return { rows: [{ total_count: filtered.length }] };
          }
          if (sql.includes('name ILIKE $1')) {
            expect(params[0]).toBe(`%${q.trim()}%`);
            const filtered = [discoverableOrg, secondDiscoverableOrg].filter((org) =>
              org.name.toLowerCase().includes(q.trim().toLowerCase()),
            );
            return { rows: filtered };
          }
          return { rows: [] };
        },
      };
      const app = createApp(pool);
      const res = await request(app).get(`/api/organizations/discover?q=${encodeURIComponent(q)}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.items.map((item) => item.name)).toEqual(expectedNames);
      expect(res.body.total_count).toBe(expectedNames.length);
    });

    it('preserves pagination when q is non-empty', async () => {
      let limit;
      let offset;
      const pool = {
        query: async (sql, params) => {
          if (sql.includes('COUNT(*)::int AS total_count')) {
            return { rows: [{ total_count: 42 }] };
          }
          if (sql.includes('LIMIT $2 OFFSET $3')) {
            expect(params[0]).toBe('%rescue%');
            limit = params[1];
            offset = params[2];
            return { rows: [discoverableOrg] };
          }
          return { rows: [] };
        },
      };
      const app = createApp(pool);
      const res = await request(app).get(
        '/api/organizations/discover?q=rescue&page=3&page_size=10',
      );
      expect(res.statusCode).toBe(200);
      expect(limit).toBe(10);
      expect(offset).toBe(20);
      expect(res.body.page).toBe(3);
      expect(res.body.page_size).toBe(10);
      expect(res.body.total_count).toBe(42);
    });

    it('does not apply ILIKE filter when q is empty or whitespace', async () => {
      let usedIlike = false;
      const pool = {
        query: async (sql) => {
          if (sql.includes('name ILIKE')) usedIlike = true;
          if (sql.includes('COUNT(*)::int AS total_count')) {
            return { rows: [{ total_count: 2 }] };
          }
          if (sql.includes('LIMIT $1 OFFSET $2')) {
            return { rows: [discoverableOrg, secondDiscoverableOrg] };
          }
          return { rows: [] };
        },
      };
      const app = createApp(pool);
      const res = await request(app).get('/api/organizations/discover?q=   ');
      expect(res.statusCode).toBe(200);
      expect(usedIlike).toBe(false);
      expect(res.body.items.length).toBe(2);
    });
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
