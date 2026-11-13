import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');

export function supportIntakeMigrationSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/106_support_intake_tables.sql'),
    'utf8',
  );
}

export function supportIntakeDownSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/106_support_intake_tables_down.sql'),
    'utf8',
  );
}

export async function applySupportIntakeMigration(db) {
  await db.query(supportIntakeMigrationSql());
}

export async function applySupportIntakeDown(db) {
  await db.query(supportIntakeDownSql());
}
