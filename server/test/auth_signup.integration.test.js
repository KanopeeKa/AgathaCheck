import request from 'supertest';
import { createApp } from '../bin/server.js';
import { expect } from 'chai';
import jwt from 'jsonwebtoken';
describe('POST /backend/api/auth/signup (integration)', () => {

// Create a mock pool object (same as in unit test)
const mockPool = {
  query: async (sql, params) => {
    if (sql.includes('INSERT INTO users')) {
      if (params[1] && params[1].startsWith('dupeuser_')) {
        const err = new Error('duplicate key value violates unique constraint');
        err.code = '23505';
        throw err;
      }
      return { rows: [{ id: 'mock-user-id' }] };
    }
    return { rows: [] };
  },
  end: async () => {}
};

const app = createApp(mockPool);
const testEmail = `integration_${Date.now()}@example.com`;
const password = 'TestPassword123!';

  it('should create a new user and return user object with JWT tokens', async () => {
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({
        email: testEmail,
        password,
        first_name: 'Integration',
        last_name: 'Test',
      });
    expect(res.statusCode).to.equal(201);
    expect(res.body.user).to.not.be.undefined;
    expect(res.body.user.email).to.equal(testEmail);
    expect(res.body.access_token).to.be.a('string');
    expect(res.body.refresh_token).to.be.a('string');
    // Validate JWT
    const decoded = jwt.decode(res.body.access_token);
    expect(decoded).to.have.property('id');
    expect(decoded).to.have.property('email', testEmail);
  });

  it('should fail with missing email', async () => {
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ password });
    expect(res.statusCode).to.be.at.least(400);
    expect(res.body.error).to.not.be.undefined;
  });

  it('should fail with duplicate email', async () => {
    // Use a known prefix that triggers the mock duplicate logic
    const dupeEmail = `dupeuser_${Date.now()}@example.com`;
    // First signup
    await request(app)
      .post('/backend/api/auth/signup')
      .send({ email: dupeEmail, password });
    // Second signup with same email
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ email: dupeEmail, password });
    expect(res.statusCode).to.be.at.least(400);
    expect(res.body.error).to.not.be.undefined;
  });
});
