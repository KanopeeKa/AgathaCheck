import { randomUUID } from 'crypto';
import fs from 'fs';
import os from 'os';
import path from 'path';

import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createApp } from '../../bin/server.js';
import { createDbPool } from './helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

const JPEG_BUFFER = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
]);

let pool;
let app;
let petPhotoDir;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables WHERE table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('erasureRace integration tests require migrated PostgreSQL');
  }

  petPhotoDir = fs.mkdtempSync(path.join(os.tmpdir(), 'erasure-race-pet-photos-'));
  process.env.PET_PHOTO_UPLOAD_DIR = petPhotoDir;
  app = createApp(pool);
}, 60000);

afterAll(async () => {
  delete process.env.PET_PHOTO_UPLOAD_DIR;
  if (pool) await pool.end();
  if (petPhotoDir) fs.rmSync(petPhotoDir, { recursive: true, force: true });
});

function countPetPhotoFiles() {
  if (!fs.existsSync(petPhotoDir)) return 0;
  return fs.readdirSync(petPhotoDir).length;
}

function startPetPhotoUpload(petId, token) {
  return new Promise((resolve, reject) => {
    request(app)
      .post(`/api/pets/${petId}/photo`)
      .set('Authorization', `Bearer ${token}`)
      .attach('photo', JPEG_BUFFER, { filename: 'race.jpg', contentType: 'image/jpeg' })
      .end((err, res) => (err ? reject(err) : resolve(res)));
  });
}

describe('upload vs erasure row locks (real PG)', () => {
  it('removes pet photo file when UPDATE races user deletion', async () => {
    const userId = randomUUID();
    const petId = randomUUID();
    const email = `race-${userId}@example.com`;
    const passwordHash = await bcrypt.hash('RaceTest123!', 10);
    await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name)
       VALUES ($1, $2, $3, 'Race', 'Tester')`,
      [userId, email, passwordHash],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species, home_timezone) VALUES ($1, $2, 'P', 'dog', 'UTC')`,
      [petId, userId],
    );
    const token = jwt.sign({ id: userId, email, typ: 'access' }, JWT_SECRET, { expiresIn: '1h' });

    const locker = await pool.connect();
    const filesBefore = countPetPhotoFiles();

    try {
      await locker.query('BEGIN');
      await locker.query('SELECT id FROM pets WHERE id = $1 FOR UPDATE', [petId]);

      const uploadPromise = startPetPhotoUpload(petId, token);

      for (let i = 0; i < 100; i += 1) {
        if (countPetPhotoFiles() > filesBefore) break;
        await new Promise((resolve) => setTimeout(resolve, 25));
      }
      expect(countPetPhotoFiles()).toBeGreaterThan(filesBefore);

      await locker.query('DELETE FROM users WHERE id = $1', [userId]);
      await locker.query('COMMIT');
      locker.release();

      const res = await uploadPromise;

      expect(res.status).toBe(404);
      expect(countPetPhotoFiles()).toBe(filesBefore);
    } finally {
      try {
        await locker.query('ROLLBACK');
      } catch {
        // ignore
      }
      try {
        locker.release();
      } catch {
        // ignore
      }
      await pool.query('DELETE FROM users WHERE id = $1', [userId]).catch(() => {});
    }
  });
});
