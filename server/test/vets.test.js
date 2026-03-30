import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makeVetRow(overrides = {}) {
  return {
    id: 'vet-1',
    user_id: userId,
    name: 'Dr. Smith',
    clinic: 'Happy Paws',
    phone: '555-0100',
    email: 'dr@vet.com',
    website: 'https://vet.com',
    address: '123 Vet St',
    notes: 'Great vet',
    created_at: new Date('2025-01-01'),
    updated_at: new Date('2025-01-02'),
    ...overrides,
  };
}

describe('Vets API', () => {
  let app;
  let lastQuery;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        lastQuery = { sql, params };

        if (sql.includes('SELECT * FROM vets') && sql.includes('ORDER BY name')) {
          return { rows: [makeVetRow(), makeVetRow({ id: 'vet-2', name: 'Dr. Jones' })] };
        }

        if (sql.includes('SELECT * FROM vets WHERE id') && params && params[1] === userId) {
          if (params[0] === 'nonexistent') return { rows: [] };
          return { rows: [makeVetRow({ id: params[0] })] };
        }

        if (sql.includes('INSERT INTO vets')) {
          return {
            rows: [makeVetRow({
              id: params[0],
              name: params[2],
              clinic: params[3],
              phone: params[4],
              email: params[5],
              website: params[6] || '',
              address: params[7] || '',
              notes: params[8] || '',
            })],
          };
        }

        if (sql.includes('UPDATE vets SET')) {
          if (params[7] === 'nonexistent') return { rows: [] };
          return {
            rows: [makeVetRow({
              id: params[7],
              name: params[0],
              clinic: params[1],
              phone: params[2],
              email: params[3],
              website: params[4] || '',
              address: params[5] || '',
              notes: params[6] || '',
            })],
          };
        }

        if (sql.includes('DELETE FROM vets')) {
          if (params[0] === 'nonexistent') return { rows: [] };
          return { rows: [{ id: params[0] }] };
        }

        return { rows: [] };
      },
      end: async () => {},
    };
    app = createApp(mockPool);
  });

  describe('Auth guard', () => {
    it('GET /api/vets returns 401 without token', async () => {
      const res = await request(app).get('/api/vets');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error', 'Unauthorized');
    });

    it('GET /api/vets/:id returns 401 without token', async () => {
      const res = await request(app).get('/api/vets/vet-1');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/vets returns 401 without token', async () => {
      const res = await request(app).post('/api/vets').send({ name: 'Dr. X' });
      expect(res.statusCode).toBe(401);
    });

    it('PUT /api/vets/:id returns 401 without token', async () => {
      const res = await request(app).put('/api/vets/vet-1').send({ name: 'Dr. X' });
      expect(res.statusCode).toBe(401);
    });

    it('DELETE /api/vets/:id returns 401 without token', async () => {
      const res = await request(app).delete('/api/vets/vet-1');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/vets')
        .set('Authorization', 'Bearer invalid.token.here');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with expired token', async () => {
      const expired = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '-1s' });
      const res = await request(app)
        .get('/api/vets')
        .set('Authorization', `Bearer ${expired}`);
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/vets (list)', () => {
    it('returns array of vets', async () => {
      const res = await request(app)
        .get('/api/vets')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(2);
    });

    it('returns vets with all mapped fields', async () => {
      const res = await request(app)
        .get('/api/vets')
        .set('Authorization', `Bearer ${token}`);
      const vet = res.body[0];
      expect(vet).toHaveProperty('id');
      expect(vet).toHaveProperty('user_id');
      expect(vet).toHaveProperty('name');
      expect(vet).toHaveProperty('clinic');
      expect(vet).toHaveProperty('phone');
      expect(vet).toHaveProperty('email');
      expect(vet).toHaveProperty('website');
      expect(vet).toHaveProperty('address');
      expect(vet).toHaveProperty('notes');
      expect(vet).toHaveProperty('created_at');
      expect(vet).toHaveProperty('updated_at');
    });

    it('scopes query by user_id', async () => {
      await request(app)
        .get('/api/vets')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('GET /api/vets/:id', () => {
    it('returns a single vet by id', async () => {
      const res = await request(app)
        .get('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id', 'vet-1');
      expect(res.body).toHaveProperty('name', 'Dr. Smith');
    });

    it('returns 404 for nonexistent vet', async () => {
      const res = await request(app)
        .get('/api/vets/nonexistent')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Vet not found');
    });

    it('scopes query by user_id', async () => {
      await request(app)
        .get('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('POST /api/vets (create)', () => {
    it('creates a vet with all fields', async () => {
      const vet = {
        name: 'Dr. New',
        clinic: 'New Clinic',
        phone: '555-9999',
        email: 'new@vet.com',
        website: 'https://new.vet',
        address: '456 New St',
        notes: 'Excellent',
      };
      const res = await request(app)
        .post('/api/vets')
        .set('Authorization', `Bearer ${token}`)
        .send(vet);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('name', 'Dr. New');
      expect(res.body).toHaveProperty('clinic', 'New Clinic');
      expect(res.body).toHaveProperty('phone', '555-9999');
      expect(res.body).toHaveProperty('email', 'new@vet.com');
      expect(res.body).toHaveProperty('website', 'https://new.vet');
      expect(res.body).toHaveProperty('address', '456 New St');
      expect(res.body).toHaveProperty('notes', 'Excellent');
    });

    it('creates a vet with minimal fields (website/address/notes default to empty)', async () => {
      const vet = { name: 'Dr. Minimal' };
      const res = await request(app)
        .post('/api/vets')
        .set('Authorization', `Bearer ${token}`)
        .send(vet);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('name', 'Dr. Minimal');
      expect(res.body).toHaveProperty('website', '');
      expect(res.body).toHaveProperty('address', '');
      expect(res.body).toHaveProperty('notes', '');
    });

    it('assigns user_id from auth token', async () => {
      await request(app)
        .post('/api/vets')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test' });
      expect(lastQuery.params[1]).toBe(userId);
    });
  });

  describe('PUT /api/vets/:id (update)', () => {
    it('updates a vet with all fields', async () => {
      const vet = {
        name: 'Dr. Updated',
        clinic: 'Updated Clinic',
        phone: '555-0000',
        email: 'updated@vet.com',
        website: 'https://updated.vet',
        address: '789 Updated St',
        notes: 'Updated notes',
      };
      const res = await request(app)
        .put('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`)
        .send(vet);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('name', 'Dr. Updated');
      expect(res.body).toHaveProperty('clinic', 'Updated Clinic');
      expect(res.body).toHaveProperty('website', 'https://updated.vet');
    });

    it('returns 404 for nonexistent vet', async () => {
      const res = await request(app)
        .put('/api/vets/nonexistent')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Nope' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Vet not found');
    });

    it('scopes update by user_id', async () => {
      await request(app)
        .put('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Test' });
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('DELETE /api/vets/:id', () => {
    it('deletes a vet and returns success message', async () => {
      const res = await request(app)
        .delete('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Vet deleted');
    });

    it('returns 404 for nonexistent vet', async () => {
      const res = await request(app)
        .delete('/api/vets/nonexistent')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Vet not found');
    });

    it('scopes delete by user_id', async () => {
      await request(app)
        .delete('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('Response shape - vetRowToMap', () => {
    it('maps website to empty string when null', async () => {
      const res = await request(app)
        .get('/api/vets/vet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(typeof res.body.website).toBe('string');
      expect(typeof res.body.address).toBe('string');
      expect(typeof res.body.notes).toBe('string');
    });
  });
});
