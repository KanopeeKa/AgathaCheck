

import request from 'supertest';
import { v4 as uuidv4 } from 'uuid';
import { createApp } from '../bin/server.js';
import { expect } from 'chai';

// Create a mock pool object
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

describe('POST /backend/api/auth/signup', () => {
  it('should create a new user and return user object', async () => {
    const email = `testuser_${uuidv4()}@example.com`;
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({
        email,
        password: 'TestPassword123',
        first_name: 'Test',
        last_name: 'User',
        category: 'tester',
        bio: 'Test bio',
        photo_url: 'http://example.com/photo.png',
        locale: 'en'
      });
    expect(res.statusCode).to.equal(201);
    expect(res.body.user).to.not.be.undefined;
    expect(res.body.user.email).to.equal(email);
    expect(res.body.user.first_name).to.equal('Test');
    expect(res.body.user.last_name).to.equal('User');
    expect(res.body.user.category).to.equal('tester');
    expect(res.body.user.bio).to.equal('Test bio');
    expect(res.body.user.photo_url).to.equal('http://example.com/photo.png');
    expect(res.body.user.locale).to.equal('en');
  });

  it('should fail gracefully with missing email', async () => {
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ password: 'TestPassword123' });
    expect(res.statusCode).to.be.at.least(400);
    expect(res.body.error).to.not.be.undefined;
  });

  it('should fail gracefully with duplicate email', async () => {
    const email = `dupeuser_${uuidv4()}@example.com`;
    // First signup
    await request(app)
      .post('/backend/api/auth/signup')
      .send({ email, password: 'TestPassword123' });
    // Second signup with same email
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ email, password: 'TestPassword123' });
    expect(res.statusCode).to.be.at.least(400);
    expect(res.body.error).to.not.be.undefined;
  });
});
