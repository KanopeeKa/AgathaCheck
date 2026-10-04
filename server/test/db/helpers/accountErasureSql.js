import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../..');

export function accountErasureMigrationSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/087_account_erasure_operations.sql'),
    'utf8',
  );
}

export function accountErasureDownSql() {
  return fs.readFileSync(
    path.join(repoRoot, 'db/migrations/087_account_erasure_operations_down.sql'),
    'utf8',
  );
}

export async function applyAccountErasureMigration(db) {
  await db.query(accountErasureMigrationSql());
}

export async function applyAccountErasureDown(db) {
  await db.query(accountErasureDownSql());
}
