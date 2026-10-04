import { randomUUID } from 'crypto';

import jwt from 'jsonwebtoken';
import request from 'supertest';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

let pool;
let app;
let userA;
let userB;
let petA;

beforeAll(async () => {
  pool = createDbPool();
  try {
    await pool.query('SELECT 1');
  } catch {
    pool = null;
    return;
  }

  const { createApp } = await import('../../bin/server.js');
  app = createApp(pool);

  userA = randomUUID();
  userB = randomUUID();
  petA = randomUUID();

  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, 'idor-a@example.com', 'hash', 'A', 'User'), ($2, 'idor-b@example.com', 'hash', 'B', 'User')`,
    [userA, userB],
  );
  await pool.query(
    `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'IdorPet', 'dog')`,
    [petA, userA],
  );
}, 60000);

afterAll(async () => {
  if (!pool) return;
  await pool.query('DELETE FROM pets WHERE id = $1', [petA]).catch(() => {});
  await pool.query('DELETE FROM users WHERE id IN ($1, $2)', [userA, userB]).catch(() => {});
  await pool.end();
});

function tokenFor(userId, email) {
  return jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '1h' });
}

describe('cross-tenant IDOR (real PG)', () => {
  jest.setTimeout(30000);

  it('user B cannot read user A pet by id', async () => {
    if (!pool) return;
    const res = await request(app)
      .get(`/api/pets/${petA}`)
      .set('Authorization', `Bearer ${tokenFor(userB, 'idor-b@example.com')}`);
    expect([403, 404]).toContain(res.statusCode);
  });

  it('user B cannot list weight entries for user A pet', async () => {
    if (!pool) return;
    const res = await request(app)
      .get(`/api/weight-entries?pet_id=${petA}`)
      .set('Authorization', `Bearer ${tokenFor(userB, 'idor-b@example.com')}`);
    expect([200, 403]).toContain(res.statusCode);
    if (res.statusCode === 200) {
      expect(res.body).toEqual([]);
    }
  });

  it('anonymous callers cannot read user A pet', async () => {
    if (!pool) return;
    const res = await request(app).get(`/api/pets/${petA}`);
    expect(res.statusCode).toBe(401);
  });
});
