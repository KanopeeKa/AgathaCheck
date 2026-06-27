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

function buildMockPool(overrides = {}) {
  const queries = [];
  const defaultHandler = async (sql, params) => {
    if (sql.includes('INSERT INTO pet_share_links')) {
      return { rows: [] };
    }
    if (sql.includes('FROM pet_share_links sl') && sql.includes('WHERE sl.code')) {
      return {
        rows: [{
          id: 'link-1',
          pet_id: petId,
          code: shareCode,
          created_by: userId,
          owner_id: userId,
        }],
      };
    }
    if (sql.includes('SELECT id FROM pets WHERE id = $1 AND user_id = $2') && !sql.includes('NOT')) {
      return { rows: [{ id: petId }] };
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
    if (sql.includes('SELECT role FROM pet_access WHERE pet_id = $1 AND user_id = $2')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_access')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    if (sql.includes("SELECT pa.*, p.name as pet_name, p.species as pet_species") && sql.includes("pending_shared")) {
      return {
        rows: [{
          id: 'pa-1',
          pet_id: petId,
          user_id: userId,
          role: 'pending_shared',
          hidden: false,
          pet_name: 'Buddy',
          pet_species: 'dog',
          pet_breed: 'Lab',
          guardian_name: 'Alice Owner',
        }],
      };
    }
    if (sql.includes('SELECT pa.*, p.name as pet_name, p.user_id as owner_id') && sql.includes("pending_shared")) {
      return {
        rows: [{
          id: 'pa-1',
          pet_id: petId,
          user_id: userId,
          role: 'pending_shared',
          pet_name: 'Buddy',
          owner_id: userId,
        }],
      };
    }
    if (sql.includes("SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p") && sql.includes("pending_shared")) {
      return {
        rows: [{
          id: 'pa-1',
          pet_id: petId,
          user_id: userId,
          role: 'pending_shared',
          hidden: false,
          pet_name: 'Buddy',
          pet_species: 'dog',
          pet_breed: 'Lab',
          guardian_name: 'Alice Owner',
        }],
      };
    }
    if (sql.includes('SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p') && sql.includes('hidden = true')) {
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
    if (sql.includes("UPDATE pet_access SET role = 'shared'")) {
      return { rows: [] };
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

  return {
    query,
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

  describe('GET /:code (resolve share link)', () => {
    it('returns pet preview data without auth', async () => {
      const res = await request(app).get(`/api/share/${shareCode}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pet');
      expect(res.body.pet).toHaveProperty('name', 'Buddy');
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
    it('creates a pending share and returns pet_id', async () => {
      const res = await request(app)
        .post(`/api/share/${shareCode}/accept`)
        .set('Authorization', `Bearer ${otherToken}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pet_id', petId);
      expect(res.body).toHaveProperty('status', 'pending');
    });
  });

  describe('GET /pending', () => {
    it('returns pending shared pets array', async () => {
      const res = await request(app)
        .get('/api/share/pending')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('pet_name', 'Buddy');
      expect(res.body[0]).toHaveProperty('role', 'pending_shared');
    });

    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/share/pending');
      expect(res.statusCode).toBe(401);
    });
  });

  describe('POST /pending/:petId/accept', () => {
    it('accepts a pending share', async () => {
      const res = await request(app)
        .post(`/api/share/pending/${petId}/accept`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Share accepted');
    });

    it('accepts with optional organization_id', async () => {
      const res = await request(app)
        .post(`/api/share/pending/${petId}/accept`)
        .set('Authorization', `Bearer ${token}`)
        .send({ organization_id: 'org-1' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Share accepted');
    });
  });

  describe('POST /pending/:petId/decline', () => {
    it('declines a pending share', async () => {
      const res = await request(app)
        .post(`/api/share/pending/${petId}/decline`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Share declined');
    });
  });

  describe('PUT /:petId/hide', () => {
    it('hides a shared pet', async () => {
      const res = await request(app)
        .put(`/api/share/${petId}/hide`)
        .set('Authorization', `Bearer ${token}`)
        .send({ hidden: true });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Pet hidden');
    });

    it('unhides a shared pet', async () => {
      const res = await request(app)
        .put(`/api/share/${petId}/hide`)
        .set('Authorization', `Bearer ${token}`)
        .send({ hidden: false });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Pet unhidden');
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

  describe('Error handling', () => {
    it('returns 500 when database throws on POST /pending/:petId/accept', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB error'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post(`/api/share/pending/${petId}/accept`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(500);
    });

    it('returns 500 when database throws on POST /pending/:petId/decline', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB error'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post(`/api/share/pending/${petId}/decline`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
    });

    it('returns 500 when database throws on PUT /:petId/hide', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB error'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .put(`/api/share/${petId}/hide`)
        .set('Authorization', `Bearer ${token}`)
        .send({ hidden: true });
      expect(res.statusCode).toBe(500);
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
