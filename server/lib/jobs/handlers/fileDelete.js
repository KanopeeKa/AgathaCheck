import fs from 'fs';
import path from 'path';

import { privateHealthDir } from '../../privateHealthStorage.js';
import { resolvePathUnderRoot } from '../../safeUpload.js';

const UPLOADS_ROOT = () => path.resolve(process.cwd(), 'uploads');

function uploadsRootForStorage(storage) {
  if (storage === 'private_health') {
    return privateHealthDir();
  }
  if (storage === 'uploads') {
    return UPLOADS_ROOT();
  }
  return null;
}

function validateRelativePath(relativePath) {
  if (typeof relativePath !== 'string' || !relativePath.length) {
    return { ok: false, retryable: false, message: 'missing relative_path' };
  }
  if (relativePath.includes('\0')) {
    return { ok: false, retryable: false, message: 'invalid relative_path' };
  }
  if (path.isAbsolute(relativePath)) {
    return { ok: false, retryable: false, message: 'absolute path rejected' };
  }
  const normalized = path.posix.normalize(relativePath.replace(/\\/g, '/'));
  if (normalized.startsWith('../') || normalized === '..' || normalized.includes('/../')) {
    return { ok: false, retryable: false, message: 'path traversal rejected' };
  }
  return { ok: true, normalized };
}

function resolveUnderRoot(rootDir, relativePath) {
  const segments = relativePath.split('/').filter(Boolean);
  let current = path.resolve(rootDir);
  const rootReal = fs.existsSync(current) ? fs.realpathSync(current) : current;
  const prefix = rootReal.endsWith(path.sep) ? rootReal : `${rootReal}${path.sep}`;

  for (const segment of segments) {
    if (segment === '.' || segment === '..') {
      throw new Error('path traversal rejected');
    }
    current = path.join(current, segment);
  }

  let resolved = path.resolve(current);
  if (fs.existsSync(resolved)) {
    resolved = fs.realpathSync(resolved);
  }
  if (resolved !== rootReal && !resolved.startsWith(prefix)) {
    throw new Error('path outside storage root');
  }
  return resolved;
}

/**
 * @param {object} payload
 * @returns {Promise<{ retryable: boolean, message?: string }>}
 */
export async function runFileDeleteJob(payload) {
  const storage = payload?.storage;
  const root = uploadsRootForStorage(storage);
  if (!root) {
    return { retryable: false, message: 'unsupported storage' };
  }

  const pathCheck = validateRelativePath(payload?.relative_path);
  if (!pathCheck.ok) {
    return { retryable: pathCheck.retryable, message: pathCheck.message };
  }

  let filePath;
  try {
    if (pathCheck.normalized.includes('/')) {
      filePath = resolveUnderRoot(root, pathCheck.normalized);
    } else {
      filePath = resolvePathUnderRoot(root, pathCheck.normalized);
    }
  } catch (err) {
    return { retryable: false, message: err.message || 'invalid path' };
  }

  try {
    await fs.promises.unlink(filePath);
    return { retryable: false };
  } catch (err) {
    if (err && err.code === 'ENOENT') {
      return { retryable: false };
    }
    if (err && ['EACCES', 'EPERM', 'EBUSY'].includes(err.code)) {
      return { retryable: true, message: err.message };
    }
    return { retryable: false, message: err?.message || 'unlink failed' };
  }
}
