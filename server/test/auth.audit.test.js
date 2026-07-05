import request from 'supertest';
import { createApp } from '../bin/server.js';

describe('Auth audit events', () => {
  it('records audit event on successful login', async () => {
    const auditInserts = [];
    const userId = 'audit-user-1';
    const userRow = {
      id: userId,
      email: 'audit@example.com',
      password_hash: '$2b$10$validhashfortestpassword',
      first_name: 'Audit',
      last_name: 'User',
      category: 'pet_guardian',
      bio: '',
      photo_url: '',
      locale: 'en',
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    };

    const mockPool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT * FROM users WHERE email')) {
          return { rows: [userRow] };
        }
        if (sql.includes('INSERT INTO audit_events')) {
          auditInserts.push(params);
          return { rows: [{ id: 'audit-login-1' }] };
        }
        return { rows: [] };
      },
      end: async () => {},
    };

    const mockComparePassword = (input, hash) =>
      input === 'testpassword' && hash === userRow.password_hash;

    const app = createApp(mockPool, mockComparePassword);
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'audit@example.com', password: 'testpassword' });

    expect(res.statusCode).toBe(200);
    expect(auditInserts.length).toBeGreaterThanOrEqual(1);
    expect(auditInserts.some((params) => params.includes('auth.login'))).toBe(true);
  });
});
