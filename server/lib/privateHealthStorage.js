/**
 * Private storage for health documents and entry photos (F-01).
 * Files are not web-accessible; bytes stream via GET /api/health-files/:id.
 */
import fs from 'fs';
import path from 'path';

import {
  assertServerFileId,
  resolvePathUnderRoot,
  saveUploadedFile,
} from './safeUpload.js';

export const MAX_HEALTH_DOCUMENT_BYTES = 2 * 1024 * 1024;
export const HEALTH_DOCUMENT_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.pdf']);
export const HEALTH_DOCUMENT_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'application/pdf',
]);

const HEALTH_FILE_API_PREFIX = '/api/health-files/';
const LEGACY_HEALTH_PREFIXES = [
  '/uploads/health_documents/',
  '/uploads/health_photos/',
];

const KNOWN_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.pdf', '.webp'];

const EXT_TO_MIME = Object.freeze({
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
});

export function privateHealthDir() {
  if (process.env.PRIVATE_HEALTH_UPLOAD_DIR) {
    return path.resolve(process.env.PRIVATE_HEALTH_UPLOAD_DIR);
  }
  return path.resolve(process.cwd(), 'uploads', 'private_health');
}

/** @deprecated Use privateHealthDir — kept for migration from HEALTH_UPLOAD_DIR */
export function legacyHealthUploadDirs() {
  const root = path.resolve(process.cwd(), 'uploads');
  const dirs = [
    process.env.HEALTH_UPLOAD_DIR
      ? path.resolve(process.env.HEALTH_UPLOAD_DIR)
      : path.join(root, 'health_documents'),
    path.join(root, 'health_photos'),
  ];
  return [...new Set(dirs)];
}

export function buildHealthFileApiPath(fileId) {
  assertServerFileId(fileId);
  return `${HEALTH_FILE_API_PREFIX}${fileId}`;
}

export function parseHealthFileIdFromUrl(url) {
  if (!url || typeof url !== 'string') return null;
  if (url.startsWith(HEALTH_FILE_API_PREFIX)) {
    const id = url.slice(HEALTH_FILE_API_PREFIX.length).split('?')[0];
    try {
      assertServerFileId(id);
      return id;
    } catch {
      return null;
    }
  }
  for (const prefix of LEGACY_HEALTH_PREFIXES) {
    if (!url.startsWith(prefix)) continue;
    const filename = url.slice(prefix.length);
    const base = path.basename(filename, path.extname(filename));
    try {
      return assertServerFileId(base);
    } catch {
      return null;
    }
  }
  return null;
}

export function savePrivateHealthFile(file, fileId) {
  const dir = privateHealthDir();
  const { filename } = saveUploadedFile({
    buffer: file.buffer,
    mimeType: file.mimetype,
    fileId,
    rootDir: dir,
    allowedExtensions: HEALTH_DOCUMENT_EXTENSIONS,
    maxBytes: MAX_HEALTH_DOCUMENT_BYTES,
  });
  return { apiPath: buildHealthFileApiPath(fileId), filename };
}

/**
 * Resolve on-disk path for a health file id (private dir, then legacy dirs).
 * @returns {{ filePath: string, mimeType: string } | null}
 */
export function resolvePrivateHealthFile(fileId) {
  try {
    assertServerFileId(fileId);
  } catch {
    return null;
  }

  const searchRoots = [privateHealthDir(), ...legacyHealthUploadDirs()];
  for (const root of searchRoots) {
    if (!fs.existsSync(root)) continue;
    for (const ext of KNOWN_EXTENSIONS) {
      const filename = `${fileId}${ext}`;
      try {
        const filePath = resolvePathUnderRoot(root, filename);
        if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
          return { filePath, mimeType: EXT_TO_MIME[ext] || 'application/octet-stream' };
        }
      } catch {
        // try next extension
      }
    }
  }
  return null;
}

/** Best-effort removal by API path, legacy URL, or raw file id. */
export function removePrivateHealthFile(urlOrId) {
  if (!urlOrId || typeof urlOrId !== 'string') return;

  const fileId = parseHealthFileIdFromUrl(urlOrId) || (
    /^[0-9a-f-]{36}$/i.test(urlOrId) ? urlOrId : null
  );
  if (fileId) {
    _removeHealthFileById(fileId);
    return;
  }

  for (const prefix of LEGACY_HEALTH_PREFIXES) {
    if (!urlOrId.startsWith(prefix)) continue;
    const filename = urlOrId.slice(prefix.length);
    if (!filename || filename.includes('/') || filename.includes('\\')) return;
    for (const root of legacyHealthUploadDirs()) {
      try {
        const filePath = resolvePathUnderRoot(root, filename);
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
      } catch {
        // ignore
      }
    }
    return;
  }
}

function _removeHealthFileById(fileId) {
  const searchRoots = [privateHealthDir(), ...legacyHealthUploadDirs()];
  for (const root of searchRoots) {
    if (!fs.existsSync(root)) continue;
    for (const ext of KNOWN_EXTENSIONS) {
      try {
        const filePath = resolvePathUnderRoot(root, `${fileId}${ext}`);
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
      } catch {
        // ignore
      }
    }
  }
}
