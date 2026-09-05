/**
 * Move legacy public health files to private storage and rewrite URL columns.
 * @param {import('pg').PoolClient} client
 */
import fs from 'fs';
import path from 'path';

import {
  buildHealthFileApiPath,
  legacyHealthUploadDirs,
  privateHealthDir,
} from '../../lib/privateHealthStorage.js';
import { resolvePathUnderRoot } from '../../lib/safeUpload.js';

const LEGACY_URL_PREFIXES = ['/uploads/health_documents/', '/uploads/health_photos/'];

function filenameFromLegacyUrl(url) {
  for (const prefix of LEGACY_URL_PREFIXES) {
    if (url.startsWith(prefix)) {
      const filename = url.slice(prefix.length);
      if (filename && !filename.includes('/') && !filename.includes('\\')) {
        return filename;
      }
    }
  }
  return null;
}

function moveFileToPrivate(sourcePath, fileId) {
  const ext = path.extname(sourcePath);
  const destDir = privateHealthDir();
  fs.mkdirSync(destDir, { recursive: true, mode: 0o700 });
  const destPath = resolvePathUnderRoot(destDir, `${fileId}${ext}`);
  if (fs.existsSync(destPath)) return;
  if (!fs.existsSync(sourcePath)) return;
  fs.renameSync(sourcePath, destPath);
}

async function migrateTableUrls(client, tableName) {
  const { rows } = await client.query(
    `SELECT id, url FROM ${tableName} WHERE url LIKE '/uploads/health_%'`
  );
  const legacyDirs = legacyHealthUploadDirs();

  for (const row of rows) {
    const filename = filenameFromLegacyUrl(row.url);
    if (!filename) continue;

    let moved = false;
    for (const dir of legacyDirs) {
      try {
        const sourcePath = resolvePathUnderRoot(dir, filename);
        if (fs.existsSync(sourcePath)) {
          moveFileToPrivate(sourcePath, row.id);
          moved = true;
          break;
        }
      } catch {
        // try next dir
      }
    }

    const apiPath = buildHealthFileApiPath(row.id);
    await client.query(`UPDATE ${tableName} SET url = $1 WHERE id = $2`, [apiPath, row.id]);
    if (!moved) {
      // Row updated even if file missing — API returns 404 for orphaned metadata.
    }
  }
}

export async function migratePrivateHealthFiles(client) {
  fs.mkdirSync(privateHealthDir(), { recursive: true, mode: 0o700 });
  await migrateTableUrls(client, 'health_issue_documents');
  await migrateTableUrls(client, 'health_event_photos');
}
