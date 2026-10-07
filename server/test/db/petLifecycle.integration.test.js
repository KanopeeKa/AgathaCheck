import { randomUUID } from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createApp } from '../../bin/server.js';
import {
  clearPetDeletionFaultStep,
  deleteAllPetData,
  deletePet,
  notifyPassedAwayCollaborators,
  setPetDeletionFaultStep,
} from '../../lib/petDataLifecycle.js';
import { drainCleanupJobs } from '../../lib/jobs/cleanupJobsRunner.js';
import { createDbPool } from './helpers/careHarness.js';
import {
  applyCleanupJobsDown,
  applyCleanupJobsMigration,
} from './helpers/cleanupJobsSql.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const lifecycleMigrationSql = fs.readFileSync(
  path.resolve(__dirname, '../../../db/migrations/086_pet_lifecycle_notifications.sql'),
  'utf8',
);
const lifecycleDownSql = fs.readFileSync(
  path.resolve(__dirname, '../../../db/migrations/086_pet_lifecycle_notifications_down.sql'),
  'utf8',
);

const PET_DELETE_FAULT_STEPS = [
  'enqueue_jobs',
  'delete_weight_entries',
  'delete_health_issues',
  'delete_health_entries',
  'delete_pet_timeline_entries',
  'delete_pet_activity_events',
  'delete_family_events',
  'delete_notifications',
  'delete_pet_share_links',
  'delete_pet_row',
  'audit_insert',
];

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

let pool;

async function seedUserPet(client, { userId, petId, photoPath = null }) {
  await client.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Test', 'User')`,
    [userId, `pet-life-${userId}@example.com`],
  );
  await client.query(
    `INSERT INTO pets (id, user_id, name, species, photo_path)
     VALUES ($1, $2, 'LifePet', 'cat', $3)`,
    [petId, userId, photoPath],
  );
}

beforeAll(async () => {
  process.env.CLEANUP_JOBS_RUNNER = 'off';
  pool = createDbPool();
  await pool.query('SELECT 1');
  await applyCleanupJobsDown(pool).catch(() => {});
  await applyCleanupJobsMigration(pool);
  await pool.query(lifecycleDownSql).catch(() => {});
  await pool.query(lifecycleMigrationSql);
}, 60000);

afterAll(async () => {
  await pool?.end();
});

afterEach(() => {
  clearPetDeletionFaultStep();
});

describe('pet lifecycle commands (real PG)', () => {
  jest.setTimeout(30000);

  it('schedules file_delete and removes the file after drain', async () => {
    const userId = randomUUID();
    const petId = randomUUID();
    const uploadsDir = path.join(process.cwd(), 'uploads', 'pet_lifecycle_test');
    fs.mkdirSync(uploadsDir, { recursive: true });
    const fileName = `photo-${randomUUID()}.txt`;
    const diskPath = path.join(uploadsDir, fileName);
    fs.writeFileSync(diskPath, 'pet-photo');
    const photoPath = `/uploads/pet_lifecycle_test/${fileName}`;

    await seedUserPet(pool, { userId, petId, photoPath });

    const result = await deleteAllPetData(pool, petId, { actorUserId: userId });
    expect(result.files_scheduled).toBe(1);
    expect(result.file_cleanup).toBe('scheduled');
    expect(fs.existsSync(diskPath)).toBe(true);

    await drainCleanupJobs(pool, { limit: 20 });
    expect(fs.existsSync(diskPath)).toBe(false);

    await pool.query('DELETE FROM cleanup_jobs WHERE correlation_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
    fs.rmSync(uploadsDir, { recursive: true, force: true });
  }, 30000);

  it('deletePet is atomic and returns the D13 response shape', async () => {
    const userId = randomUUID();
    const petId = randomUUID();
    await seedUserPet(pool, { userId, petId });

    const result = await deletePet(pool, petId, { actorUserId: userId });
    expect(result).toMatchObject({
      deleted: true,
      pet_id: petId,
      file_cleanup: 'none',
      files_scheduled: 0,
      files_removed: 0,
    });

    const pet = await pool.query('SELECT id FROM pets WHERE id = $1', [petId]);
    expect(pet.rows).toHaveLength(0);

    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });

  it('deletePet fault injection rolls back and leaves pet intact', async () => {
    for (const step of PET_DELETE_FAULT_STEPS) {
      const userId = randomUUID();
      const petId = randomUUID();
      await seedUserPet(pool, { userId, petId });
      await pool.query(
        `INSERT INTO health_entries
           (id, pet_id, user_id, type, name, frequency, recurrence_anchor,
            next_due_date, start_date, status, care_planning, care_importance)
         VALUES ($1, $2, $3, 'medication', 'Fault pet care', 'daily', 'from_due_date',
           '2030-06-05', '2030-06-05', 'active', 'planned', 'essential')`,
        [randomUUID(), petId, userId],
      );

      setPetDeletionFaultStep(step);
      await expect(
        deletePet(pool, petId, { actorUserId: userId }),
      ).rejects.toThrow(/pet deletion fault injection/);

      const pet = await pool.query('SELECT id FROM pets WHERE id = $1', [petId]);
      expect(pet.rows).toHaveLength(1);

      const jobs = await pool.query(
        'SELECT count(*)::int AS n FROM cleanup_jobs WHERE correlation_id = $1',
        [petId],
      );
      expect(jobs.rows[0].n).toBe(0);

      const audits = await pool.query(
        `SELECT count(*)::int AS n FROM audit_events
         WHERE resource_id = $1 AND action = 'pet.deleted'`,
        [petId],
      );
      expect(audits.rows[0].n).toBe(0);

      clearPetDeletionFaultStep();
      await pool.query('DELETE FROM health_entries WHERE pet_id = $1', [petId]);
      await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
      await pool.query('DELETE FROM users WHERE id = $1', [userId]);
    }
  });

  it('failed deletePet at audit_insert writes no audit row', async () => {
    const userId = randomUUID();
    const petId = randomUUID();
    await seedUserPet(pool, { userId, petId });
    setPetDeletionFaultStep('audit_insert');

    await expect(deletePet(pool, petId, { actorUserId: userId })).rejects.toThrow();

    const audits = await pool.query(
      `SELECT id FROM audit_events WHERE resource_id = $1`,
      [petId],
    );
    expect(audits.rows).toHaveLength(0);

    clearPetDeletionFaultStep();
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });

  it('passed-away dedupes notifications on repeat POST', async () => {
    const ownerId = randomUUID();
    const collabId = randomUUID();
    const petId = randomUUID();
    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, 'hash', 'Owner', 'User'),
              ($3, $4, 'hash', 'Collab', 'User')`,
      [ownerId, `owner-${ownerId}@example.com`, collabId, `collab-${collabId}@example.com`],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'Buddy', 'dog')`,
      [petId, ownerId],
    );
    await pool.query(
      `INSERT INTO pet_access (id, pet_id, user_id, role, hidden)
       VALUES ($1, $2, $3, 'carer', false)`,
      [randomUUID(), petId, collabId],
    );

    const first = await notifyPassedAwayCollaborators(pool, {
      petId,
      ownerId,
      petName: 'Buddy',
    });
    expect(first).toMatchObject({
      notified_count: 1,
      already_notified_count: 0,
      delivery_status: 'delivered',
    });

    const second = await notifyPassedAwayCollaborators(pool, {
      petId,
      ownerId,
      petName: 'Buddy',
    });
    expect(second).toMatchObject({
      notified_count: 0,
      already_notified_count: 1,
      delivery_status: 'already_notified',
    });

    const notifCount = await pool.query(
      'SELECT COUNT(*)::int AS n FROM notifications WHERE pet_id = $1 AND user_id = $2',
      [petId, collabId],
    );
    expect(notifCount.rows[0].n).toBe(1);

    await pool.query('DELETE FROM notifications WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pet_lifecycle_notifications WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pet_access WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id IN ($1, $2)', [ownerId, collabId]);
  });

  it('concurrent POST passed-away dedupes to one collaborator notification', async () => {
    const ownerId = randomUUID();
    const collabId = randomUUID();
    const petId = randomUUID();
    const ownerEmail = `owner-conc-${ownerId}@example.com`;
    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, 'hash', 'Owner', 'User'),
              ($3, $4, 'hash', 'Collab', 'User')`,
      [ownerId, ownerEmail, collabId, `collab-${collabId}@example.com`],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'Buddy', 'dog')`,
      [petId, ownerId],
    );
    await pool.query(
      `INSERT INTO pet_access (id, pet_id, user_id, role, hidden)
       VALUES ($1, $2, $3, 'carer', false)`,
      [randomUUID(), petId, collabId],
    );
    const token = jwt.sign({ id: ownerId, email: ownerEmail }, JWT_SECRET, {
      expiresIn: '1h',
    });
    const concurrentApp = createApp(pool);

    const [firstRes, secondRes] = await Promise.all([
      request(concurrentApp)
        .post(`/api/pets/${petId}/passed-away`)
        .set('Authorization', `Bearer ${token}`)
        .send({}),
      request(concurrentApp)
        .post(`/api/pets/${petId}/passed-away`)
        .set('Authorization', `Bearer ${token}`)
        .send({}),
    ]);
    expect(firstRes.status).toBe(200);
    expect(secondRes.status).toBe(200);
    expect(
      firstRes.body.notified_count + secondRes.body.notified_count,
    ).toBe(1);
    expect(
      firstRes.body.already_notified_count + secondRes.body.already_notified_count,
    ).toBe(1);

    const notifCount = await pool.query(
      'SELECT COUNT(*)::int AS n FROM notifications WHERE pet_id = $1 AND user_id = $2',
      [petId, collabId],
    );
    expect(notifCount.rows[0].n).toBe(1);

    await pool.query('DELETE FROM notifications WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pet_lifecycle_notifications WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pet_access WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id IN ($1, $2)', [ownerId, collabId]);
  });

  it('POST passed-away does not modify the pets row', async () => {
    const ownerId = randomUUID();
    const petId = randomUUID();
    await seedUserPet(pool, { userId: ownerId, petId });
    const before = await pool.query('SELECT * FROM pets WHERE id = $1', [petId]);

    await notifyPassedAwayCollaborators(pool, {
      petId,
      ownerId,
      petName: 'LifePet',
    });

    const after = await pool.query('SELECT * FROM pets WHERE id = $1', [petId]);
    expect(after.rows[0]).toEqual(before.rows[0]);

    await pool.query('DELETE FROM pet_lifecycle_notifications WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = $1', [ownerId]);
  });
});
