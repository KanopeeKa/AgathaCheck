import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');

export function dropHealthHistoryMigrationSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/093_drop_health_history.sql'),
    'utf8',
  );
}

export function dropHealthHistoryDownSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/093_drop_health_history_down.sql'),
    'utf8',
  );
}

export async function applyDropHealthHistoryMigration(db) {
  await db.query(dropHealthHistoryMigrationSql());
}

export async function applyDropHealthHistoryDown(db) {
  await db.query(dropHealthHistoryDownSql());
}
