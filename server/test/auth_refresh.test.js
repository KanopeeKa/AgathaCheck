import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

describe('Auth Refresh API', () => {
  let app;
  let refreshToken;

  beforeAll(() => {
    const mockPool = {
      query: async () => ({ rows: [] }),
      end: async () => {}
    };
    app = createApp(mockPool);
    refreshToken = jwt.sign({ id: 'user-1', email: 'user@example.com' }, JWT_SECRET, { expiresIn: '30d' });
  });

  it('POST /backend/api/auth/refresh returns new access token', async () => {
    const res = await request(app)
      .post('/backend/api/auth/refresh')
      .send({ refresh_token: refreshToken });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('access_token');
    const decoded = jwt.verify(res.body.access_token, JWT_SECRET);
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
