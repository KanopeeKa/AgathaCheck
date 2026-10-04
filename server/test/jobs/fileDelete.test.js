import fs from 'fs';
import os from 'os';
import path from 'path';

import { afterEach, describe, expect, it } from '@jest/globals';

import { runFileDeleteJob } from '../../lib/jobs/handlers/fileDelete.js';

const roots = [];

function withUploadsRoot(fn) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'cleanup-root-'));
  const uploads = path.join(root, 'uploads');
  fs.mkdirSync(uploads, { recursive: true });
  roots.push(root);
  const prev = process.cwd();
  process.chdir(root);
  try {
    return fn(uploads);
  } finally {
    process.chdir(prev);
  }
}

afterEach(() => {
  for (const root of roots.splice(0)) {
    fs.rmSync(root, { recursive: true, force: true });
  }
  delete process.env.PRIVATE_HEALTH_UPLOAD_DIR;
});

describe('file_delete handler', () => {
  it('deletes an existing file under uploads storage', async () => {
    await withUploadsRoot(async (uploads) => {
      const file = path.join(uploads, 'pet_photos', 'photo.jpg');
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, 'bytes');
      const outcome = await runFileDeleteJob({
        storage: 'uploads',
        relative_path: 'pet_photos/photo.jpg',
      });
      expect(outcome.retryable).toBe(false);
      expect(outcome.message).toBeUndefined();
      expect(fs.existsSync(file)).toBe(false);
    });
  });

  it('treats missing file as success', async () => {
    await withUploadsRoot(async () => {
      const outcome = await runFileDeleteJob({
        storage: 'uploads',
        relative_path: 'missing.jpg',
      });
      expect(outcome).toEqual({ retryable: false });
    });
  });

  it('rejects absolute paths and traversal without unlink', async () => {
    await withUploadsRoot(async (uploads) => {
      const file = path.join(uploads, 'keep.txt');
      fs.writeFileSync(file, 'stay');
      const cases = [
        { storage: 'uploads', relative_path: '/etc/passwd' },
        { storage: 'uploads', relative_path: '../outside.txt' },
        { storage: 'uploads', relative_path: 'a\u0000b' },
      ];
      for (const payload of cases) {
        const outcome = await runFileDeleteJob(payload);
        expect(outcome.retryable).toBe(false);
        expect(outcome.message).toBeDefined();
      }
      expect(fs.existsSync(file)).toBe(true);
    });
  });

  it('rejects symlinks that resolve outside the root', async () => {
    await withUploadsRoot(async (uploads) => {
      const outside = fs.mkdtempSync(path.join(os.tmpdir(), 'outside-'));
      roots.push(outside);
      const outsideFile = path.join(outside, 'secret.txt');
      fs.writeFileSync(outsideFile, 'secret');
      const link = path.join(uploads, 'escape.link');
      fs.symlinkSync(outsideFile, link);
      const outcome = await runFileDeleteJob({
        storage: 'uploads',
        relative_path: 'escape.link',
      });
      expect(outcome.retryable).toBe(false);
      expect(fs.existsSync(outsideFile)).toBe(true);
    });
  });

  it('marks EACCES as retryable', async () => {
    if (process.platform === 'win32') return;
    if (typeof process.getuid === 'function' && process.getuid() === 0) return;
    await withUploadsRoot(async (uploads) => {
      // Unlink needs write on the parent directory; file mode alone is not enough on Linux CI.
      const sub = path.join(uploads, 'lockeddir');
      fs.mkdirSync(sub, { mode: 0o555 });
      const file = path.join(sub, 'locked.txt');
      fs.writeFileSync(file, 'x', { mode: 0o644 });
      const outcome = await runFileDeleteJob({
        storage: 'uploads',
        relative_path: 'lockeddir/locked.txt',
      });
      fs.chmodSync(sub, 0o755);
      if (!outcome.retryable && !fs.existsSync(file)) {
        return; // host allows unlink despite restrictive directory mode
      }
      expect(outcome.retryable).toBe(true);
      expect(fs.existsSync(file)).toBe(true);
    });
  });

  it('deletes under private_health storage', async () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'private-health-'));
    roots.push(root);
    process.env.PRIVATE_HEALTH_UPLOAD_DIR = root;
    const fileId = '00000000-0000-4000-8000-000000000099';
    const file = path.join(root, `${fileId}.jpg`);
    fs.writeFileSync(file, 'health');
    const outcome = await runFileDeleteJob({
      storage: 'private_health',
      relative_path: `${fileId}.jpg`,
    });
    expect(outcome).toEqual({ retryable: false });
    expect(fs.existsSync(file)).toBe(false);
  });
});
