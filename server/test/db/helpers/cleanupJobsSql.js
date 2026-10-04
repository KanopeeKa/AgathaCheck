import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');

export function cleanupJobsMigrationSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/085_cleanup_jobs.sql'),
    'utf8',
  );
}

export function cleanupJobsDownSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/085_cleanup_jobs_down.sql'),
    'utf8',
  );
}

export async function applyCleanupJobsMigration(db) {
  await db.query(cleanupJobsMigrationSql());
}

export async function applyCleanupJobsDown(db) {
  await db.query(cleanupJobsDownSql());
}
