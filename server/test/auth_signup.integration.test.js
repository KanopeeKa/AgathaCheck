import request from 'supertest';
import { createApp } from '../bin/server.js';
import { expect } from 'chai';
import jwt from 'jsonwebtoken';

describe('POST /backend/api/auth/signup (integration)', () => {
  const app = createApp();
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
    // First signup
    await request(app)
      .post('/backend/api/auth/signup')
      .send({ email: testEmail, password });
    // Second signup with same email
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ email: testEmail, password });
    expect(res.statusCode).to.be.at.least(400);
    expect(res.body.error).to.not.be.undefined;
  });
});
