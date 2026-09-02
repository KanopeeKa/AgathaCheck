#!/usr/bin/env node
/**
 * Node.js migration runner — runs on the deployed (UAT/PROD) backend.
 * Supports `up` and `status`.
 *
 * Tracks applied migrations in the `_migrations` table.
 *
 * Migration discovery: looks for `db/migrations/*.sql` (excluding `_down.sql`
 * files) in two candidate locations to support both local dev and the remote
 * deploy layout:
 *   1. `<repo>/db/migrations`  — local dev (script lives at `server/scripts/`)
 *   2. `<server>/db/migrations` — remote (deploy stages files under server/)
 *
 * Usage:
 *   node scripts/migrate.js up      apply pending migrations (auto-seeds ledger after canonical bootstrap)
 *   node scripts/migrate.js status  show applied/pending
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';
import { v4 as uuidv4 } from 'uuid';
import { migrateFamilyEventsPlacements } from './migrations/016_migrate_family_events_placements.js';
import { migrateFosterProfiles } from './migrations/023_foster_profiles.js';
import { migrateAdoptionJourneys } from './migrations/028_adoption_journeys.js';
import { migrateFamilyEventsTimeline } from './migrations/034_migrate_family_events_timeline.js';
import { migrateOrganizationPermissions } from './migrations/036_organization_permissions.js';
import { backfillWeightEntriesFromPets } from './migrations/040_backfill_weight_entries_from_pets.js';
import { migrateOrgMemberPrivacy } from './migrations/042_org_member_privacy.js';
import { migrateRetireFosterWireRole } from './migrations/044_org_retire_foster_wire_role.js';
import { migrateOrganizationRolePermissionDefaults } from './migrations/045_organization_role_permission_defaults.js';
import { backfillHealthOccurrences } from './migrations/047_health_occurrences_backfill.js';
import { maybeAutoSeedMigrationLedger } from './lib/migration-ledger.js';

const { Pool } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load the same .env the app uses. When the deploy runs this over SSH, the
// process does NOT inherit cPanel's Node-app environment, so we read the .env
// in the backend root (one level up from scripts/) exactly like bin/server.js.
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

// Mirror bin/server.js createPool(): prefer DATABASE_URL, else fall back to
// the discrete PG* vars. This keeps the migration runner connecting the same
// way the running app does, in every environment.
function createPool() {
  const databaseUrl = process.env.DATABASE_URL;
  if (databaseUrl) {
    return new Pool({ connectionString: databaseUrl });
  }
  return new Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    database: process.env.PGDATABASE || 'agatha_db',
  });
}

function resolveMigrationsDir() {
  const candidates = [
    path.resolve(__dirname, '../../db/migrations'),
    path.resolve(__dirname, '../db/migrations'),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  throw new Error(
    `Could not locate db/migrations directory. Looked in: ${candidates.join(', ')}`
  );
}

function listMigrationFiles(dir) {
  // Only apply incremental migrations matching `NNN_*.sql` (e.g.
  // `005_add_vet_fields.sql`). Explicitly EXCLUDES the canonical fresh-install
  // schema (`v3__initial_uuid_schema.sql`), which contains full CREATE TABLE
  // statements and would crash on any pre-existing DB. The canonical schema
  // is for `fresh` only (Dart runner, gated by MIGRATE_CONFIRM=DROP_ALL).
  return fs
    .readdirSync(dir)
    .filter(
      (name) =>
        /^\d{3}_.+\.sql$/.test(name) && !name.includes('_down')
    )
    .sort();
}

async function ensureMigrationsTable(pool) {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id UUID PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      applied_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);
}

async function appliedMigrations(pool) {
  const { rows } = await pool.query('SELECT name FROM _migrations');
  return new Set(rows.map((r) => r.name));
}

/** Migrations whose data changes need app-generated UUIDs (no gen_random_uuid()). */
const CODE_MIGRATIONS = {
  '016_migrate_family_events_placements.sql': migrateFamilyEventsPlacements,
  '023_foster_profiles.sql': migrateFosterProfiles,
  '028_adoption_journeys.sql': migrateAdoptionJourneys,
  '034_pet_timeline_entries.sql': migrateFamilyEventsTimeline,
  '036_organization_permissions.sql': migrateOrganizationPermissions,
  '040_backfill_weight_entries_from_pets.sql': backfillWeightEntriesFromPets,
  '042_org_member_privacy.sql': migrateOrgMemberPrivacy,
  '044_org_retire_foster_wire_role.sql': migrateRetireFosterWireRole,
  '045_organization_role_permission_defaults.sql': migrateOrganizationRolePermissionDefaults,
  '047_health_occurrences.sql': backfillHealthOccurrences,
};

async function applyMigration(client, name, sql) {
  const codeRunner = CODE_MIGRATIONS[name];
  if (codeRunner) {
    await codeRunner(client);
    return;
  }
  await client.query(sql);
}

async function runUp(pool) {
  await ensureMigrationsTable(pool);
  await maybeAutoSeedMigrationLedger(pool);
  const applied = await appliedMigrations(pool);
  const dir = resolveMigrationsDir();
  const files = listMigrationFiles(dir);
  let ran = 0;

  for (const name of files) {
    if (applied.has(name)) {
      console.log(`  skip  ${name} (already applied)`);
      continue;
    }
    const sql = fs.readFileSync(path.join(dir, name), 'utf8');
    console.log(`  apply ${name} ...`);
    // Apply the migration SQL and record it in `_migrations` inside one
    // transaction. Without this, a SQL success followed by an INSERT failure
    // (or SIGTERM mid-run) would leave the schema changed but unrecorded,
    // causing the next deploy to retry the same migration and crash.
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await applyMigration(client, name, sql);
      await client.query(
        'INSERT INTO _migrations (id, name) VALUES ($1, $2)',
        [uuidv4(), name]
      );
      await client.query('COMMIT');
      ran++;
      console.log(`  done  ${name}`);
    } catch (err) {
      try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
      console.error(`  FAIL  ${name}: ${err.message}`);
      throw err;
    } finally {
      client.release();
    }
  }

  if (ran === 0) {
    console.log('Nothing to migrate — all migrations already applied.');
  } else {
    console.log(`Applied ${ran} migration(s).`);
  }
}

async function showStatus(pool) {
  await ensureMigrationsTable(pool);
  const applied = await appliedMigrations(pool);
  const dir = resolveMigrationsDir();
  const files = listMigrationFiles(dir);

  console.log('Migration status:');
  let pending = 0;
  for (const name of files) {
    const status = applied.has(name) ? 'applied' : 'PENDING';
    if (!applied.has(name)) pending++;
    console.log(`  [${status}] ${name}`);
  }
  console.log(`${applied.size} applied, ${pending} pending.`);
}

async function main() {
  const command = process.argv[2] || 'up';
  console.log('Agatha Track — Migration Runner (Node)');
  console.log(`Command: ${command}\n`);

  const pool = createPool();
  try {
    switch (command) {
      case 'up':
        await runUp(pool);
        break;
      case 'status':
        await showStatus(pool);
        break;
      default:
        console.log('Usage: node scripts/migrate.js [up|status]');
        console.log('');
        console.log('  up      apply pending NNN_*.sql migrations');
        console.log('  status  show which migrations are applied/pending');
        console.log('');
        process.exit(2);
    }
  } catch (err) {
    console.error(`ERROR: ${err.message}`);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
