import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const petId = 'pet-1';
const shareCode = 'abc12345';

function buildMockPool(overrides = {}) {
  const defaultHandler = async (sql, params) => {
    if (sql.includes("SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p") && sql.includes("pending_shared")) {
      return {
        rows: [{
          id: 'pa-1',
          pet_id: petId,
          user_id: userId,
          role: 'pending_shared',
          hidden: false,
          pet_name: 'Buddy',
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
    return { rows: [] };
  };

  return {
    query: overrides.query || defaultHandler,
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

  describe('POST / (generate share code)', () => {
    it('generates a share code for a pet', async () => {
      const res = await request(app)
        .post('/api/share')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('code');
      expect(typeof res.body.code).toBe('string');
      expect(res.body.code.length).toBe(8);
      expect(res.body).toHaveProperty('pet_id', petId);
    });
  });

  describe('GET /:code (code info)', () => {
    it('returns code info', async () => {
      const res = await request(app)
        .get(`/api/share/${shareCode}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('code', shareCode);
      expect(res.body).toHaveProperty('pet');
    });
  });

  describe('POST /:code/accept', () => {
    it('accepts a share by code', async () => {
      const res = await request(app)
        .post(`/api/share/${shareCode}/accept`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Share accepted');
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
    it('POST / still succeeds even with DB error (no DB call)', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB error'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .post('/api/share')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('code');
    });

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
    it('POST /backend/api/share generates share code', async () => {
      const res = await request(app)
        .post('/backend/api/share')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: petId });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('code');
    });
  });
});
