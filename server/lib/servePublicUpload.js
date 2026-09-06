/**
 * Serve persisted upload files through the API (Passenger-safe on UAT).
 * Apache blocks direct GETs under /backend/uploads; this route reads files
 * from the confined uploads tree with the same path rules as persistence.
 */
import fs from 'fs';
import path from 'path';

const PUBLIC_UPLOAD_SUBDIRS = new Set([
  'org_photos',
  'org_logos',
  'photos',
]);

const SAFE_FILENAME = /^[0-9a-zA-Z][0-9a-zA-Z._-]*\.(jpg|jpeg|png|webp|pdf)$/i;

const EXT_TO_MIME = Object.freeze({
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
});

function defaultUploadsRoot() {
  return path.resolve(process.cwd(), 'uploads');
}

/** Match persistence paths in route shared modules (env overrides). */
function resolveUploadDir(subdir) {
  if (subdir === 'org_photos' || subdir === 'org_logos') {
    if (process.env.ORG_UPLOAD_DIR) {
      return path.resolve(process.env.ORG_UPLOAD_DIR);
    }
    return path.resolve(defaultUploadsRoot(), subdir);
  }
  if (subdir === 'photos') {
    return path.resolve(defaultUploadsRoot(), 'photos');
  }
  return defaultUploadsRoot();
}

function mimeForFilename(filename) {
  const ext = path.extname(filename).toLowerCase();
  return EXT_TO_MIME[ext] || 'application/octet-stream';
}

/**
 * @param {string} relativePath path after /uploads/ (e.g. org_photos/uuid.jpg)
 * @returns {{ filePath: string, mimeType: string }}
 */
export function resolvePublicUploadFile(relativePath) {
  if (!relativePath || typeof relativePath !== 'string') {
    throw new Error('Not found');
  }

  const normalized = relativePath.replace(/\\/g, '/').replace(/^\/+/, '');
  const segments = normalized.split('/').filter(Boolean);
  if (!segments.length || segments.some((s) => s === '.' || s === '..')) {
    throw new Error('Not found');
  }

  let subdir = null;
  let filename;
  if (segments.length === 1) {
    [filename] = segments;
  } else if (segments.length === 2) {
    [subdir, filename] = segments;
    if (!PUBLIC_UPLOAD_SUBDIRS.has(subdir)) {
      throw new Error('Not found');
    }
  } else {
    throw new Error('Not found');
  }

  if (!SAFE_FILENAME.test(filename) || filename.startsWith('.')) {
    throw new Error('Not found');
  }

  const dir = subdir ? resolveUploadDir(subdir) : defaultUploadsRoot();
  if (!fs.existsSync(dir)) {
    throw new Error('Not found');
  }

  const safeRoot = fs.realpathSync(dir);
  const prefix = safeRoot.endsWith(path.sep) ? safeRoot : `${safeRoot}${path.sep}`;
  const filePath = path.resolve(safeRoot, filename);
  if (filePath !== safeRoot && !filePath.startsWith(prefix)) {
    throw new Error('Not found');
  }
  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    throw new Error('Not found');
  }

  return { filePath, mimeType: mimeForFilename(filename) };
}

/**
 * @param {string} relativePath
 * @param {import('express').Response} res
 */
export function sendPublicUpload(relativePath, res) {
  try {
    const { filePath, mimeType } = resolvePublicUploadFile(relativePath);
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'public, max-age=86400, immutable');
    res.sendFile(filePath);
  } catch {
    res.status(404).json({ error: 'Not found' });
  }
}
