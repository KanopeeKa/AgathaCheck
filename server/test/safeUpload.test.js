import fs from 'fs';
import os from 'os';
import path from 'path';

import {
  extensionForMime,
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

  it('rejects path traversal in filename', () => {
    expect(() => resolvePathUnderRoot(tmpDir, '../outside.txt')).toThrow(/Invalid upload/);
    expect(() => resolvePathUnderRoot(tmpDir, '..')).toThrow(/Invalid upload path/);
  });

  it('writes under the upload root with server-chosen name', () => {
    const allowed = new Set(['.jpg']);
    const { filename, filePath } = saveUploadedFile({
      buffer: Buffer.from('data'),
      mimeType: 'image/jpeg',
      filenameStem: 'abc-123',
      rootDir: tmpDir,
      allowedExtensions: allowed,
    });
    expect(filename).toBe('abc-123.jpg');
    expect(fs.existsSync(filePath)).toBe(true);
    expect(filePath.startsWith(path.resolve(tmpDir))).toBe(true);
  });
});
