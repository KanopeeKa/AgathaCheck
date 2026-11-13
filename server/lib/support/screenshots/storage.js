import fs from 'fs';
import path from 'path';

import { v4 as uuidv4 } from 'uuid';

import {
  resolvePathUnderRoot,
  saveUploadedFile,
  validateOrgImageMime,
} from '../../safeUpload.js';
import {
  SUPPORT_SCREENSHOT_EXTENSIONS,
  SUPPORT_SCREENSHOT_MAX_BYTES_PER_FILE,
  SUPPORT_SCREENSHOT_STORAGE,
} from './constants.js';

/** Private support screenshots live outside the public uploads tree (R-008). */
export function supportScreenshotDir() {
  if (process.env.PRIVATE_SUPPORT_SCREENSHOT_DIR) {
    return path.resolve(process.env.PRIVATE_SUPPORT_SCREENSHOT_DIR);
  }
  return path.resolve(process.cwd(), 'private_support_screenshots');
}

/**
 * @param {string} filename
 * @returns {string}
 */
export function buildSupportScreenshotStorageKey(filename) {
  return JSON.stringify({
    storage: SUPPORT_SCREENSHOT_STORAGE,
    relative_path: filename,
  });
}

/**
 * @param {string} storageKey
 * @returns {{ storage: string, relative_path: string } | null}
 */
export function parseSupportScreenshotStorageKey(storageKey) {
  if (!storageKey || typeof storageKey !== 'string') return null;
  try {
    const parsed = JSON.parse(storageKey);
    if (
      parsed?.storage === SUPPORT_SCREENSHOT_STORAGE &&
      typeof parsed.relative_path === 'string' &&
      parsed.relative_path.length > 0
    ) {
      return parsed;
    }
  } catch {
  }
  return null;
}

/**
 * @param {{ buffer: Buffer, mimetype?: string }} file
 * @returns {{ attachmentId: string, storage_key: string, mime: string, bytes: number, filename: string }}
 */
export function saveSupportScreenshotFile(file) {
  const attachmentId = uuidv4();
  const mimeType = validateOrgImageMime(
    file.mimetype,
    file.buffer,
    SUPPORT_SCREENSHOT_EXTENSIONS,
  );
  const { filename } = saveUploadedFile({
    buffer: file.buffer,
    mimeType,
    fileId: attachmentId,
    rootDir: supportScreenshotDir(),
    allowedExtensions: SUPPORT_SCREENSHOT_EXTENSIONS,
    maxBytes: SUPPORT_SCREENSHOT_MAX_BYTES_PER_FILE,
  });
  return {
    attachmentId,
    storage_key: buildSupportScreenshotStorageKey(filename),
    mime: mimeType,
    bytes: file.buffer.length,
    filename,
  };
}

/**
 * @param {string} storageKey
 * @returns {{ filePath: string, mime: string } | null}
 */
export function resolveSupportScreenshotFile(storageKey) {
  const parsed = parseSupportScreenshotStorageKey(storageKey);
  if (!parsed) return null;
  const root = supportScreenshotDir();
  try {
    const filePath = resolvePathUnderRoot(root, parsed.relative_path);
    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      return null;
    }
    const ext = path.extname(parsed.relative_path).toLowerCase();
    const extToMime = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
    };
    const mime = extToMime[ext];
    if (!mime) return null;
    return { filePath, mime };
  } catch {
    return null;
  }
}

/** Best-effort unlink when a DB transaction rolls back after a disk write. */
export function removeSupportScreenshotFile(storageKey) {
  const parsed = parseSupportScreenshotStorageKey(storageKey);
  if (!parsed) return;
  const root = supportScreenshotDir();
  try {
    const filePath = resolvePathUnderRoot(root, parsed.relative_path);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  } catch {
    // ignore
  }
}
