import request from 'supertest';
import app from '../bin/server.js';

describe('POST /backend/api/auth/login', () => {
  it('should login successfully and return user and tokens', async () => {
    // You should have a test user in your test DB for this to work
    const email = 'testuser@example.com';
    const password = 'testpassword';
    // Optionally, create the user first if not present
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email, password });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('user');
    expect(res.body.user).toHaveProperty('id');
    expect(res.body.user).toHaveProperty('email', email);
    expect(res.body).toHaveProperty('access_token');
    expect(res.body).toHaveProperty('refresh_token');
  });

  it('should fail with wrong password', async () => {
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email: 'testuser@example.com', password: 'wrongpassword' });
    expect(res.statusCode).toBe(401);
    expect(res.body).toHaveProperty('error');
  });

  it('should fail with missing fields', async () => {
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email: '' });
    expect(res.statusCode).toBe(400);
    expect(res.body).toHaveProperty('error');
  });
});
