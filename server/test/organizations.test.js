import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT o.*') && sql.includes('ORDER BY o.name')) {
          return { rows: [{ id: 'org-1', name: 'Test Org', type: 'professional', email: null, phone: null, address: null, website: null, bio: '', photo_url: '', role: 'super_user', member_count: '1', pet_count: '0', created_at: new Date(), updated_at: new Date() }] };
        }
        if (sql.includes('INSERT INTO organizations')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO organization_users')) {
          return { rows: [] };
        }
        if (sql.includes('SELECT o.*') && sql.includes('WHERE o.id')) {
          return { rows: [{ id: 'org-1', name: 'Test Org', type: 'professional', email: null, phone: null, address: null, website: null, bio: '', photo_url: '', role: 'super_user', member_count: '1', pet_count: '0', created_at: new Date(), updated_at: new Date() }] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('GET /api/organizations returns array with org fields', async () => {
    const res = await request(app)
      .get('/api/organizations')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('type');
    expect(res.body[0]).toHaveProperty('role');
    expect(res.body[0]).toHaveProperty('member_count');
  });

  it('POST /api/organizations creates organization', async () => {
    const org = { name: 'New Org', type: 'charity' };
    const res = await request(app)
      .post('/api/organizations')
      .set('Authorization', `Bearer ${token}`)
      .send(org);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('name');
    expect(res.body).toHaveProperty('type');
    expect(res.body).toHaveProperty('role', 'super_user');
  });

  it('GET /api/organizations without auth returns 401', async () => {
    const res = await request(app).get('/api/organizations');
    expect(res.statusCode).toBe(401);
  });
});
