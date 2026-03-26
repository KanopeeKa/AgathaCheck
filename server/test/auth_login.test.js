
import request from 'supertest';
import { createApp } from '../bin/server.js';
import { expect } from 'chai';


import * as bcrypt from 'bcrypt';


// Helper to simulate password hash for test
function fakePasswordHash(pw) {
  if (pw === 'testpassword') return '$2b$10$validhashfortestpassword';
  if (pw === 'wrongpassword') return '$2b$10$validhashforwrongpassword';
  return '$2b$10$someotherhash';
}

const mockPool = {
  query: async (sql, params) => {
    if (sql.includes('SELECT * FROM users WHERE email = $1')) {
      if (params[0] === 'testuser@example.com') {
        // Return a user with a password_hash that matches the password
        return { rows: [{
          id: 'mock-user-id',
          email: 'testuser@example.com',
          password_hash: fakePasswordHash('testpassword'),
          first_name: 'Test',
          last_name: 'User',
          category: 'tester',
          bio: 'Test bio',
          photo_url: 'http://example.com/photo.png',
          locale: 'en'
        }] };
      }
      return { rows: [] };
    }
    return { rows: [] };
  },
  end: async () => {}
};

// Inject a mock comparePassword function
function mockComparePassword(pw, hash) {
  if (pw === 'testpassword' && hash === fakePasswordHash('testpassword')) return true;
  if (pw === 'wrongpassword' && hash === fakePasswordHash('testpassword')) return false;
  return false;
}

const app = createApp(mockPool, mockComparePassword);

describe('POST /backend/api/auth/login', () => {
  it('should login successfully and return user and tokens', async () => {
    const email = 'testuser@example.com';
    const password = 'testpassword';
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email, password });
    expect(res.statusCode).to.equal(200);
    expect(res.body).to.have.property('user');
    expect(res.body.user).to.have.property('id');
    expect(res.body.user).to.have.property('email', email);
    expect(res.body).to.have.property('access_token');
    expect(res.body).to.have.property('refresh_token');
  });

  it('should fail with wrong password', async () => {
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email: 'testuser@example.com', password: 'wrongpassword' });
    expect(res.statusCode).to.equal(401);
    expect(res.body).to.have.property('error');
  });

  it('should fail with missing fields', async () => {
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email: '' });
    expect(res.statusCode).to.equal(400);
    expect(res.body).to.have.property('error');
  });
});
