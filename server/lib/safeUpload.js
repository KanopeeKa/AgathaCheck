/**
 * Safe server-side persistence for multer memory uploads.
 * Filenames are server UUIDs plus a MIME-derived extension literal.
 * Paths are confined under a fixed root (realpath + prefix guard).
 */
import fs from 'fs';
import path from 'path';

export const DEFAULT_MAX_UPLOAD_BYTES = 2 * 1024 * 1024;

const UPLOAD_FILE_ID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const MIME_TO_EXT = Object.freeze({
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'application/pdf': '.pdf',
});

/** Allowed MIME keys for switch-based extension resolution. */
export const SUPPORTED_UPLOAD_MIMES = new Set(Object.keys(MIME_TO_EXT));

/** @param {string} fileId server-generated UUID */
export function assertServerFileId(fileId) {
  if (typeof fileId !== 'string' || !UPLOAD_FILE_ID.test(fileId)) {
    throw new Error('Invalid upload file id');
  }
  return fileId;
}

export function extensionForMime(mimeType, allowedExtensions) {
  let ext;
  switch (mimeType) {
    case 'image/jpeg':
      ext = '.jpg';
      break;
    case 'image/png':
      ext = '.png';
      break;
    case 'image/webp':
      ext = '.webp';
      break;
    case 'application/pdf':
      ext = '.pdf';
      break;
    default:
      throw new Error('Unsupported file type');
  }
  if (!allowedExtensions.has(ext)) {
    throw new Error('Unsupported file type');
  }
  return ext;
}

function assertUploadBuffer(buffer, maxBytes) {
  if (!Buffer.isBuffer(buffer) || buffer.length === 0 || buffer.length > maxBytes) {
    throw new Error('Invalid upload payload');
  }
}

/**
 * Resolve a confined path for a new upload file under rootDir.
 * Uses realpath on the upload root (CodeQL path-injection guidance).
 */
export function resolveConfinedUploadPath(rootDir, fileId, extension) {
  const safeId = assertServerFileId(fileId);
  if (!extension || !/^\.\w+$/.test(extension)) {
    throw new Error('Invalid upload extension');
  }
  const filename = `${safeId}${extension}`;
  if (filename.includes('/') || filename.includes('\\')) {
    throw new Error('Invalid upload filename');
  }

  const dir = path.resolve(rootDir);
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  const safeRoot = fs.realpathSync(dir);
  const prefix = safeRoot.endsWith(path.sep) ? safeRoot : `${safeRoot}${path.sep}`;
  const filePath = path.resolve(safeRoot, filename);
  if (filePath !== safeRoot && !filePath.startsWith(prefix)) {
    throw new Error('Invalid upload path');
  }
  return { filename, filePath, safeRoot };
}

/** @deprecated Use resolveConfinedUploadPath — kept for unit tests */
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
 * @param {{ buffer: Buffer, mimeType: string, fileId: string, rootDir: string, allowedExtensions: Set<string>, fileMode?: number, maxBytes?: number }} opts
 */
export function saveUploadedFile({
  buffer,
  mimeType,
  fileId,
  rootDir,
  allowedExtensions,
  fileMode = 0o600,
  maxBytes = DEFAULT_MAX_UPLOAD_BYTES,
}) {
  const ext = extensionForMime(mimeType, allowedExtensions);
  const { filename, filePath } = resolveConfinedUploadPath(rootDir, fileId, ext);
  assertUploadBuffer(buffer, maxBytes);
  // Validated multipart upload: MIME allowlist (multer) + size cap + confined path.
  // codeql[js/path-injection]: fileId is server UUID; extension from MIME allowlist switch; path under realpath root
  // codeql[js/http-to-file-access]: intentional persistence of vetted upload bytes
  fs.writeFileSync(filePath, buffer, { mode: fileMode, flag: 'wx' });
  return { filename, filePath };
}
