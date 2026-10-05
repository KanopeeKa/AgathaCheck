import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { handleManageEntryQuery, handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { KG_PER_LB } from '../../lib/care/observations/weightUnits.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makePool(handlers = {}) {
  return {
    query: async (sql, params) => {
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { command: sql, rows: [] };
      }
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: ['pet-1'],
      });
      if (access) return access;
      if (handlers.query) return handlers.query(sql, params);
      if (sql.includes('SELECT home_timezone FROM pets')) {
        return { rows: [{ home_timezone: 'UTC' }] };
      }
      if (sql.includes('INSERT INTO weight_entries')) {
        return {
          rows: [{
            id: params[0],
            pet_id: params[1],
            user_id: params[2],
            weight: params[3],
            unit: 'kg',
            date: params[4],
            notes: params[5] || '',
            measurement_source: params[6] || 'guardian',
            health_occurrence_id: null,
            created_at: new Date(),
          }],
        };
      }
      if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
      if (sql.includes('INSERT INTO audit_events')) return { rows: [{ id: 'audit-1' }] };
      return { rows: [] };
    },
    connect: async () => ({
      query: async (sql, params) => makePool(handlers).query(sql, params),
      release: () => {},
    }),
    end: async () => {},
  };
}

describe('Weight entries units and dates (W1)', () => {
  it('U-1 POST { weight: 10, unit: lb } stores and returns kg', async () => {
    const app = createApp(makePool());
    const res = await request(app)
      .post('/api/weight-entries')
      .set('Authorization', `Bearer ${token}`)
      .send({ pet_id: 'pet-1', weight: 10, unit: 'lb' });
    expect(res.statusCode).toBe(201);
    expect(res.body.unit).toBe('kg');
    expect(res.body.weight).toBeCloseTo(10 * KG_PER_LB, 6);
  });

  it('U-2 POST unit st returns 400 and does not insert', async () => {
    let inserted = false;
    const app = createApp(makePool({
      query: (sql) => {
        if (sql.includes('INSERT INTO weight_entries')) inserted = true;
        return { rows: [] };
      },
    }));
    const res = await request(app)
      .post('/api/weight-entries')
      .set('Authorization', `Bearer ${token}`)
      .send({ pet_id: 'pet-1', weight: 10, unit: 'st' });
    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('unit must be kg or lb');
    expect(inserted).toBe(false);
  });

  it('U-3 POST date tomorrow returns date_in_future', async () => {
    const app = createApp(makePool({
      query: (sql) => {
        if (sql.includes('SELECT home_timezone FROM pets')) {
          return { rows: [{ home_timezone: 'UTC' }] };
        }
        return { rows: [] };
      },
    }));
    const tomorrow = new Date();
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    const date = tomorrow.toISOString().slice(0, 10);
    const res = await request(app)
      .post('/api/weight-entries')
      .set('Authorization', `Bearer ${token}`)
      .send({ pet_id: 'pet-1', weight: 4, date });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('date_in_future');
  });

  it('U-4 PUT with unit lb stores kg', async () => {
    const app = createApp(makePool({
      query: (sql, params) => {
        const manageWeight = handleManageEntryQuery(sql, params, { tableName: 'weight_entries we' });
        if (manageWeight) return manageWeight;
        if (sql.includes('SELECT * FROM weight_entries WHERE id = $1')) {
          return { rows: [{ id: 'we-1', pet_id: 'pet-1', weight: 5, unit: 'kg', date: '2026-01-01' }] };
        }
        if (sql.includes('UPDATE weight_entries')) {
          return {
            rows: [{
              id: 'we-1',
              pet_id: 'pet-1',
              weight: params[0],
              unit: 'kg',
              date: params[1],
              notes: '',
              measurement_source: 'guardian',
              created_at: new Date(),
            }],
          };
        }
        if (sql.includes('SELECT home_timezone FROM pets')) {
          return { rows: [{ home_timezone: 'UTC' }] };
        }
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('INSERT INTO audit_events')) return { rows: [{ id: 'audit-1' }] };
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: ['pet-1'] });
        if (access) return access;
        return { rows: [] };
      },
    }));
    const res = await request(app)
      .put('/api/weight-entries/we-1')
      .set('Authorization', `Bearer ${token}`)
      .send({ weight: 10, unit: 'lb', date: '2026-01-01' });
    expect(res.statusCode).toBe(200);
    expect(res.body.unit).toBe('kg');
    expect(res.body.weight).toBeCloseTo(10 * KG_PER_LB, 6);
  });
});
