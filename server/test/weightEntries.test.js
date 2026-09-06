import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';
import { handlePetAccessQuery, handleManageEntryQuery } from './helpers/petAccessMocks.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makeWeightRow(overrides = {}) {
  return {
    id: 'we-1',
    pet_id: 'pet-1',
    pet_name: 'Fluffy',
    weight: 4.5,
    unit: 'kg',
    date: new Date('2026-03-26'),
    notes: 'Morning weigh',
    created_at: new Date('2026-03-26'),
    ...overrides,
  };
}

describe('Weight Entries API', () => {
  let app;
  let lastQuery;
  let allQueries;

  beforeAll(() => {
    allQueries = [];
    const mockPool = {
      query: async (sql, params) => {
        lastQuery = { sql, params };
        allQueries.push(lastQuery);

        const access = handlePetAccessQuery(sql, params, {
          userId,
          ownedPetIds: ['pet-1', 'pet-2', 'empty-pet'],
          deniedPetIds: ['pet-notmine'],
        });
        if (access) return access;

        const manageWeight = handleManageEntryQuery(sql, params, { tableName: 'weight_entries we' });
        if (manageWeight) return manageWeight;

        // Pet ownership check (create). 'pet-notmine' => another user's pet.
        if (sql.includes('SELECT 1 FROM pets WHERE id') && !sql.includes('LIMIT 1')) {
          if (params && params[0] === 'pet-notmine') return { rows: [] };
          return { rows: [{ exists: 1 }] };
        }

        if (sql.includes('SELECT we.*') && sql.includes('LIMIT 1')) {
          if (params && params[0] === 'empty-pet') return { rows: [] };
          return { rows: [makeWeightRow()] };
        }

        if (sql.includes('SELECT we.*') && sql.includes('FROM weight_entries')) {
          return { rows: [makeWeightRow(), makeWeightRow({ id: 'we-2', weight: 5.0 })] };
        }

        if (sql.includes('INSERT INTO weight_entries')) {
          return {
            rows: [makeWeightRow({
              id: params[0],
              pet_id: params[1],
              user_id: params[2],
              weight: params[3],
              unit: params[4],
              date: params[5],
              notes: params[6] || '',
              pet_name: null,
            })],
          };
        }

        if (sql.includes('UPDATE weight_entries')) {
          if (params[4] === 'nonexistent') return { rows: [] };
          return {
            rows: [makeWeightRow({
              id: params[4],
              pet_id: 'pet-1',
              weight: params[0],
              unit: params[1],
              date: params[2],
              notes: params[3] || '',
            })],
          };
        }

        if (sql.includes('SELECT pet_id FROM weight_entries WHERE id = $1')) {
          return { rows: [{ pet_id: 'pet-1' }] };
        }

        if (sql.includes('UPDATE pets SET weight = (')) {
          return { rows: [] };
        }

        if (sql.includes('DELETE FROM weight_entries')) {
          return { rows: [] };
        }

        if (sql.includes('INSERT INTO audit_events')) {
          return { rows: [{ id: 'audit-1' }] };
        }

        return { rows: [] };
      },
      end: async () => {},
    };
    app = createApp(mockPool);
  });

  describe('Auth guard', () => {
    it('GET /api/weight-entries returns 401 without token', async () => {
      const res = await request(app).get('/api/weight-entries');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error', 'Unauthorized');
    });

    it('GET /api/weight-entries/latest returns 401 without token', async () => {
      const res = await request(app).get('/api/weight-entries/latest?pet_id=pet-1');
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/weight-entries returns 401 without token', async () => {
      const res = await request(app).post('/api/weight-entries').send({ pet_id: 'p', weight: 1 });
      expect(res.statusCode).toBe(401);
    });

    it('PUT /api/weight-entries/:id returns 401 without token', async () => {
      const res = await request(app).put('/api/weight-entries/we-1').send({ weight: 1 });
      expect(res.statusCode).toBe(401);
    });

    it('DELETE /api/weight-entries/:id returns 401 without token', async () => {
      const res = await request(app).delete('/api/weight-entries/we-1');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/weight-entries')
        .set('Authorization', 'Bearer bad.token');
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/weight-entries (list)', () => {
    it('returns array of weight entries', async () => {
      const res = await request(app)
        .get('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(2);
    });

    it('returns entries with all mapped fields', async () => {
      const res = await request(app)
        .get('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`);
      const entry = res.body[0];
      expect(entry).toHaveProperty('id');
      expect(entry).toHaveProperty('pet_id');
      expect(entry).toHaveProperty('pet_name');
      expect(entry).toHaveProperty('weight');
      expect(entry).toHaveProperty('unit');
      expect(entry).toHaveProperty('date');
      expect(entry).toHaveProperty('notes');
      expect(entry).toHaveProperty('created_at');
    });

    it('filters by pet_id query param', async () => {
      const res = await request(app)
        .get('/api/weight-entries?pet_id=pet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(lastQuery.params).toContain('pet-1');
    });

    it('filters by petId query param alias', async () => {
      const res = await request(app)
        .get('/api/weight-entries?petId=pet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(lastQuery.params).toContain('pet-1');
    });

    it('scopes query by user_id', async () => {
      await request(app)
        .get('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`);
      expect(lastQuery.params).toContain(userId);
    });
  });

  describe('GET /api/weight-entries/latest', () => {
    it('returns latest weight entry', async () => {
      const res = await request(app)
        .get('/api/weight-entries/latest?pet_id=pet-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pet_id');
      expect(res.body).toHaveProperty('weight');
      expect(res.body).toHaveProperty('date');
      expect(res.body).toHaveProperty('pet_name');
    });

    it('returns 400 without pet_id', async () => {
      const res = await request(app)
        .get('/api/weight-entries/latest')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'pet_id is required');
    });

    it('returns 404 when no entries found', async () => {
      const res = await request(app)
        .get('/api/weight-entries/latest?pet_id=empty-pet')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'No weight entries found');
    });
  });

  describe('POST /api/weight-entries (create)', () => {
    it('creates a weight entry with all fields', async () => {
      const entry = { pet_id: 'pet-1', weight: 5.2, unit: 'lbs', date: '2026-04-01', notes: 'After meal' };
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('weight');
      expect(res.body).toHaveProperty('unit');
      expect(res.body).toHaveProperty('notes');
    });

    it('defaults unit to kg when not provided', async () => {
      const entry = { pet_id: 'pet-1', weight: 3.0 };
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insert = [...allQueries].reverse().find((q) => q.sql.includes('INSERT INTO weight_entries'));
      expect(insert.params[4]).toBe('kg');
    });

    it('normalizes ISO timestamps to date-only on create', async () => {
      await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({
          pet_id: 'pet-1',
          weight: 4.0,
          date: '2026-04-01T00:00:00.000Z',
        });
      const insert = [...allQueries].reverse().find((q) => q.sql.includes('INSERT INTO weight_entries'));
      expect(insert.params[5]).toBe('2026-04-01');
    });

    it('scopes create by authenticated user_id', async () => {
      const entry = { pet_id: 'pet-1', weight: 4.2 };
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insert = [...allQueries].reverse().find((q) => q.sql.includes('INSERT INTO weight_entries'));
      expect(insert.sql).toContain('INSERT INTO weight_entries');
      expect(insert.params[2]).toBe(userId);
    });

    it('accepts petId alias for pet_id', async () => {
      const entry = { petId: 'pet-2', weight: 3.5 };
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insert = [...allQueries].reverse().find((q) => q.sql.includes('INSERT INTO weight_entries'));
      expect(insert.params[1]).toBe('pet-2');
    });

    it('parses weight from string', async () => {
      const entry = { pet_id: 'pet-1', weight: '6.7' };
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(201);
      const insert = [...allQueries].reverse().find((q) => q.sql.includes('INSERT INTO weight_entries'));
      expect(insert.params[3]).toBe(6.7);
    });

    it('returns 403 when the pet belongs to another user', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-notmine', weight: 4.2 });
      expect(res.statusCode).toBe(403);
    });

    it('returns 400 when weight is missing', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-1' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/weight is required/i);
    });

    it('returns 400 when weight is not a number', async () => {
      const res = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-1', weight: 'not-a-number' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/weight must be a number/i);
    });

    it('returns 400 when weight is zero or negative', async () => {
      const zero = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-1', weight: 0 });
      expect(zero.statusCode).toBe(400);
      expect(zero.body.error).toMatch(/positive/i);

      const negative = await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-1', weight: -1 });
      expect(negative.statusCode).toBe(400);
      expect(negative.body.error).toMatch(/positive/i);
    });

    it('refreshes pets.weight after create', async () => {
      await request(app)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-1', weight: 4.2 });
      const cacheUpdate = allQueries.some((q) => q.sql.includes('UPDATE pets SET weight = ('));
      expect(cacheUpdate).toBe(true);
    });
  });

  describe('PUT /api/weight-entries/:id (update)', () => {
    it('updates a weight entry', async () => {
      const entry = { weight: 5.5, unit: 'lbs', date: '2026-04-02', notes: 'Updated' };
      const res = await request(app)
        .put('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`)
        .send(entry);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('weight');
    });

    it('returns 404 for nonexistent entry', async () => {
      const res = await request(app)
        .put('/api/weight-entries/nonexistent')
        .set('Authorization', `Bearer ${token}`)
        .send({ weight: 1 });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Not found');
    });

    it('scopes update by entry id', async () => {
      await request(app)
        .put('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ weight: 5 });
      const update = [...allQueries].reverse().find((q) => q.sql.includes('UPDATE weight_entries'));
      expect(update.sql).toContain('UPDATE weight_entries');
      expect(update.params[4]).toBe('we-1');
    });

    it('returns 400 when weight is invalid on update', async () => {
      const res = await request(app)
        .put('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ weight: 'bad' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/weight must be a number/i);
    });
  });

  describe('DELETE /api/weight-entries/:id', () => {
    it('deletes a weight entry and returns success', async () => {
      const res = await request(app)
        .delete('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('scopes delete by entry id', async () => {
      await request(app)
        .delete('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`);
      const del = [...allQueries].reverse().find((q) => q.sql.includes('DELETE FROM weight_entries WHERE id = $1'));
      expect(del.sql).toContain('DELETE FROM weight_entries WHERE id = $1');
      expect(del.params[0]).toBe('we-1');
    });

    it('refreshes pets.weight after delete', async () => {
      const queries = [];
      const mockPool = {
        query: async (sql, params) => {
          queries.push(sql);
          const access = handlePetAccessQuery(sql, params, {
            userId,
            ownedPetIds: ['pet-1'],
          });
          if (access) return access;
          const manageWeight = handleManageEntryQuery(sql, params, { tableName: 'weight_entries we' });
          if (manageWeight) return manageWeight;
          if (sql.includes('SELECT pet_id FROM weight_entries WHERE id = $1')) {
            return { rows: [{ pet_id: 'pet-1' }] };
          }
          if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
          if (sql.includes('DELETE FROM weight_entries')) return { rows: [] };
          return { rows: [] };
        },
        end: async () => {},
      };
      const deleteApp = createApp(mockPool);
      await request(deleteApp)
        .delete('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`);
      expect(queries.some((sql) => sql.includes('UPDATE pets SET weight = ('))).toBe(true);
    });
  });

  describe('Response shape - weightEntryToMap', () => {
    it('includes pet_name in response', async () => {
      const res = await request(app)
        .get('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0]).toHaveProperty('pet_name', 'Fluffy');
    });

    it('defaults unit to kg', async () => {
      const res = await request(app)
        .get('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0]).toHaveProperty('unit', 'kg');
    });

    it('date is serialized as date-only string', async () => {
      const res = await request(app)
        .get('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].date).toBe('2026-03-26');
      expect(res.body[0].date).not.toMatch(/T/);
    });
  });

  describe('Audit events (F-18)', () => {
    it('records audit event on create', async () => {
      const auditInserts = [];
      const mockPool = {
        query: async (sql, params) => {
          const access = handlePetAccessQuery(sql, params, {
            userId,
            ownedPetIds: ['pet-1'],
          });
          if (access) return access;
          if (sql.includes('INSERT INTO weight_entries')) {
            return {
              rows: [makeWeightRow({ id: params[0], pet_id: params[1], weight: params[3] })],
            };
          }
          if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
          if (sql.includes('INSERT INTO audit_events')) {
            auditInserts.push(params);
            return { rows: [{ id: 'audit-1' }] };
          }
          return { rows: [] };
        },
        end: async () => {},
      };
      const auditApp = createApp(mockPool);
      const res = await request(auditApp)
        .post('/api/weight-entries')
        .set('Authorization', `Bearer ${token}`)
        .send({ pet_id: 'pet-1', weight: 4.2 });
      expect(res.statusCode).toBe(201);
      expect(auditInserts.some((p) => p.includes('weight_entry.created'))).toBe(true);
    });

    it('records audit event on update', async () => {
      const auditInserts = [];
      const mockPool = {
        query: async (sql, params) => {
          if (sql.includes('SELECT pet_id FROM weight_entries WHERE id = $1')) {
            return { rows: [{ pet_id: 'pet-1' }] };
          }
          const access = handlePetAccessQuery(sql, params, {
            userId,
            ownedPetIds: ['pet-1'],
          });
          if (access) return access;
          if (sql.includes('UPDATE weight_entries')) {
            return { rows: [makeWeightRow({ id: params[4], pet_id: 'pet-1', weight: params[0] })] };
          }
          if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
          if (sql.includes('INSERT INTO audit_events')) {
            auditInserts.push(params);
            return { rows: [{ id: 'audit-1' }] };
          }
          return { rows: [] };
        },
        end: async () => {},
      };
      const auditApp = createApp(mockPool);
      const res = await request(auditApp)
        .put('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`)
        .send({ weight: 5.0 });
      expect(res.statusCode).toBe(200);
      expect(auditInserts.some((p) => p.includes('weight_entry.updated'))).toBe(true);
    });

    it('records audit event on delete', async () => {
      const auditInserts = [];
      const mockPool = {
        query: async (sql, params) => {
          if (sql.includes('SELECT pet_id FROM weight_entries WHERE id = $1')) {
            return { rows: [{ pet_id: 'pet-1' }] };
          }
          const access = handlePetAccessQuery(sql, params, {
            userId,
            ownedPetIds: ['pet-1'],
          });
          if (access) return access;
          if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
          if (sql.includes('DELETE FROM weight_entries')) return { rows: [] };
          if (sql.includes('INSERT INTO audit_events')) {
            auditInserts.push(params);
            return { rows: [{ id: 'audit-1' }] };
          }
          return { rows: [] };
        },
        end: async () => {},
      };
      const auditApp = createApp(mockPool);
      const res = await request(auditApp)
        .delete('/api/weight-entries/we-1')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(auditInserts.some((p) => p.includes('weight_entry.deleted'))).toBe(true);
    });
  });
});
