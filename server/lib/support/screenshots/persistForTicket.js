import {
  removeSupportScreenshotFile,
  saveSupportScreenshotFile,
} from './storage.js';

/**
 * Persist validated multer files and return attachment rows for insert.
 * Rolls back disk writes when a later file fails.
 * @param {import('express').Multer.File[]} files
 * @returns {{ id: string, storage_key: string, mime: string, bytes: number }[]}
 */
export function persistSupportScreenshotAttachments(files) {
  /** @type {{ id: string, storage_key: string, mime: string, bytes: number }[]} */
  const saved = [];
  try {
    for (const file of files) {
      const row = saveSupportScreenshotFile(file);
      saved.push({
        id: row.attachmentId,
        storage_key: row.storage_key,
        mime: row.mime,
        bytes: row.bytes,
      });
    }
    return saved;
  } catch (err) {
    for (const row of saved) {
      removeSupportScreenshotFile(row.storage_key);
    }
    throw err;
  }
}
