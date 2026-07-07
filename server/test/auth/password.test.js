import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  userId,
  userEmail,
  buildMockPool,
  makeToken,
  mockComparePassword,
} from './helpers.js';

describe('Auth Routes — Password', () => {
  let app;
  let mockPool;

  beforeEach(() => {
    mockPool = buildMockPool();
    app = createApp(mockPool, mockComparePassword);
  });

  describe('POST /api/auth/change-password', () => {
    it('should change password successfully', async () => {
      const token = makeToken();
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send({ currentPassword: 'testpassword', newPassword: 'NewPassword456' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Password changed successfully');
    });

    it('should return 400 when current password is incorrect', async () => {
      const token = makeToken();
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send({ currentPassword: 'wrongpassword', newPassword: 'NewPassword456' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Current password is incorrect');
    });

    it('should return 400 when currentPassword is missing', async () => {
      const token = makeToken();
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send({ newPassword: 'NewPassword456' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 when newPassword is missing', async () => {
      const token = makeToken();
      const res = await request(app)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send({ currentPassword: 'testpassword' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .post('/api/auth/change-password')
        .send({ currentPassword: 'testpassword', newPassword: 'NewPassword456' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        selectPasswordHash: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .post('/api/auth/change-password')
        .set('Authorization', `Bearer ${token}`)
        .send({ currentPassword: 'testpassword', newPassword: 'NewPassword456' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/forgot-password', () => {
    it('should return success message for existing email', async () => {
      const pool = buildMockPool({
        selectUserByEmail: async (sql, params) => {
          if (sql.includes('SELECT id')) return { rows: [{ id: userId, locale: 'en' }] };
          return { rows: [{ id: userId, email: userEmail, password_hash: '$2b$10$validhashfortestpassword', first_name: 'Test', last_name: 'User', category: 'pet_guardian', bio: 'A test bio', photo_url: 'http://example.com/photo.png', locale: 'en', created_at: '2024-01-01T00:00:00Z', updated_at: '2024-01-01T00:00:00Z' }] };
        },
      });
      const forgotApp = createApp(pool, mockComparePassword);
      const res = await request(forgotApp)
        .post('/api/auth/forgot-password')
        .send({ email: userEmail });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
      // Outside production the code is exposed for local/test convenience.
      expect(res.body).toHaveProperty('code');
    });

    it('does not return the reset code in production', async () => {
      const prev = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';
      try {
        const pool = buildMockPool({
          selectUserByEmail: async () => ({ rows: [{ id: userId, locale: 'en' }] }),
        });
        const prodApp = createApp(pool, mockComparePassword);
        const res = await request(prodApp)
          .post('/api/auth/forgot-password')
          .send({ email: userEmail });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('message');
        expect(res.body).not.toHaveProperty('code');
      } finally {
        process.env.NODE_ENV = prev;
      }
    });

    it('should return success message for non-existent email (no info leak)', async () => {
      const pool = buildMockPool({
        selectUserByEmail: async () => ({ rows: [] }),
      });
      const forgotApp = createApp(pool, mockComparePassword);
      const res = await request(forgotApp)
        .post('/api/auth/forgot-password')
        .send({ email: 'nobody@example.com' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
    });

    it('exposes the reset code in development without configured SMTP', async () => {
      const prevEnv = process.env.NODE_ENV;
      const prevHost = process.env.UAT_SMTP_HOST;
      process.env.NODE_ENV = 'development';
      delete process.env.UAT_SMTP_HOST;
      try {
        const pool = buildMockPool({
          selectUserByEmail: async () => ({ rows: [{ id: userId, locale: 'en' }] }),
        });
        const forgotApp = createApp(pool, mockComparePassword);
        const res = await request(forgotApp)
          .post('/api/auth/forgot-password')
          .send({ email: userEmail });
        expect(res.statusCode).toBe(200);
        expect(res.body).toHaveProperty('code');
      } finally {
        if (prevEnv === undefined) delete process.env.NODE_ENV;
        else process.env.NODE_ENV = prevEnv;
        if (prevHost === undefined) delete process.env.UAT_SMTP_HOST;
        else process.env.UAT_SMTP_HOST = prevHost;
      }
    });

    it('should return 400 when email is missing', async () => {
      const res = await request(app)
        .post('/api/auth/forgot-password')
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/reset-password', () => {
    it('should reset password with valid code', async () => {
      const pool = buildMockPool({
        selectResetToken: async () => ({ rows: [{ id: 'token-1', user_id: userId }] }),
      });
      const resetApp = createApp(pool, mockComparePassword);
      const res = await request(resetApp)
        .post('/api/auth/reset-password')
        .send({ email: userEmail, code: '123456', new_password: 'NewPassword789' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Password has been reset successfully');
    });

    it('should return 400 with invalid/expired code', async () => {
      const pool = buildMockPool({
        selectResetToken: async () => ({ rows: [] }),
      });
      const resetApp = createApp(pool, mockComparePassword);
      const res = await request(resetApp)
        .post('/api/auth/reset-password')
        .send({ email: userEmail, code: 'badcode', new_password: 'NewPassword789' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Invalid or expired reset code');
    });

    it('should return 400 when email is missing', async () => {
      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({ code: '123456', new_password: 'NewPassword789' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 when code is missing', async () => {
      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({ email: userEmail, new_password: 'NewPassword789' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 when new_password is missing', async () => {
      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({ email: userEmail, code: '123456' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });
});
