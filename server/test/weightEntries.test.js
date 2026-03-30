import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Weight Entries API', () => {
  let app;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT we.*') && sql.includes('LIMIT 1')) {
          return { rows: [{ id: 'we-1', pet_id: 'pet-1', pet_name: 'Fluffy', weight: 4.5, unit: 'kg', date: new Date('2026-03-26'), notes: '', created_at: new Date() }] };
        }
        if (sql.includes('SELECT we.*') && sql.includes('FROM weight_entries')) {
          return { rows: [{ id: 'we-1', pet_id: 'pet-1', pet_name: 'Fluffy', weight: 4.5, unit: 'kg', date: new Date('2026-03-26'), notes: '', created_at: new Date() }] };
        }
        if (sql.includes('INSERT INTO weight_entries')) {
          return { rows: [{ id: 'new-we', pet_id: params[1], weight: params[2], unit: params[3], date: params[4], notes: params[5] || '', created_at: new Date() }] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('POST /backend/api/weight-entries creates entry with all fields', async () => {
    const entry = { pet_id: 'pet-1', weight: 4.5, unit: 'kg', date: '2026-03-26', notes: 'Morning' };
    const res = await request(app)
      .post('/backend/api/weight-entries')
      .set('Authorization', `Bearer ${token}`)
      .send(entry);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('weight', 4.5);
    expect(res.body).toHaveProperty('unit', 'kg');
    expect(res.body).toHaveProperty('notes');
  });

  it('GET /backend/api/weight-entries/latest returns entry with pet_name', async () => {
    const res = await request(app)
      .get('/backend/api/weight-entries/latest?pet_id=pet-1')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('pet_id');
    expect(res.body).toHaveProperty('weight');
    expect(res.body).toHaveProperty('date');
    expect(res.body).toHaveProperty('pet_name');
  });

  it('GET /backend/api/weight-entries without auth returns 401', async () => {
    const res = await request(app).get('/backend/api/weight-entries');
    expect(res.statusCode).toBe(401);
  });
});
