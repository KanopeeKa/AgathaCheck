import request from 'supertest';
import express from 'express';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import app from '../bin/server.js';

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
    expect(res.statusCode).toBe(201);
    expect(res.body.user).toBeDefined();
    expect(res.body.user.email).toBe(email);
    expect(res.body.user.first_name).toBe('Test');
    expect(res.body.user.last_name).toBe('User');
    expect(res.body.user.category).toBe('tester');
    expect(res.body.user.bio).toBe('Test bio');
    expect(res.body.user.photo_url).toBe('http://example.com/photo.png');
    expect(res.body.user.locale).toBe('en');
  });

  it('should fail gracefully with missing email', async () => {
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ password: 'TestPassword123' });
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.body.error).toBeDefined();
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
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.body.error).toBeDefined();
  });
});
