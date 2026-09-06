import fs from 'fs';
import os from 'os';
import path from 'path';

import request from 'supertest';

import { createApp } from '../../bin/server.js';
import {
  deleteAllPetData,
  notifyPassedAwayCollaborators,
  purgePetFiles,
} from '../../lib/petDataLifecycle.js';
import { privateHealthDir, savePrivateHealthFile } from '../../lib/privateHealthStorage.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, petId, token, userId } from './helpers.js';

describe('petDataLifecycle', () => {
  describe('deleteAllPetData', () => {
    it('deletes pet-related rows and removes health files from disk', async () => {
      const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pet-lifecycle-'));
      const prevDir = process.env.PRIVATE_HEALTH_UPLOAD_DIR;
      process.env.PRIVATE_HEALTH_UPLOAD_DIR = path.join(tmpRoot, 'private_health');
      fs.mkdirSync(process.env.PRIVATE_HEALTH_UPLOAD_DIR, { recursive: true });

      const fileId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
      const buffer = Buffer.from('health-bytes');
      savePrivateHealthFile(
        { buffer, mimetype: 'image/png' },
        fileId,
      );
      const healthUrl = `/api/health-files/${fileId}`;

      const deletedTables = [];
      const pool = {
        query: async (sql, params) => {
          if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
            return { rows: [] };
          }
          if (sql.includes('SELECT photo_path FROM pets')) {
            return { rows: [{ photo_path: null }] };
          }
          if (sql.includes('FROM health_event_photos')) {
            return { rows: [{ url: healthUrl }] };
          }
          if (sql.includes('FROM health_issue_documents')) {
            return { rows: [] };
          }
          if (sql.startsWith('DELETE FROM ')) {
            deletedTables.push(sql);
            return { rowCount: 2 };
          }
          if (sql.includes('UPDATE pets')) {
            return { rows: [] };
          }
          if (sql.includes('INSERT INTO audit_events')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      };

      const result = await deleteAllPetData(pool, petId, { actorUserId: userId });
      expect(result.deleted).toBe(true);
      expect(result.files_removed).toBe(1);
      expect(deletedTables.some((s) => s.includes('health_entries'))).toBe(true);
      expect(deletedTables.some((s) => s.includes('weight_entries'))).toBe(true);
      expect(fs.existsSync(path.join(process.env.PRIVATE_HEALTH_UPLOAD_DIR, `${fileId}.png`))).toBe(false);

      if (prevDir === undefined) delete process.env.PRIVATE_HEALTH_UPLOAD_DIR;
      else process.env.PRIVATE_HEALTH_UPLOAD_DIR = prevDir;
      fs.rmSync(tmpRoot, { recursive: true, force: true });
    });
  });

  describe('notifyPassedAwayCollaborators', () => {
    it('creates notifications for collaborators and returns count', async () => {
      const notifications = [];
      const pool = {
        query: async (sql, params) => {
          if (sql.includes('FROM pet_access pa')) {
            return { rows: [{ user_id: 'collab-1' }, { user_id: 'collab-2' }] };
          }
          if (sql.includes('FROM users WHERE id')) {
            return { rows: [{ first_name: 'Alice', last_name: 'Owner', email: 'a@example.com' }] };
          }
          if (sql.includes('INSERT INTO notifications')) {
            notifications.push(params);
            return { rows: [] };
          }
          return { rows: [] };
        },
      };

      const count = await notifyPassedAwayCollaborators(pool, {
        petId,
        ownerId: userId,
        petName: 'Buddy',
      });
      expect(count).toBe(2);
      expect(notifications).toHaveLength(2);
    });
  });

  describe('purgePetFiles', () => {
    it('removes files without deleting DB rows', async () => {
      const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pet-purge-'));
      process.env.PRIVATE_HEALTH_UPLOAD_DIR = path.join(tmpRoot, 'private_health');
      fs.mkdirSync(process.env.PRIVATE_HEALTH_UPLOAD_DIR, { recursive: true });
      const fileId = 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff';
      savePrivateHealthFile({ buffer: Buffer.from('x'), mimetype: 'image/jpeg' }, fileId);

      const pool = {
        query: async (sql) => {
          if (sql.includes('SELECT photo_path')) return { rows: [{ photo_path: null }] };
          if (sql.includes('health_event_photos')) {
            return { rows: [{ url: `/api/health-files/${fileId}` }] };
          }
          if (sql.includes('health_issue_documents')) return { rows: [] };
          return { rows: [] };
        },
      };

      const removed = await purgePetFiles(pool, petId);
      expect(removed).toBe(1);
      expect(fs.existsSync(path.join(privateHealthDir(), `${fileId}.jpg`))).toBe(false);

      delete process.env.PRIVATE_HEALTH_UPLOAD_DIR;
      fs.rmSync(tmpRoot, { recursive: true, force: true });
    });
  });
});

describe('Pets lifecycle routes', () => {
  it('DELETE /:id/data returns rows_removed when owner deletes pet data', async () => {
    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
      if (sql.includes('SELECT photo_path')) return { rows: [{ photo_path: null }] };
      if (sql.includes('health_event_photos')) return { rows: [] };
      if (sql.includes('health_issue_documents')) return { rows: [] };
      if (sql.startsWith('DELETE FROM ')) return { rowCount: 1 };
      if (sql.includes('UPDATE pets')) return { rows: [] };
      if (sql.includes('INSERT INTO audit_events')) return { rows: [] };
      return { rows: [] };
    });
    const app = createApp(pool);
    const res = await request(app)
      .delete(`/api/pets/${petId}/data`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ deleted: true, pet_id: petId });
    expect(res.body.rows_removed).toBeDefined();
  });

  it('POST /:id/passed-away returns notified_count', async () => {
    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('SELECT name FROM pets')) return { rows: [{ name: 'Fluffy' }] };
      if (sql.includes('FROM pet_access pa')) return { rows: [{ user_id: 'collab-1' }] };
      if (sql.includes('FROM users WHERE id')) {
        return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
      }
      if (sql.includes('INSERT INTO notifications')) return { rows: [] };
      return { rows: [] };
    });
    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/pets/${petId}/passed-away`)
      .set('Authorization', `Bearer ${token}`)
      .send({ pet_name: 'Fluffy' });
    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({
      passed_away: true,
      pet_id: petId,
      notified_count: 1,
    });
  });
});
