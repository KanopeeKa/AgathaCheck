import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

import { createApp } from '../../../bin/server.js';
import { createDbPool } from '../helpers/careHarness.js';
import {
  applySupportIntakeDown,
  applySupportIntakeMigration,
} from '../helpers/supportIntakeSql.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

let pool;
let app;
let userId;
let token;

function payload() {
  return {
    category: 'account',
    title: 'Rate limit probe',
    description: 'Integration test ticket',
    locale: 'en',
    context: { platform: 'web' },
  };
}

beforeAll(async () => {
  pool = createDbPool();
  await applySupportIntakeDown(pool).catch(() => {});
  await applySupportIntakeMigration(pool);

  userId = uuidv4();
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Support', 'RateTest')
     ON CONFLICT (id) DO NOTHING`,
    [userId, `support-rate-${userId}@example.com`],
  );
  token = jwt.sign(
    { id: userId, email: `support-rate-${userId}@example.com`, typ: 'access' },
    JWT_SECRET,
    { expiresIn: '1h' },
  );
  app = createApp(pool);
}, 60000);

afterAll(async () => {
  if (pool) {
    await pool.query('DELETE FROM support_outbox WHERE ticket_id IN (SELECT id FROM support_tickets WHERE user_id = $1)', [userId]);
    await pool.query('DELETE FROM support_tickets WHERE user_id = $1', [userId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
    await pool.end();
  }
});

describe('POST /api/support/tickets rate limit (real PG)', () => {
  it('returns 429 with Retry-After after 3 tickets in one hour', async () => {
    for (let i = 0; i < 3; i += 1) {
      const ok = await request(app)
        .post('/api/support/tickets')
        .set('Authorization', `Bearer ${token}`)
        .send(payload());
      expect(ok.statusCode).toBe(201);
    }

    const blocked = await request(app)
      .post('/api/support/tickets')
      .set('Authorization', `Bearer ${token}`)
      .send(payload());

    expect(blocked.statusCode).toBe(429);
    expect(blocked.headers['retry-after']).toBeDefined();
    expect(Number(blocked.headers['retry-after'])).toBeGreaterThan(0);
    expect(blocked.body.error).toMatch(/too many/i);
  });
});
