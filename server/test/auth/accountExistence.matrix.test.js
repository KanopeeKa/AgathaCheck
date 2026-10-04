import { randomUUID } from 'crypto';
import fs from 'fs';
import os from 'os';
import path from 'path';

import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createApp } from '../../bin/server.js';
import { applyAccountErasureMigration } from '../db/helpers/accountErasureSql.js';
import { applyCleanupJobsMigration } from '../db/helpers/cleanupJobsSql.js';
import { createDbPool } from '../db/helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

const JPEG_BUFFER = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
]);

let pool;
let app;
let uploadRoot;
let petPhotoDir;
let healthUploadDir;

async function createUserWithPet(password = 'EraseMe123!') {
  const userId = randomUUID();
  const petId = randomUUID();
  const email = `matrix-${userId}@example.com`;
  const passwordHash = await bcrypt.hash(password, 10);
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, $3, 'Matrix', 'Tester')`,
    [userId, email, passwordHash],
  );
  await pool.query(
    `INSERT INTO pets (id, user_id, name, species, home_timezone) VALUES ($1, $2, 'P', 'dog', 'UTC')`,
    [petId, userId],
  );
  const entryId = randomUUID();
  await pool.query(
    `INSERT INTO health_entries
       (id, pet_id, user_id, name, type, status, care_family, care_planning, care_importance, next_due_date)
     VALUES ($1, $2, $3, 'Check', 'vet_visit', 'active', 'wellness_review', 'planned', 'essential', '2030-01-01')`,
    [entryId, petId, userId],
  );
  const token = jwt.sign({ id: userId, email, typ: 'access' }, JWT_SECRET, { expiresIn: '1h' });
  return { userId, petId, entryId, email, token, password };
}

function countFiles(dir) {
  if (!fs.existsSync(dir)) return 0;
  return fs.readdirSync(dir).filter((f) => !f.startsWith('.')).length;
}

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables WHERE table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('accountExistence matrix tests require migrated PostgreSQL');
  }
  await applyCleanupJobsMigration(pool).catch(() => {});
  await applyAccountErasureMigration(pool).catch(() => {});

  uploadRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'matrix-uploads-'));
  petPhotoDir = path.join(uploadRoot, 'pet_photos');
  healthUploadDir = path.join(uploadRoot, 'private_health');
  fs.mkdirSync(petPhotoDir, { recursive: true });
  fs.mkdirSync(healthUploadDir, { recursive: true });
  process.env.PET_PHOTO_UPLOAD_DIR = petPhotoDir;
  process.env.PRIVATE_HEALTH_UPLOAD_DIR = healthUploadDir;

  app = createApp(pool);
}, 60000);

afterAll(async () => {
  delete process.env.PET_PHOTO_UPLOAD_DIR;
  delete process.env.PRIVATE_HEALTH_UPLOAD_DIR;
  if (pool) await pool.end();
  if (uploadRoot) fs.rmSync(uploadRoot, { recursive: true, force: true });
});

describe('account_unavailable matrix (real PG)', () => {
  const apiPrefixes = ['/api', '/backend/api'];

  apiPrefixes.forEach((prefix) => {
    describe(prefix, () => {
      it('rejects pre-erasure token on pets, health create, and uploads without writing files', async () => {
        const { userId, petId, entryId, token, password } = await createUserWithPet();

        const del = await request(app)
          .delete(`${prefix}/auth/me`)
          .set('Authorization', `Bearer ${token}`)
          .send({ password });
        expect(del.status).toBe(202);

        const petFilesBefore = countFiles(petPhotoDir);
        const healthFilesBefore = countFiles(healthUploadDir);

        const auth = { Authorization: `Bearer ${token}` };

        const pets = await request(app).get(`${prefix}/pets`).set(auth);
        expect(pets.status).toBe(401);
        expect(pets.body.code).toBe('account_unavailable');

        const createEntry = await request(app)
          .post(`${prefix}/health-entries`)
          .set(auth)
          .send({
            pet_id: petId,
            name: 'Blocked',
            type: 'preventive',
            care_family: 'parasite_prevention',
            next_due_date: '2026-01-01',
          });
        expect(createEntry.status).toBe(401);
        expect(createEntry.body.code).toBe('account_unavailable');

        const petPhoto = await request(app)
          .post(`${prefix}/pets/${petId}/photo`)
          .set(auth)
          .attach('photo', JPEG_BUFFER, { filename: 'x.jpg', contentType: 'image/jpeg' });
        expect(petPhoto.status).toBe(401);
        expect(petPhoto.body.code).toBe('account_unavailable');

        const healthPhoto = await request(app)
          .post(`${prefix}/health-entries/${entryId}/photos`)
          .set(auth)
          .attach('photo', JPEG_BUFFER, { filename: 'doc.jpg', contentType: 'image/jpeg' });
        expect(healthPhoto.status).toBe(401);
        expect(healthPhoto.body.code).toBe('account_unavailable');

        expect(countFiles(petPhotoDir)).toBe(petFilesBefore);
        expect(countFiles(healthUploadDir)).toBe(healthFilesBefore);

        const user = await pool.query('SELECT 1 FROM users WHERE id = $1', [userId]);
        expect(user.rows).toHaveLength(0);
      });
    });
  });
});
