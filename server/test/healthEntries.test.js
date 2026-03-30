import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Health Entries API', () => {
  let app;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT he.*') && sql.includes('FROM health_entries')) {
          return { rows: [{ id: 'he-1', pet_id: 'pet-1', user_id: userId, pet_name: 'Fluffy', name: 'Checkup', type: 'vet_visit', dosage: '', frequency: 'once', frequency_days: null, frequency_interval: 1, start_date: null, next_due_date: null, notes: '', health_issue_id: null, remind_days_before: 1, status: 'active', completed_at: null, created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('INSERT INTO health_entries')) {
          return { rows: [{ id: 'new-he', pet_id: params[1], user_id: userId, name: params[3], type: params[4], dosage: params[5], frequency: params[6], frequency_days: params[7], frequency_interval: params[8], start_date: params[9], next_due_date: params[10], notes: params[11], health_issue_id: params[12], remind_days_before: params[13], status: params[14], completed_at: null, created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('UPDATE health_entries SET status')) {
          return { rows: [{ id: params[0], pet_id: 'pet-1', user_id: userId, name: 'Checkup', type: 'vet_visit', dosage: '', frequency: 'once', frequency_days: null, frequency_interval: 1, start_date: null, next_due_date: null, notes: '', health_issue_id: null, remind_days_before: 1, status: 'completed', completed_at: new Date(), created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('INSERT INTO health_history')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('GET /backend/api/health-entries returns array with all fields', async () => {
    const res = await request(app)
      .get('/backend/api/health-entries')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('pet_name');
    expect(res.body[0]).toHaveProperty('name');
    expect(res.body[0]).toHaveProperty('dosage');
    expect(res.body[0]).toHaveProperty('frequency');
    expect(res.body[0]).toHaveProperty('status');
  });

  it('POST /backend/api/health-entries creates entry with all fields', async () => {
    const entry = { pet_id: 'pet-1', name: 'Vaccination', type: 'preventive', dosage: '1ml', frequency: 'yearly' };
    const res = await request(app)
      .post('/backend/api/health-entries')
      .set('Authorization', `Bearer ${token}`)
      .send(entry);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('name', 'Vaccination');
    expect(res.body).toHaveProperty('type', 'preventive');
    expect(res.body).toHaveProperty('dosage', '1ml');
    expect(res.body).toHaveProperty('status');
  });

  it('GET /backend/api/health-entries without auth returns 401', async () => {
    const res = await request(app).get('/backend/api/health-entries');
    expect(res.statusCode).toBe(401);
  });
});
