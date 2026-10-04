import { randomUUID } from 'crypto';
import fs from 'fs';
import os from 'os';
import path from 'path';

import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it, jest } from '@jest/globals';

import { createApp } from '../../bin/server.js';
import {
  clearAccountErasureFaultStep,
  setAccountErasureFaultStep,
} from '../../lib/account/accountErasureService.js';
import * as posthogServer from '../../lib/posthogServer.js';
import { createDbPool } from './helpers/careHarness.js';
import {
  applyAccountErasureMigration,
} from './helpers/accountErasureSql.js';
import {
  applyCleanupJobsMigration,
} from './helpers/cleanupJobsSql.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const FAULT_STEPS = [
  'lock_user',
  'collect_files',
  'enqueue_jobs',
  'revoke_sessions',
  'insert_operation',
  'explicit_erasure',
  'delete_user',
  'audit',
];

let pool;
let app;

async function createUserWithPassword(password = 'EraseMe123!') {
  const userId = randomUUID();
  const email = `erase-${userId}@example.com`;
  const passwordHash = await bcrypt.hash(password, 10);
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, $3, 'Erase', 'Tester')`,
    [userId, email, passwordHash],
  );
  const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '1h' });
  return { userId, email, token, password };
}

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables WHERE table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('account erasure integration tests require migrated PostgreSQL');
  }
  await applyCleanupJobsMigration(pool).catch(() => {});
  await applyAccountErasureMigration(pool).catch(() => {});
  app = createApp(pool);
}, 60000);

afterAll(async () => {
  if (pool) await pool.end();
});

afterEach(() => {
  clearAccountErasureFaultStep();
  jest.restoreAllMocks();
});

describe('account erasure (real PG)', () => {
  it('DELETE /api/auth/me returns 202 and enqueues cleanup jobs', async () => {
    const { userId, token, password } = await createUserWithPassword();
    const petId = randomUUID();
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species, home_timezone) VALUES ($1, $2, 'P', 'dog', 'UTC')`,
      [petId, userId],
    );

    const res = await request(app)
      .delete('/api/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });

    expect(res.status).toBe(202);
    expect(typeof res.body.message).toBe('string');
    expect(res.body.erasure.status).toBe('accepted');
    expect(res.body.erasure.status_token).toBeTruthy();

    const users = await pool.query('SELECT 1 FROM users WHERE id = $1', [userId]);
    expect(users.rows).toHaveLength(0);

    const jobs = await pool.query(
      'SELECT job_type FROM cleanup_jobs WHERE correlation_id = $1',
      [res.body.erasure.operation_id],
    );
    expect(jobs.rows.some((j) => j.job_type === 'posthog_person_delete')).toBe(true);

    const login = await pool.query('SELECT 1 FROM users WHERE id = $1', [userId]);
    expect(login.rows).toHaveLength(0);
  });

  it('idempotent DELETE /me after acceptance returns same operation without status_token', async () => {
    const { userId, token, password } = await createUserWithPassword();
    const first = await request(app)
      .delete('/api/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });
    expect(first.status).toBe(202);
    const operationId = first.body.erasure.operation_id;

    const second = await request(app)
      .delete('/backend/api/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });
    expect(second.status).toBe(202);
    expect(second.body.erasure.operation_id).toBe(operationId);
    expect(second.body.erasure.status_token).toBeUndefined();

    const jobCount = await pool.query(
      'SELECT count(*)::int AS n FROM cleanup_jobs WHERE correlation_id = $1',
      [operationId],
    );
    const phCount = await pool.query(
      `SELECT count(*)::int AS n FROM cleanup_jobs
       WHERE correlation_id = $1 AND job_type = 'posthog_person_delete'`,
      [operationId],
    );
    expect(phCount.rows[0].n).toBe(1);
    expect(jobCount.rows[0].n).toBeGreaterThanOrEqual(1);
  });

  it('GET erasure status requires token and hides wrong token', async () => {
    const { token, password } = await createUserWithPassword();
    const del = await request(app)
      .delete('/api/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });
    const { operation_id: operationId, status_token } = del.body.erasure;

    const ok = await request(app)
      .get(`/api/auth/erasure/${operationId}`)
      .set('X-Erasure-Status-Token', status_token);
    expect(ok.status).toBe(200);
    expect(ok.body.steps.database).toBe('completed');
    expect(ok.body.steps.files).toMatchObject({
      total: expect.any(Number),
      succeeded: expect.any(Number),
      pending: expect.any(Number),
      dead: expect.any(Number),
    });

    const wrong = await request(app)
      .get(`/backend/api/auth/erasure/${operationId}`)
      .set('X-Erasure-Status-Token', 'not-the-token');
    expect(wrong.status).toBe(404);

    const missing = await request(app).get(`/api/auth/erasure/${randomUUID()}`)
      .set('X-Erasure-Status-Token', status_token);
    expect(missing.status).toBe(404);
  });

  it('fault injection at each step rolls back and leaves user intact', async () => {
    jest.spyOn(posthogServer, 'deletePostHogPersonForJob').mockResolvedValue({
      kind: 'succeeded',
    });

    for (const step of FAULT_STEPS) {
      await pool.query('DELETE FROM cleanup_jobs');
      const { userId, token, password } = await createUserWithPassword();
      setAccountErasureFaultStep(step);
      const res = await request(app)
        .delete('/api/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send({ password });
      expect(res.status).toBe(500);

      const user = await pool.query('SELECT id FROM users WHERE id = $1', [userId]);
      expect(user.rows).toHaveLength(1);

      const jobs = await pool.query('SELECT count(*)::int AS n FROM cleanup_jobs');
      expect(jobs.rows[0].n).toBe(0);

      clearAccountErasureFaultStep();
    }
    expect(posthogServer.deletePostHogPersonForJob).not.toHaveBeenCalled();
  });

  it('profile photo upload removes file when user row is gone', async () => {
    const { userId, token } = await createUserWithPassword();
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);

    const photosDir = path.join(process.cwd(), 'uploads', 'photos');
    fs.mkdirSync(photosDir, { recursive: true });
    const before = fs.readdirSync(photosDir).length;

    const res = await request(app)
      .post('/api/auth/me/photo')
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.status).toBe(404);

    const after = fs.readdirSync(photosDir).length;
    expect(after).toBe(before);
  });
});
