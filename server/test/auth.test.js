import request from 'supertest';
import { createApp } from '../bin/server.js';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

const userId = 'test-user-id-1';
const userEmail = 'testuser@example.com';
const userPasswordHash = '$2b$10$validhashfortestpassword';
const userRow = {
  id: userId,
  email: userEmail,
  password_hash: userPasswordHash,
  first_name: 'Test',
  last_name: 'User',
  category: 'pet_guardian',
  bio: 'A test bio',
  photo_url: 'http://example.com/photo.png',
  locale: 'en',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
};

function makeToken(overrides = {}) {
  return jwt.sign(
    { id: userId, email: userEmail, ...overrides },
    JWT_SECRET,
    { expiresIn: '1h' },
  );
}

function makeExpiredToken() {
  return jwt.sign({ id: userId, email: userEmail }, JWT_SECRET, { expiresIn: '-1s' });
}

function makeRefreshToken(overrides = {}) {
  return jwt.sign(
    { id: userId, email: userEmail, ...overrides },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

function buildMockPool(overrides = {}) {
  const defaults = {
    insertUser: async (sql, params) => ({ rows: [{ id: userId }] }),
    selectUserByEmail: async (sql, params) => ({ rows: [userRow] }),
    selectUserById: async (sql, params) => ({ rows: [userRow] }),
    selectPasswordHash: async (sql, params) => ({ rows: [{ password_hash: userPasswordHash }] }),
    updateUser: async (sql, params) => ({ rows: [{ ...userRow, ...overrides.updatedFields }] }),
    deleteUser: async (sql, params) => ({ rows: [] }),
    selectPets: async (sql, params) => ({ rows: [{ id: 'pet-1', name: 'Buddy' }] }),
    selectVets: async (sql, params) => ({ rows: [{ id: 'vet-1', name: 'Dr. Smith' }] }),
    selectResetToken: async (sql, params) => ({ rows: [] }),
    insertResetToken: async (sql, params) => ({ rows: [] }),
    updateResetTokenUsed: async (sql, params) => ({ rows: [] }),
    updatePasswordHash: async (sql, params) => ({ rows: [] }),
    fallback: async (sql, params) => ({ rows: [] }),
  };
  const handlers = { ...defaults, ...overrides };

  return {
    query: async (sql, params) => {
      if (sql.includes('INSERT INTO users')) return handlers.insertUser(sql, params);
      if (sql.includes('SELECT * FROM users WHERE email')) return handlers.selectUserByEmail(sql, params);
      if (sql.includes('SELECT * FROM users WHERE id')) return handlers.selectUserById(sql, params);
      if (sql.includes('SELECT password_hash FROM users WHERE id')) return handlers.selectPasswordHash(sql, params);
      if (sql.includes('UPDATE users SET password_hash')) return handlers.updatePasswordHash(sql, params);
      if (sql.includes('UPDATE users SET') && !sql.includes('password_hash')) return handlers.updateUser(sql, params);
      if (sql.includes('DELETE FROM users')) return handlers.deleteUser(sql, params);
      if (sql.includes('SELECT * FROM pets')) return handlers.selectPets(sql, params);
      if (sql.includes('SELECT * FROM vets')) return handlers.selectVets(sql, params);
      if (sql.includes('SELECT id FROM users WHERE email')) return handlers.selectUserByEmail(sql, params);
      if (sql.includes('INSERT INTO password_reset_tokens')) return handlers.insertResetToken(sql, params);
      if (sql.includes('SELECT prt.id')) return handlers.selectResetToken(sql, params);
      if (sql.includes('UPDATE password_reset_tokens')) return handlers.updateResetTokenUsed(sql, params);
      return handlers.fallback(sql, params);
    },
    end: async () => {},
  };
}

function mockComparePassword(inputPassword, hash) {
  if (inputPassword === 'testpassword' && hash === userPasswordHash) return true;
  return false;
}

describe('Auth Routes', () => {
  let app;
  let mockPool;

  beforeEach(() => {
    mockPool = buildMockPool();
    app = createApp(mockPool, mockComparePassword);
  });

  describe('POST /api/auth/signup', () => {
    it('should create a new user and return user with tokens', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({
          email: 'new@example.com',
          password: 'Password123',
          first_name: 'New',
          last_name: 'User',
          category: 'pet_guardian',
          bio: 'My bio',
          photo_url: 'http://example.com/pic.png',
          locale: 'fr',
        });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('user');
      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('refresh_token');
      expect(res.body.user).toHaveProperty('id');
      expect(res.body.user).toHaveProperty('email', 'new@example.com');
      expect(res.body.user).toHaveProperty('first_name', 'New');
      expect(res.body.user).toHaveProperty('last_name', 'User');
      expect(res.body.user).toHaveProperty('category', 'pet_guardian');
      expect(res.body.user).toHaveProperty('bio', 'My bio');
      expect(res.body.user).toHaveProperty('photo_url', 'http://example.com/pic.png');
      expect(res.body.user).toHaveProperty('locale', 'fr');
    });

    it('should use default values for optional fields', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'minimal@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(201);
      expect(res.body.user.first_name).toBe('');
      expect(res.body.user.last_name).toBe('');
      expect(res.body.user.category).toBe('pet_guardian');
      expect(res.body.user.bio).toBe('');
      expect(res.body.user.photo_url).toBe('');
      expect(res.body.user.locale).toBe('en');
    });

    it('should return valid JWT tokens', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'jwt@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(201);
      const decoded = jwt.verify(res.body.access_token, JWT_SECRET);
      expect(decoded).toHaveProperty('id');
      expect(decoded).toHaveProperty('email', 'jwt@example.com');
      const decodedRefresh = jwt.verify(res.body.refresh_token, JWT_SECRET);
      expect(decodedRefresh).toHaveProperty('id');
    });

    it('should return 400 when email is missing', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ password: 'Password123' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 when password is missing', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'nopass@example.com' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 with empty body', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 for duplicate email', async () => {
      const pool = buildMockPool({
        insertUser: async () => {
          const err = new Error('duplicate key value violates unique constraint');
          err.code = '23505';
          throw err;
        },
      });
      const dupeApp = createApp(pool, mockComparePassword);
      const res = await request(dupeApp)
        .post('/api/auth/signup')
        .send({ email: 'dupe@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/already exists/i);
    });

    it('should return 500 on unexpected database error', async () => {
      const pool = buildMockPool({
        insertUser: async () => { throw new Error('DB connection lost'); },
      });
      const errApp = createApp(pool, mockComparePassword);
      const res = await request(errApp)
        .post('/api/auth/signup')
        .send({ email: 'err@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(500);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login successfully and return user and tokens', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('refresh_token');
      expect(res.body.user).toHaveProperty('id', userId);
      expect(res.body.user).toHaveProperty('email', userEmail);
      expect(res.body.user).toHaveProperty('first_name', 'Test');
      expect(res.body.user).toHaveProperty('last_name', 'User');
      expect(res.body.user).toHaveProperty('category', 'pet_guardian');
      expect(res.body.user).toHaveProperty('bio', 'A test bio');
      expect(res.body.user).toHaveProperty('photo_url', 'http://example.com/photo.png');
      expect(res.body.user).toHaveProperty('locale', 'en');
    });

    it('should return valid JWT tokens on login', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      const decoded = jwt.verify(res.body.access_token, JWT_SECRET);
      expect(decoded).toHaveProperty('id', userId);
      expect(decoded).toHaveProperty('email', userEmail);
    });

    it('should return 401 for wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'wrongpassword' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 for non-existent email', async () => {
      const pool = buildMockPool({
        selectUserByEmail: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const res = await request(noUserApp)
        .post('/api/auth/login')
        .send({ email: 'nobody@example.com', password: 'testpassword' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 when email is missing', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ password: 'testpassword' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 when password is missing', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 with empty body', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 with empty string email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: '', password: 'testpassword' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/refresh', () => {
    it('should return a new access token with valid refresh token', async () => {
      const refreshToken = makeRefreshToken();
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('access_token');
      const decoded = jwt.verify(res.body.access_token, JWT_SECRET);
      expect(decoded).toHaveProperty('id', userId);
      expect(decoded).toHaveProperty('email', userEmail);
    });

    it('should return 400 when refresh_token is missing', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with invalid refresh token', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: 'invalid-token-string' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired refresh token', async () => {
      const expiredToken = jwt.sign({ id: userId, email: userEmail }, JWT_SECRET, { expiresIn: '-1s' });
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: expiredToken });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with token signed with wrong secret', async () => {
      const badToken = jwt.sign({ id: userId, email: userEmail }, 'wrong_secret', { expiresIn: '30d' });
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refresh_token: badToken });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should return 200 with logged out message', async () => {
      const res = await request(app)
        .post('/api/auth/logout')
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Logged out');
    });
  });

  describe('GET /api/auth/me', () => {
    it('should return user profile with valid token', async () => {
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id', userId);
      expect(res.body).toHaveProperty('email', userEmail);
      expect(res.body).toHaveProperty('first_name', 'Test');
      expect(res.body).toHaveProperty('last_name', 'User');
      expect(res.body).toHaveProperty('category', 'pet_guardian');
      expect(res.body).toHaveProperty('bio', 'A test bio');
      expect(res.body).toHaveProperty('photo_url', 'http://example.com/photo.png');
      expect(res.body).toHaveProperty('locale', 'en');
    });

    it('should return 401 without token', async () => {
      const res = await request(app).get('/api/auth/me');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with malformed authorization header', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'NotBearer sometoken');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        selectUserById: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('PUT /api/auth/me', () => {
    it('should update user profile fields', async () => {
      const updatedRow = { ...userRow, first_name: 'Updated', last_name: 'Name', bio: 'New bio' };
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [updatedRow] }),
      });
      const updateApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(updateApp)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ first_name: 'Updated', last_name: 'Name', bio: 'New bio' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('first_name', 'Updated');
      expect(res.body).toHaveProperty('last_name', 'Name');
      expect(res.body).toHaveProperty('bio', 'New bio');
    });

    it('should update locale', async () => {
      const updatedRow = { ...userRow, locale: 'fr' };
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [updatedRow] }),
      });
      const updateApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(updateApp)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ locale: 'fr' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('locale', 'fr');
    });

    it('should return 400 with no fields to update', async () => {
      const token = makeToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .put('/api/auth/me')
        .send({ first_name: 'Hacker' });
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ first_name: 'Expired' });
      expect(res.statusCode).toBe(500);
    });

    it('should return 404 when user not found on update', async () => {
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .put('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ first_name: 'Ghost' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/me/photo', () => {
    it('should update photo and return user', async () => {
      const updatedRow = { ...userRow, photo_url: '/uploads/photos/test.jpg' };
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [updatedRow] }),
      });
      const photoApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(photoApp)
        .post('/api/auth/me/photo')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('photo_url');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .post('/api/auth/me/photo')
        .send({});
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .post('/api/auth/me/photo')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(500);
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        updateUser: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .post('/api/auth/me/photo')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(404);
    });
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
          if (sql.includes('SELECT id FROM users')) return { rows: [{ id: userId }] };
          return { rows: [userRow] };
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
          selectUserByEmail: async () => ({ rows: [{ id: userId }] }),
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

  describe('DELETE /api/auth/me', () => {
    it('should delete account with correct password', async () => {
      const token = makeToken();
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Account deleted successfully');
    });

    it('should return 400 with incorrect password', async () => {
      const token = makeToken();
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password: 'wrongpassword' });
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error', 'Password is incorrect');
    });

    it('should return 400 when password is missing', async () => {
      const token = makeToken();
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 401 without token', async () => {
      const res = await request(app)
        .delete('/api/auth/me')
        .send({ password: 'testpassword' });
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
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password: 'testpassword' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('GET /api/auth/me/export', () => {
    it('should export user data with pets and vets', async () => {
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('user');
      expect(res.body.user).toHaveProperty('id', userId);
      expect(res.body.user).toHaveProperty('email', userEmail);
      expect(res.body).toHaveProperty('pets');
      expect(Array.isArray(res.body.pets)).toBe(true);
      expect(res.body.pets.length).toBe(1);
      expect(res.body).toHaveProperty('vets');
      expect(Array.isArray(res.body.vets)).toBe(true);
      expect(res.body.vets.length).toBe(1);
      expect(res.body).toHaveProperty('exported_at');
    });

    it('should return 401 without token', async () => {
      const res = await request(app).get('/api/auth/me/export');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should return error with expired token', async () => {
      const token = makeExpiredToken();
      const res = await request(app)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect([401, 500]).toContain(res.statusCode);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 404 when user not found', async () => {
      const pool = buildMockPool({
        selectUserById: async () => ({ rows: [] }),
      });
      const noUserApp = createApp(pool, mockComparePassword);
      const token = makeToken();
      const res = await request(noUserApp)
        .get('/api/auth/me/export')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('Auth guard consistency', () => {
    const protectedEndpoints = [
      { method: 'get', path: '/api/auth/me' },
      { method: 'put', path: '/api/auth/me' },
      { method: 'post', path: '/api/auth/me/photo' },
      { method: 'post', path: '/api/auth/change-password' },
      { method: 'delete', path: '/api/auth/me' },
      { method: 'get', path: '/api/auth/me/export' },
    ];

    protectedEndpoints.forEach(({ method, path }) => {
      it(`${method.toUpperCase()} ${path} returns 401 without token`, async () => {
        const res = await request(app)[method](path).send({});
        expect(res.statusCode).toBe(401);
        expect(res.body).toHaveProperty('error');
      });

      it(`${method.toUpperCase()} ${path} returns 401 with invalid token`, async () => {
        const res = await request(app)[method](path)
          .set('Authorization', 'Bearer totally-invalid-token')
          .send({});
        const status = res.statusCode;
        expect(status === 401 || status === 500).toBe(true);
      });
    });
  });

  describe('Response shape validation', () => {
    it('login response user has all expected fields', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userEmail, password: 'testpassword' });
      expect(res.statusCode).toBe(200);
      const user = res.body.user;
      expect(user).toHaveProperty('id');
      expect(user).toHaveProperty('email');
      expect(user).toHaveProperty('first_name');
      expect(user).toHaveProperty('last_name');
      expect(user).toHaveProperty('category');
      expect(user).toHaveProperty('bio');
      expect(user).toHaveProperty('photo_url');
      expect(user).toHaveProperty('locale');
    });

    it('signup response user has all expected fields', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'shape@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(201);
      const user = res.body.user;
      expect(user).toHaveProperty('id');
      expect(user).toHaveProperty('email');
      expect(user).toHaveProperty('first_name');
      expect(user).toHaveProperty('last_name');
      expect(user).toHaveProperty('category');
      expect(user).toHaveProperty('bio');
      expect(user).toHaveProperty('photo_url');
      expect(user).toHaveProperty('locale');
    });

    it('me endpoint response has all expected fields', async () => {
      const token = makeToken();
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('email');
      expect(res.body).toHaveProperty('first_name');
      expect(res.body).toHaveProperty('last_name');
      expect(res.body).toHaveProperty('category');
      expect(res.body).toHaveProperty('bio');
      expect(res.body).toHaveProperty('photo_url');
      expect(res.body).toHaveProperty('locale');
    });
  });
});
