import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import {
  JWT_SECRET,
  userId,
  userEmail,
  buildMockPool,
  makeRefreshToken,
  mockComparePassword,
} from './helpers.js';

describe('Auth Routes — Session', () => {
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
          category: 'pet_carer',
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
      expect(res.body.user).toHaveProperty('category', 'pet_carer');
      expect(res.body.user).toHaveProperty('bio', 'My bio');
      expect(res.body.user).toHaveProperty('photo_url', 'http://example.com/pic.png');
      expect(res.body.user).toHaveProperty('locale', 'fr');
    });

    it('links external foster contacts by email on signup', async () => {
      const fosterLinkCalls = [];
      const pool = buildMockPool({
        insertUser: async () => ({ rows: [{ id: 'new-user-id' }] }),
        fallback: async (sql, params) => {
          if (sql.includes('UPDATE org_foster_parents')) {
            fosterLinkCalls.push({ sql, params });
            return { rows: [] };
          }
          return { rows: [] };
        },
      });
      const signupApp = createApp(pool, mockComparePassword);
      const res = await request(signupApp)
        .post('/api/auth/signup')
        .send({
          email: 'foster@example.com',
          password: 'Password123',
        });
      expect(res.statusCode).toBe(201);
      expect(fosterLinkCalls).toHaveLength(1);
      expect(fosterLinkCalls[0].params[0]).toBe('new-user-id');
      expect(fosterLinkCalls[0].params[1]).toBe('foster@example.com');
    });

    it('should use default values for optional fields', async () => {
      const res = await request(app)
        .post('/api/auth/signup')
        .send({ email: 'minimal@example.com', password: 'Password123' });
      expect(res.statusCode).toBe(201);
      expect(res.body.user.first_name).toBe('');
      expect(res.body.user.last_name).toBe('');
      expect(res.body.user.category).toBe('pet_carer');
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
      expect(res.body.user).toHaveProperty('category', 'pet_carer');
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
});
