/**
 * Safe server-side persistence for multer memory uploads.
 * Extensions come from MIME type (never client originalname). Paths are
 * resolved under a fixed root with a traversal guard (CodeQL path-injection).
 */
import fs from 'fs';
import path from 'path';

const MIME_TO_EXT = Object.freeze({
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'application/pdf': '.pdf',
});

export function extensionForMime(mimeType, allowedExtensions) {
  const ext = MIME_TO_EXT[mimeType];
  if (!ext || !allowedExtensions.has(ext)) {
    throw new Error('Unsupported file type');
  }
  return ext;
}

export function resolvePathUnderRoot(rootDir, filename) {
  if (!filename || filename.includes('/') || filename.includes('\\') || filename.includes('\0')) {
    throw new Error('Invalid upload filename');
  }
  const root = path.resolve(rootDir);
  const resolved = path.resolve(root, filename);
  const prefix = root.endsWith(path.sep) ? root : `${root}${path.sep}`;
  if (resolved !== root && !resolved.startsWith(prefix)) {
    throw new Error('Invalid upload path');
  }
  return resolved;
}

/**
 * @param {{ buffer: Buffer, mimeType: string, filenameStem: string, rootDir: string, allowedExtensions: Set<string>, fileMode?: number }} opts
 */
export function saveUploadedFile({
  buffer,
  mimeType,
  filenameStem,
  rootDir,
  allowedExtensions,
  fileMode = 0o600,
}) {
  const ext = extensionForMime(mimeType, allowedExtensions);
  const filename = `${filenameStem}${ext}`;
  const dir = path.resolve(rootDir);
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  const filePath = resolvePathUnderRoot(dir, filename);
  fs.writeFileSync(filePath, buffer, { mode: fileMode });
  return { filename, filePath };
}
