import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Health Issues API', () => {
  let app;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT hi.*') && sql.includes('FROM health_issues')) {
          return { rows: [{ id: 'hi-1', pet_id: 'pet-1', user_id: userId, pet_name: 'Fluffy', name: 'Allergy', issue_type: 'allergy', notes: 'Seasonal', start_date: null, end_date: null, status: 'active', created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('INSERT INTO health_issues')) {
          return { rows: [{ id: 'new-hi', pet_id: params[1], user_id: userId, name: params[3], issue_type: params[4], notes: params[5], start_date: params[6], end_date: params[7], status: params[8], created_at: new Date(), updated_at: new Date() }] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('GET /backend/api/health-issues returns array with all fields', async () => {
    const res = await request(app)
      .get('/backend/api/health-issues')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('pet_name');
    expect(res.body[0]).toHaveProperty('title');
    expect(res.body[0]).toHaveProperty('name');
    expect(res.body[0]).toHaveProperty('issue_type');
    expect(res.body[0]).toHaveProperty('status');
  });

  it('POST /backend/api/health-issues creates issue with all fields', async () => {
    const issue = { pet_id: 'pet-1', title: 'Limping', issue_type: 'injury', notes: 'Left leg' };
    const res = await request(app)
      .post('/backend/api/health-issues')
      .set('Authorization', `Bearer ${token}`)
      .send(issue);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('name', 'Limping');
    expect(res.body).toHaveProperty('title', 'Limping');
    expect(res.body).toHaveProperty('issue_type', 'injury');
  });

  it('GET /backend/api/health-issues without auth returns 401', async () => {
    const res = await request(app).get('/backend/api/health-issues');
    expect(res.statusCode).toBe(401);
  });
});
