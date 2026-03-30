import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function buildMockPool(overrides = {}) {
  const defaultHandler = async (sql, params) => {
    if (sql.includes('SELECT * FROM notifications WHERE user_id') && sql.includes('ORDER BY')) {
      return {
        rows: [
          {
            id: 'n-1',
            user_id: userId,
            pet_id: 'pet-1',
            pet_name: 'Buddy',
            health_entry_id: 'he-1',
            organization_id: 'org-1',
            title: 'Reminder',
            message: 'Time for checkup',
            type: 'health',
            is_read: false,
            read: false,
            created_at: new Date('2024-01-01T00:00:00Z'),
          },
          {
            id: 'n-2',
            user_id: userId,
            pet_id: null,
            pet_name: null,
            health_entry_id: null,
            organization_id: null,
            title: 'Welcome',
            message: 'Welcome to Agatha',
            type: 'general',
            is_read: true,
            read: true,
            created_at: new Date('2024-01-02T00:00:00Z'),
          },
        ],
      };
    }
    if (sql.includes('SELECT COUNT')) {
      return { rows: [{ count: '3' }] };
    }
    if (sql.includes('UPDATE notifications SET is_read')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT * FROM notification_preferences')) {
      return {
        rows: [
          { preference: 'email', value: 'true' },
          { preference: 'push', value: 'false' },
        ],
      };
    }
    if (sql.includes('SELECT id FROM notification_preferences')) {
      return { rows: [{ id: 'pref-1' }] };
    }
    if (sql.includes('UPDATE notification_preferences')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO notification_preferences')) {
      return { rows: [] };
    }
    return { rows: [] };
  };

  return {
    query: overrides.query || defaultHandler,
    end: async () => {},
  };
}

describe('Notifications API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Auth guard - 401 without token', () => {
    const endpoints = [
      ['GET', '/api/notifications'],
      ['GET', '/api/notifications/unread-count'],
      ['PUT', '/api/notifications/n-1/read'],
      ['POST', '/api/notifications/n-1/read'],
      ['PUT', '/api/notifications/read-all'],
      ['POST', '/api/notifications/read-all'],
      ['GET', '/api/notifications/preferences'],
      ['PUT', '/api/notifications/preferences'],
      ['POST', '/api/notifications/check-due'],
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
        .get('/api/notifications')
        .set('Authorization', 'Bearer invalid.token.here');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with expired token', async () => {
      const expired = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '0s' });
      await new Promise(r => setTimeout(r, 10));
      const res = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${expired}`);
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/notifications', () => {
    it('returns mapped notifications array', async () => {
      const res = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(2);
    });

    it('maps all notification fields correctly', async () => {
      const res = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${token}`);
      const n = res.body[0];
      expect(n).toHaveProperty('id', 'n-1');
      expect(n).toHaveProperty('user_id', userId);
      expect(n).toHaveProperty('pet_id', 'pet-1');
      expect(n).toHaveProperty('pet_name', 'Buddy');
      expect(n).toHaveProperty('health_entry_id', 'he-1');
      expect(n).toHaveProperty('organization_id', 'org-1');
      expect(n).toHaveProperty('title', 'Reminder');
      expect(n).toHaveProperty('message', 'Time for checkup');
      expect(n).toHaveProperty('type', 'health');
      expect(n).toHaveProperty('is_read', false);
      expect(n).toHaveProperty('created_at');
    });

    it('handles null optional fields', async () => {
      const res = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${token}`);
      const n = res.body[1];
      expect(n.pet_id).toBeNull();
      expect(n.pet_name).toBeNull();
      expect(n.health_entry_id).toBeNull();
      expect(n.organization_id).toBeNull();
      expect(n.is_read).toBe(true);
    });

    it('defaults type to general when missing', async () => {
      const pool = buildMockPool({
        query: async (sql) => {
          if (sql.includes('SELECT * FROM notifications WHERE user_id')) {
            return {
              rows: [{ id: 'n-x', user_id: userId, title: '', message: '' }],
            };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body[0].type).toBe('general');
    });

    it('works via /backend/api prefix', async () => {
      const res = await request(app)
        .get('/backend/api/notifications')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/notifications/unread-count', () => {
    it('returns unread_count key (not camelCase)', async () => {
      const res = await request(app)
        .get('/api/notifications/unread-count')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('unread_count');
      expect(typeof res.body.unread_count).toBe('number');
      expect(res.body.unread_count).toBe(3);
    });

    it('does not have unreadCount key', async () => {
      const res = await request(app)
        .get('/api/notifications/unread-count')
        .set('Authorization', `Bearer ${token}`);
      expect(res.body.unreadCount).toBeUndefined();
    });
  });

  describe('PUT /:id/read', () => {
    it('marks notification as read', async () => {
      const res = await request(app)
        .put('/api/notifications/n-1/read')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('success', true);
    });
  });

  describe('POST /:id/read', () => {
    it('marks notification as read via POST', async () => {
      const res = await request(app)
        .post('/api/notifications/n-1/read')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('success', true);
    });
  });

  describe('PUT /read-all', () => {
    it('marks all notifications as read', async () => {
      const res = await request(app)
        .put('/api/notifications/read-all')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('success', true);
    });
  });

  describe('POST /read-all', () => {
    it('marks all notifications as read via POST', async () => {
      const res = await request(app)
        .post('/api/notifications/read-all')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('success', true);
    });
  });

  describe('GET /preferences', () => {
    it('returns dict mapping preference to value', async () => {
      const res = await request(app)
        .get('/api/notifications/preferences')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ email: 'true', push: 'false' });
    });
  });

  describe('PUT /preferences', () => {
    it('updates preferences and returns body', async () => {
      const res = await request(app)
        .put('/api/notifications/preferences')
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'false', sms: 'true' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({ email: 'false', sms: 'true' });
    });

    it('inserts new preference when not existing', async () => {
      const queries = [];
      const pool = buildMockPool({
        query: async (sql, params) => {
          queries.push({ sql, params });
          if (sql.includes('SELECT id FROM notification_preferences')) {
            return { rows: [] };
          }
          if (sql.includes('INSERT INTO notification_preferences')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .put('/api/notifications/preferences')
        .set('Authorization', `Bearer ${token}`)
        .send({ new_pref: 'yes' });
      expect(res.statusCode).toBe(200);
      const insertQuery = queries.find(q => q.sql.includes('INSERT INTO notification_preferences'));
      expect(insertQuery).toBeDefined();
    });

    it('updates existing preference', async () => {
      const queries = [];
      const pool = buildMockPool({
        query: async (sql, params) => {
          queries.push({ sql, params });
          if (sql.includes('SELECT id FROM notification_preferences')) {
            return { rows: [{ id: 'existing-pref' }] };
          }
          if (sql.includes('UPDATE notification_preferences')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      });
      const a = createApp(pool);
      const res = await request(a)
        .put('/api/notifications/preferences')
        .set('Authorization', `Bearer ${token}`)
        .send({ email: 'true' });
      expect(res.statusCode).toBe(200);
      const updateQuery = queries.find(q => q.sql.includes('UPDATE notification_preferences'));
      expect(updateQuery).toBeDefined();
    });
  });

  describe('POST /check-due', () => {
    it('returns checked true', async () => {
      const res = await request(app)
        .post('/api/notifications/check-due')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('checked', true);
    });
  });

  describe('Error handling', () => {
    it('returns 500 when database throws on GET /', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB down'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
      expect(res.body).toHaveProperty('error');
    });

    it('returns 500 when database throws on GET /unread-count', async () => {
      const pool = buildMockPool({
        query: async () => { throw new Error('DB down'); },
      });
      const a = createApp(pool);
      const res = await request(a)
        .get('/api/notifications/unread-count')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(500);
    });
  });
});
