import fs from 'fs';
import os from 'os';
import path from 'path';

import { afterEach, describe, expect, it } from '@jest/globals';

import { fileRefFromUrl } from '../../lib/petDataLifecycle.js';

describe('fileRefFromUrl', () => {
  const roots = [];
  let prevHealthDir;
  let prevCwd;

  afterEach(() => {
    for (const root of roots) {
      fs.rmSync(root, { recursive: true, force: true });
    }
    roots.length = 0;
    if (prevHealthDir === undefined) delete process.env.HEALTH_UPLOAD_DIR;
    else process.env.HEALTH_UPLOAD_DIR = prevHealthDir;
    if (prevCwd) process.chdir(prevCwd);
  });

  it('schedules legacy health_documents files under uploads storage', () => {
    const workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'pet-cleanup-ref-'));
    roots.push(workDir);
    prevCwd = process.cwd();
    process.chdir(workDir);
    fs.mkdirSync(path.join(workDir, 'uploads', 'health_documents'), { recursive: true });

    const fileId = '00000000-0000-4000-8000-0000000000aa';
    const legacyRel = `health_documents/${fileId}.pdf`;
    fs.writeFileSync(path.join(workDir, 'uploads', legacyRel), '%PDF');

    const ref = fileRefFromUrl(`/uploads/${legacyRel}`);
    expect(ref).toEqual({
      storage: 'uploads',
      relative_path: legacyRel,
      dedupeKey: `file:uploads:${legacyRel}`,
    });
  });
});
