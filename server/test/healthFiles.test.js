import fs from 'fs';
import os from 'os';
import path from 'path';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

import { createApp } from '../bin/server.js';
import {
  buildHealthFileApiPath,
  privateHealthDir,
  savePrivateHealthFile,
} from '../lib/privateHealthStorage.js';
import { resolvePublicUploadFile } from '../lib/servePublicUpload.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const ownerId = 'owner-user';
const otherId = 'other-user';
const petId = 'pet-1';
const fileId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const ownerToken = jwt.sign({ id: ownerId, email: 'owner@test.com' }, JWT_SECRET, { expiresIn: '1h' });
const otherToken = jwt.sign({ id: otherId, email: 'other@test.com' }, JWT_SECRET, { expiresIn: '1h' });

function mockPoolForHealthFile() {
  return {
    query: async (sql, params = []) => {
      if (sql.includes('FROM health_issue_documents hid')) {
        if (params[0] === fileId) {
          return { rows: [{ pet_id: petId }] };
        }
        return { rows: [] };
      }
      if (sql.includes('FROM health_event_photos hep')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
        const [pid, uid] = params;
        if (pid === petId && uid === ownerId) return { rows: [{ '?column?': 1 }] };
        return { rows: [] };
      }
      if (sql.startsWith('SELECT 1 FROM pet_access')) {
        return { rows: [] };
      }
      if (sql.includes('FROM organization_users')) {
        return { rows: [] };
      }
      return { rows: [] };
    },
    end: async () => {},
  };
}

describe('private health files (F-01)', () => {
  let tmpDir;
  let prevCwd;

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'private-health-'));
    prevCwd = process.cwd();
    process.chdir(tmpDir);
    fs.mkdirSync(privateHealthDir(), { recursive: true });
  });

  afterEach(() => {
    process.chdir(prevCwd);
    delete process.env.PRIVATE_HEALTH_UPLOAD_DIR;
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it('rejects health_documents via public upload resolver', () => {
    expect(() => resolvePublicUploadFile('health_documents/test.jpg')).toThrow(/Not found/);
  });

  it('blocks GET /uploads/health_documents/*', async () => {
    const legacyDir = path.join(tmpDir, 'uploads', 'health_documents');
    fs.mkdirSync(legacyDir, { recursive: true });
    fs.writeFileSync(path.join(legacyDir, 'secret.jpg'), Buffer.from('secret'));

    const app = createApp();
    const res = await request(app).get('/uploads/health_documents/secret.jpg');
    expect(res.status).toBe(404);
  });

  it('returns 401 for health-files without auth', async () => {
    const app = createApp(mockPoolForHealthFile());
    const res = await request(app).get(`/api/health-files/${fileId}`);
    expect(res.status).toBe(401);
  });

  it('streams bytes for authorized owner', async () => {
    const buffer = Buffer.from([0xff, 0xd8, 0xff, 0x00]);
    savePrivateHealthFile(
      { buffer, mimetype: 'image/jpeg' },
      fileId
    );

    const app = createApp(mockPoolForHealthFile());
    const res = await request(app)
      .get(`/api/health-files/${fileId}`)
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/image\/jpeg/);
    expect(res.headers['cache-control']).toMatch(/private/);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it('returns 404 for unrelated user', async () => {
    savePrivateHealthFile(
      { buffer: Buffer.from([0xff, 0xd8, 0xff]), mimetype: 'image/jpeg' },
      fileId
    );

    const app = createApp(mockPoolForHealthFile());
    const res = await request(app)
      .get(`/api/health-files/${fileId}`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(404);
  });

  it('saveHealthDocument returns API path', () => {
    const id = uuidv4();
    expect(buildHealthFileApiPath(id)).toBe(`/api/health-files/${id}`);
  });
});
