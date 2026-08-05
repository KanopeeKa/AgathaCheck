import fs from 'fs';
import os from 'os';
import path from 'path';
import request from 'supertest';
import { v4 as uuidv4 } from 'uuid';

import { createApp } from '../bin/server.js';
import { resolvePublicUploadFile } from '../lib/servePublicUpload.js';

describe('public upload serving', () => {
  let tmpDir;
  let prevCwd;

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'public-upload-'));
    prevCwd = process.cwd();
    process.chdir(tmpDir);
    fs.mkdirSync(path.join(tmpDir, 'uploads', 'org_photos'), { recursive: true });
  });

  afterEach(() => {
    process.chdir(prevCwd);
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it('resolves a confined org photo path', () => {
    const fileId = uuidv4();
    const filename = `${fileId}.jpg`;
    const filePath = path.join(tmpDir, 'uploads', 'org_photos', filename);
    fs.writeFileSync(filePath, Buffer.from('jpeg'));

    const resolved = resolvePublicUploadFile(`org_photos/${filename}`);
    expect(resolved.filePath).toBe(fs.realpathSync(filePath));
    expect(resolved.mimeType).toBe('image/jpeg');
  });

  it('rejects path traversal', () => {
    expect(() => resolvePublicUploadFile('../outside.jpg')).toThrow(/Not found/);
    expect(() => resolvePublicUploadFile('org_photos/../../etc/passwd')).toThrow(/Not found/);
  });

  it('rejects unknown subdirectories', () => {
    expect(() => resolvePublicUploadFile('secrets/file.jpg')).toThrow(/Not found/);
  });

  it('serves files via GET /api/uploads', async () => {
    const fileId = uuidv4();
    const filename = `${fileId}.png`;
    const filePath = path.join(tmpDir, 'uploads', 'org_logos', filename);
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, Buffer.from([0x89, 0x50, 0x4e, 0x47]));

    const app = createApp();
    const res = await request(app).get(`/api/uploads/org_logos/${filename}`);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/image\/png/);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it('serves files via GET /backend/api/uploads', async () => {
    const fileId = uuidv4();
    const filename = `${fileId}.jpg`;
    const filePath = path.join(tmpDir, 'uploads', 'org_photos', filename);
    fs.writeFileSync(filePath, Buffer.from('jpeg'));

    const app = createApp();
    const res = await request(app).get(`/backend/api/uploads/org_photos/${filename}`);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/image\/jpeg/);
  });

  it('returns 404 for missing files', async () => {
    const app = createApp();
    const fileId = uuidv4();
    const res = await request(app).get(`/api/uploads/org_photos/${fileId}.jpg`);

    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: 'Not found' });
  });
});
