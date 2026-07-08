import fs from 'fs';
import os from 'os';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

import {
  assertServerFileId,
  extensionForMime,
  resolveConfinedUploadPath,
  resolvePathUnderRoot,
  saveUploadedFile,
} from '../lib/safeUpload.js';

describe('safeUpload', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'safe-upload-'));
  });

  afterEach(() => {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it('maps MIME to an allowed extension', () => {
    expect(extensionForMime('image/png', new Set(['.png']))).toBe('.png');
  });

  it('rejects disallowed MIME types', () => {
    expect(() => extensionForMime('application/x-msdownload', new Set(['.png']))).toThrow(
      /Unsupported file type/,
    );
  });

  it('rejects invalid upload file ids', () => {
    expect(() => assertServerFileId('../etc/passwd')).toThrow(/Invalid upload file id/);
    expect(() => assertServerFileId('not-a-uuid')).toThrow(/Invalid upload file id/);
  });

  it('rejects path traversal in filename', () => {
    expect(() => resolvePathUnderRoot(tmpDir, '../outside.txt')).toThrow(/Invalid upload/);
    expect(() => resolvePathUnderRoot(tmpDir, '..')).toThrow(/Invalid upload path/);
  });

  it('confines uploads under the resolved root', () => {
    const fileId = uuidv4();
    const { filename, filePath } = resolveConfinedUploadPath(tmpDir, fileId, '.jpg');
    expect(filename).toBe(`${fileId}.jpg`);
    expect(filePath.startsWith(fs.realpathSync(tmpDir))).toBe(true);
  });

  it('writes under the upload root with server-chosen id', () => {
    const allowed = new Set(['.jpg']);
    const fileId = uuidv4();
    const { filename, filePath } = saveUploadedFile({
      buffer: Buffer.from('data'),
      mimeType: 'image/jpeg',
      fileId,
      rootDir: tmpDir,
      allowedExtensions: allowed,
    });
    expect(filename).toBe(`${fileId}.jpg`);
    expect(fs.existsSync(filePath)).toBe(true);
    expect(filePath.startsWith(fs.realpathSync(tmpDir))).toBe(true);
  });
});
