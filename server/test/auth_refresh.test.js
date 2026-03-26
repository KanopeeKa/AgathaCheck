import request from 'supertest';
import express from 'express';
import jwt from 'jsonwebtoken';
import authRoutes from '../routes/auth.js';

describe('Auth Refresh API', () => {
  let app;
  let jwtSecret;
  let refreshToken;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    // Mock pool (not used for refresh)
    app.use('/backend/api/auth', authRoutes({}, null));
    jwtSecret = process.env.JWT_SECRET || 'default_secret';
    refreshToken = jwt.sign({ id: 'user-1', email: 'user@example.com' }, jwtSecret, { expiresIn: '30d' });
  });

  it('POST /backend/api/auth/refresh returns new access token', async () => {
    const res = await request(app)
      .post('/backend/api/auth/refresh')
      .send({ refresh_token: refreshToken });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('access_token');
    // Should be a valid JWT
    const decoded = jwt.verify(res.body.access_token, jwtSecret);
    expect(decoded).toHaveProperty('id', 'user-1');
    expect(decoded).toHaveProperty('email', 'user@example.com');
  });

  it('POST /backend/api/auth/refresh with missing token returns 400', async () => {
    const res = await request(app)
      .post('/backend/api/auth/refresh')
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body).toHaveProperty('error');
  });

  it('POST /backend/api/auth/refresh with invalid token returns 401', async () => {
    const res = await request(app)
      .post('/backend/api/auth/refresh')
      .send({ refresh_token: 'invalid' });
    expect(res.statusCode).toBe(401);
    expect(res.body).toHaveProperty('error');
  });
});
