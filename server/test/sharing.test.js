import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const otherUserId = 'other-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const otherToken = jwt.sign({ id: otherUserId, email: 'other@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const petId = 'pet-1';
const shareCode = 'abc12345';
const linkId = 'link-1';

function buildMockPool(overrides = {}) {
  const queries = [];
  const defaultHandler = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_share_links')) {
      return { rows: [] };
    }
    if (sql.includes('FROM pet_share_links sl') && sql.includes('FOR UPDATE')) {
      return {
        rows: [{
          id: linkId,
          pet_id: petId,
          code: shareCode,
          created_by: userId,
          owner_id: userId,
          pet_name: 'Buddy',
          status: 'pending',
          claimed_by: null,
        }],
      };
    }
    if (sql.includes('FROM pet_share_links sl') && sql.includes('WHERE sl.code')) {
      return {
        rows: [{
          id: linkId,
          pet_id: petId,
          code: shareCode,
          created_by: userId,
          owner_id: userId,
          status: 'pending',
          claimed_by: null,
        }],
      };
    }
    if (sql.includes('SELECT id FROM pets WHERE id = $1 AND user_id = $2') && !sql.includes('NOT')) {
      return { rows: [{ id: petId }] };
    }
    if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (sql.includes('SELECT name, user_id FROM pets WHERE id = $1')) {
      return { rows: [{ name: 'Buddy', user_id: userId }] };
    }
    if (sql.includes('SELECT * FROM pets WHERE id = $1') && params?.[0] === petId) {
      return {
        rows: [{
          id: petId,
          user_id: userId,
          name: 'Buddy',
          species: 'dog',
          breed: 'Lab',
          bio: '',
          insurance: '',
          neuter_dismissed: false,
          chip_id: '',
          chip_dismissed: false,
          photo_path: null,
          vet_id: null,
          color_index: 0,
          passed_away: false,
          organization_id: null,
          created_at: new Date(),
          updated_at: new Date(),
        }],
      };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users WHERE id = $1')) {
      return { rows: [{ first_name: 'Alice', last_name: 'Owner', email: 'alice@example.com' }] };
    }
    if (sql.includes('SELECT role FROM pet_access') && sql.includes("role IN ('shared', 'foster')")) {
      return { rows: [{ role: 'foster' }] };
    }
    if (sql.includes('SELECT role FROM pet_access WHERE pet_id = $1 AND user_id = $2')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_access')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE pet_share_links')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM pet_share_links sl')) {
      return { rows: [{ id: linkId, status: 'pending' }] };
    }
    if (sql.includes('FROM pet_share_links sl') && sql.includes('LEFT JOIN users')) {
      return {
        rows: [{
          id: linkId,
          code: shareCode,
          status: 'pending',
          created_at: new Date(),
          claimed_at: null,
          claimed_by: null,
          claimed_by_name: null,
        }],
      };
    }
    if (sql.includes("DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2 AND role = 'shared'")) {
      return { rows: [{ id: 'pa-1' }] };
    }
    if (sql.includes("SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p") && sql.includes('hidden = true')) {
      return {
        rows: [{
          id: 'pa-2',
          pet_id: 'pet-2',
          user_id: userId,
          role: 'shared',
          hidden: true,
          pet_name: 'Max',
        }],
      };
    }
    if (sql.includes("DELETE FROM pet_access WHERE pet_id")) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE pet_access SET hidden')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT * FROM health_entries WHERE pet_id')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT id, first_name, last_name, email, photo_url, bio, category FROM users')) {
      return { rows: [{ id: userId, first_name: 'Alice', last_name: 'Owner', email: 'alice@example.com' }] };
    }
    return { rows: [] };
  };

  const query = overrides.query || (async (sql, params) => {
    queries.push({ sql, params });
    return defaultHandler(sql, params);
  });

  const connect = overrides.connect || (async () => ({
    query,
    release: () => {},
  }));

  return {
    query,
    connect,
    queries,
    end: async () => {},
  };
}

describe('Sharing API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Auth guard - 401 without token', () => {
    const endpoints = [
      ['POST', '/api/share'],
      ['POST', `/api/share/${shareCode}/accept`],
      ['DELETE', `/api/share/links/${linkId}`],
      ['POST', `/api/share/pending/${petId}/accept`],
      ['POST', `/api/share/pending/${petId}/decline`],
      ['PUT', `/api/share/${petId}/hide`],
    ];

    endpoints.forEach(([method, url]) => {
      it(`${method} ${url} returns 401 without token`, async () => {
        const res = await request(app)[method.toLowerCase()](url).send({});
        expect(res.statusCode).toBe(401);
        expect(res.body).toHaveProperty('error', 'Unauthorized');
      });
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .post('/api/share')
        .set('Authorization', 'Bearer bad.token.value')
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(401);
    });
  });

  describe('POST / (create share link)', () => {
    it('returns a share code for the pet owner', async () => {
      const res = await request(app)
        .post('/api/share')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('share_code');
      expect(res.body).toHaveProperty('link_id');
      expect(typeof res.body.share_code).toBe('string');
      expect(res.body.share_code.length).toBeGreaterThan(0);
    });

    it('returns 404 when pet is not owned by the user', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT id FROM pets WHERE id = $1 AND user_id = $2')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post('/api/share')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(404);
    });
  });

  describe('DELETE /links/:linkId', () => {
    it('deletes a share link for the owner', async () => {
      const res = await request(app)
        .delete(`/api/share/links/${linkId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Share link deleted');
    });
  });

  describe('GET /:code (resolve share link)', () => {
    it('returns pet preview data without auth', async () => {
      const res = await request(app).get(`/api/share/${shareCode}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pet');
      expect(res.body.pet).toHaveProperty('name', 'Buddy');
      expect(res.body).toHaveProperty('link_status', 'pending');
      expect(res.body).toHaveProperty('owner');
      expect(res.body).toHaveProperty('health_entries');
    });

    it('returns 404 for unknown code', async () => {
      const pool = buildMockPool({
        query: async () => ({ rows: [] }),
      });
      const a = createApp(pool);
      const res = await request(a).get('/api/share/unknown');
      expect(res.statusCode).toBe(404);
    });
  });

  describe('POST /:code/accept (claim invitation)', () => {
    it('creates shared access immediately and returns pet_id', async () => {
      const res = await request(app)
        .post(`/api/share/${shareCode}/accept`)
        .set('Authorization', `Bearer ${otherToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pet_id', petId);
      expect(res.body).toHaveProperty('status', 'shared');
    });

    it('returns 410 when link is already used by another user', async () => {
      const pool = buildMockPool({
        connect: async () => ({
          query: async (sql) => {
            if (sql.includes('FOR UPDATE')) {
              return {
                rows: [{
                  id: linkId,
                  pet_id: petId,
                  code: shareCode,
                  created_by: userId,
                  owner_id: userId,
                  pet_name: 'Buddy',
                  status: 'active',
                  claimed_by: 'someone-else',
                }],
              };
            }
            if (sql.includes('SELECT role FROM pet_access')) {
              return { rows: [] };
            }
            if (sql === 'BEGIN' || sql === 'ROLLBACK') return { rows: [] };
            return { rows: [] };
          },
          release: () => {},
        }),
      });
      const a = createApp(pool);
      const res = await request(a)
        .post(`/api/share/${shareCode}/accept`)
        .set('Authorization', `Bearer ${otherToken}`);
      expect(res.statusCode).toBe(410);
    });
  });

  describe('GET /pending', () => {
    it('returns empty array (deprecated flow)', async () => {
      const res = await request(app)
        .get('/api/share/pending')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual([]);
    });

    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/share/pending');
      expect(res.statusCode).toBe(401);
    });
  });

  describe('POST /pending/:petId/accept', () => {
    it('returns 410 (deprecated)', async () => {
      const res = await request(app)
        .post(`/api/share/pending/${petId}/accept`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(410);
    });
  });

  describe('POST /pending/:petId/decline', () => {
    it('returns 410 (deprecated)', async () => {
      const res = await request(app)
        .post(`/api/share/pending/${petId}/decline`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(410);
    });
  });

  describe('PUT /:petId/hide', () => {
    it('hides a fostered pet for the fosterer', async () => {
      const res = await request(app)
        .put(`/api/share/${petId}/hide`)
        .set('Authorization', `Bearer ${token}`)
        .send({ hidden: true });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Pet hidden');
    });

    it('unhides a fostered pet', async () => {
      const res = await request(app)
        .put(`/api/share/${petId}/hide`)
        .set('Authorization', `Bearer ${token}`)
        .send({ hidden: false });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Pet unhidden');
    });

    it('hides a shared pet for the collaborator', async () => {
      const pool = buildMockPool({
        query: async (sql, params) => {
          if (sql.includes("role IN ('shared', 'foster')")) {
            return { rows: [{ role: 'shared' }] };
          }
          if (sql.includes('UPDATE pet_access SET hidden')) {
            expect(params[3]).toBe('shared');
            return { rows: [] };
          }
          return buildMockPool().query(sql, params);
        },
      });
      const appWithShared = createApp(pool);
      const res = await request(appWithShared)
        .put(`/api/share/${petId}/hide`)
        .set('Authorization', `Bearer ${token}`)
        .send({ hidden: true });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Pet hidden');
    });
  });

  describe('GET /hidden', () => {
    it('returns hidden shared pets array', async () => {
      const res = await request(app)
        .get('/api/share/hidden')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('pet_name', 'Max');
      expect(res.body[0]).toHaveProperty('hidden', true);
    });

    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/share/hidden');
      expect(res.statusCode).toBe(401);
    });
  });

  describe('Backend prefix', () => {
    it('POST /backend/api/share is reachable under the /backend prefix', async () => {
      const res = await request(app)
        .post('/backend/api/share')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('share_code');
    });
  });
});

describe('Foster share links', () => {
  const fosterUserId = 'foster-user-id';
  const fosterToken = jwt.sign({ id: fosterUserId, email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });

  function buildFosterPool(overrides = {}) {
    const base = buildMockPool();
    const innerQuery = overrides.query || base.query;
    return {
      ...base,
      query: async (sql, params) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
          return { rows: [] };
        }
        if (sql.includes('foster_placements fp')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('DELETE FROM pet_share_links sl') && sql.includes('sl.created_by = $2')) {
          return { rows: [{ id: linkId, status: 'pending' }] };
        }
        if (sql.includes('FROM pet_share_links sl') && sql.includes('LEFT JOIN users') && sql.includes('created_by = $2')) {
          return {
            rows: [{
              id: linkId,
              code: shareCode,
              status: 'pending',
              created_at: new Date(),
              claimed_at: null,
              claimed_by: null,
              claimed_by_name: null,
            }],
          };
        }
        return innerQuery(sql, params);
      },
    };
  }

  it('POST / lets active foster create a share link', async () => {
    const app = createApp(buildFosterPool());
    const res = await request(app)
      .post('/api/share')
      .set('Authorization', `Bearer ${fosterToken}`)
      .send({ pet_id: petId });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('share_code');
  });

  it('DELETE /links/:linkId lets foster delete their own link', async () => {
    const app = createApp(buildFosterPool());
    const res = await request(app)
      .delete(`/api/share/links/${linkId}`)
      .set('Authorization', `Bearer ${fosterToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message', 'Share link deleted');
  });

  it('GET /api/pets/:id/share-links returns foster-created links only', async () => {
    const app = createApp(buildFosterPool());
    const res = await request(app)
      .get(`/api/pets/${petId}/share-links`)
      .set('Authorization', `Bearer ${fosterToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('code', shareCode);
  });
});

describe('Pet share links and follow', () => {
  it('GET /api/pets/:id/share-links returns links for owner', async () => {
    const app = createApp(buildMockPool());
    const res = await request(app)
      .get(`/api/pets/${petId}/share-links`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('code', shareCode);
    expect(res.body[0]).toHaveProperty('status', 'pending');
  });

  it('DELETE /api/pets/:id/follow lets shared user stop following', async () => {
    const app = createApp(buildMockPool());
    const res = await request(app)
      .delete(`/api/pets/${petId}/follow`)
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message', 'Stopped following pet');
  });
});
