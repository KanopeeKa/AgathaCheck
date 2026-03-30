import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Notifications API', () => {
  let app;

  beforeAll(() => {
    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT * FROM notifications WHERE user_id') && sql.includes('ORDER BY')) {
          return { rows: [{ id: 'n-1', user_id: userId, pet_id: null, pet_name: null, health_entry_id: null, organization_id: null, title: 'Test', message: 'Hello', type: 'general', is_read: false, read: false, created_at: new Date() }] };
        }
        if (sql.includes('SELECT COUNT')) {
          return { rows: [{ count: '1' }] };
        }
        if (sql.includes('SELECT * FROM notification_preferences')) {
          return { rows: [{ preference: 'email', value: 'true' }] };
        }
        if (sql.includes('UPDATE notifications')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('GET /backend/api/notifications returns mapped notifications', async () => {
    const res = await request(app)
      .get('/backend/api/notifications')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('title');
    expect(res.body[0]).toHaveProperty('message');
    expect(res.body[0]).toHaveProperty('type');
    expect(res.body[0]).toHaveProperty('is_read');
  });

  it('GET /backend/api/notifications/unread-count returns unread_count', async () => {
    const res = await request(app)
      .get('/backend/api/notifications/unread-count')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('unread_count');
  });

  it('GET /backend/api/notifications/preferences returns mapped prefs', async () => {
    const res = await request(app)
      .get('/backend/api/notifications/preferences')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('email');
  });

  it('POST /backend/api/notifications/check-due returns checked true', async () => {
    const res = await request(app)
      .post('/backend/api/notifications/check-due')
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('checked', true);
  });
});
