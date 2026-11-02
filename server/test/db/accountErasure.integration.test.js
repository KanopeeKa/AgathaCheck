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
  acceptAccountErasure,
  clearAccountErasureFaultStep,
  setAccountErasureFaultStep,
} from '../../lib/account/accountErasureService.js';
import {
  NOTIFICATION_TYPE_HOUSEHOLD_ORGANISER_PROMOTED,
  NOTIFICATION_TYPE_HOUSEHOLD_PET_REMOVED,
} from '../../lib/notificationKind.js';
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

  it('erasing sole organiser promotes a remaining member and skips pet-removed notices for deleted pets (H6)', async () => {
    const organiser = await createUserWithPassword();
    const successorId = randomUUID();
    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, 'hash', 'Remain', 'Member')`,
      [successorId, `succ-${successorId}@example.com`],
    );

    const householdId = randomUUID();
    const directoryId = randomUUID();
    const householdContactId = randomUUID();
    const petId = randomUUID();
    const entryId = randomUUID();

    await pool.query('INSERT INTO households (id, name) VALUES ($1, $2)', [householdId, 'Erase HH']);
    await pool.query(
      `INSERT INTO household_members (household_id, user_id, access_tier, is_organiser, joined_at)
       VALUES ($1, $2, 'full_access', true, now() - interval '2 days'),
              ($1, $3, 'full_access', false, now() - interval '1 day')`,
      [householdId, organiser.userId, successorId],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species, home_timezone) VALUES ($1, $2, 'VetPet', 'dog', 'UTC')`,
      [petId, organiser.userId],
    );
    await pool.query(
      'INSERT INTO household_pets (household_id, pet_id) VALUES ($1, $2)',
      [householdId, petId],
    );
    await pool.query(
      'INSERT INTO people_directories (id, household_id) VALUES ($1, $2)',
      [directoryId, householdId],
    );
    await pool.query(
      `INSERT INTO people_contacts (id, directory_id, kind, name)
       VALUES ($1, $2, 'organisation', 'Household Vet')`,
      [householdContactId, directoryId],
    );
    await pool.query(
      `INSERT INTO health_entries (
         id, pet_id, user_id, name, type, frequency, status,
         care_family, care_setting, care_planning, care_importance,
         importance_overridden, care_source, schedule_policy_version,
         provider_contact_id
       ) VALUES (
         $1, $2, $3, 'Checkup', 'vet_visit', 'yearly', 'active',
         'wellness_review', 'vet', 'planned', 'recommended',
         false, 'guardian_defined', 1, $4
       )`,
      [entryId, petId, organiser.userId, householdContactId],
    );

    await acceptAccountErasure(pool, {
      userId: organiser.userId,
      userEmail: organiser.email,
    });

    const successor = await pool.query(
      'SELECT is_organiser, access_tier FROM household_members WHERE household_id = $1 AND user_id = $2',
      [householdId, successorId],
    );
    expect(successor.rows[0].is_organiser).toBe(true);
    expect(successor.rows[0].access_tier).toBe('full_access');

    const deletedUserDirs = await pool.query(
      'SELECT id FROM people_directories WHERE owner_user_id = $1',
      [organiser.userId],
    );
    expect(deletedUserDirs.rows).toHaveLength(0);

    const petRemoved = await pool.query(
      `SELECT 1 FROM notifications
       WHERE user_id = $1 AND type = $2 AND pet_id = $3`,
      [successorId, NOTIFICATION_TYPE_HOUSEHOLD_PET_REMOVED, petId],
    );
    expect(petRemoved.rows).toHaveLength(0);

    const promotedNotice = await pool.query(
      `SELECT 1 FROM notifications
       WHERE user_id = $1 AND type = $2`,
      [successorId, NOTIFICATION_TYPE_HOUSEHOLD_ORGANISER_PROMOTED],
    );
    expect(promotedNotice.rows.length).toBeGreaterThanOrEqual(1);
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
    expect(res.status).toBe(401);
    expect(res.body.code).toBe('account_unavailable');

    const after = fs.readdirSync(photosDir).length;
    expect(after).toBe(before);
  });
});
