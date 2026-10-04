import { randomUUID } from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import {
  deleteAllPetData,
  deletePet,
  notifyPassedAwayCollaborators,
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

  it('passed-away dedupes notifications on repeat and concurrent POST', async () => {
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
