/**
 * Pre-seed _migrations after a canonical.sql bootstrap (empty ledger, schema present).
 * Used by migrate.js on deploy and by seed-migration-ledger.js for explicit bootstrap.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { v4 as uuidv4 } from 'uuid';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function resolveManifestPath() {
  const candidates = [
    path.resolve(__dirname, '../../../db/schema/migration-manifest.json'),
    path.resolve(__dirname, '../../db/schema/migration-manifest.json'),
  ];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

export function loadManifest(manifestPath = resolveManifestPath()) {
  if (!manifestPath) {
    throw new Error(
      'migration-manifest.json not found (looked in repo root and backend db/schema/)'
    );
  }
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const migrations = manifest.incremental_migrations;
  if (!Array.isArray(migrations) || migrations.length === 0) {
    throw new Error('incremental_migrations missing or empty in manifest');
  }
  return migrations;
}

export async function usersTableExists(pool) {
  const { rows } = await pool.query(
    `SELECT EXISTS (
       SELECT 1
       FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'users'
     ) AS exists`
  );
  return rows[0]?.exists === true;
}

export async function appliedMigrations(pool) {
  const { rows } = await pool.query('SELECT name FROM _migrations');
  return new Set(rows.map((row) => row.name));
}

/**
 * Canonical bootstrap fingerprint: application schema exists but no incremental
 * migrations are recorded yet (typical after psql -f canonical.sql).
 */
export async function shouldAutoSeedMigrationLedger(pool, manifestMigrations) {
  if (!(await usersTableExists(pool))) return false;
  const applied = await appliedMigrations(pool);
  return manifestMigrations.every((name) => !applied.has(name));
}

export async function seedMigrationLedger(pool, manifestMigrations) {
  const applied = await appliedMigrations(pool);
  let inserted = 0;

  for (const name of manifestMigrations) {
    if (applied.has(name)) continue;
    await pool.query('INSERT INTO _migrations (id, name) VALUES ($1, $2)', [
      uuidv4(),
      name,
    ]);
    inserted++;
  }

  return inserted;
}

/**
 * When canonical.sql was applied manually, record manifest migrations before
 * migrate.js attempts to replay 001..020 SQL.
 */
export async function maybeAutoSeedMigrationLedger(pool) {
  const manifestPath = resolveManifestPath();
  if (!manifestPath) {
    console.log(
      'migration-ledger: manifest not found — skipping auto-seed (normal migrate path)'
    );
    return 0;
  }

  const manifestMigrations = loadManifest(manifestPath);
  if (!(await shouldAutoSeedMigrationLedger(pool, manifestMigrations))) {
    return 0;
  }

  const inserted = await seedMigrationLedger(pool, manifestMigrations);
  if (inserted === 0) {
    console.log('migration-ledger: canonical bootstrap detected — ledger already complete');
  } else {
    console.log(
      `migration-ledger: canonical bootstrap detected — recorded ${inserted} migration(s) in _migrations`
    );
  }
  return inserted;
}
