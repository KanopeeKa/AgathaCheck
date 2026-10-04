/**
 * Migration 083 against a real PostgreSQL database. An isolated schema cloned
 * from the migrated public tables represents the pre-083 layout; the actual
 * migrate.js CLI applies the SQL, hook and ledger entry on that schema.
 */
import { randomUUID } from 'crypto';
import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import pg from 'pg';

import { createDbPool } from './helpers/careHarness.js';
import { migrateCareOccurrenceModel } from '../../scripts/migrations/083_care_occurrence_model.js';

const serverDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const migrationsDir = path.resolve(serverDir, '../db/migrations');
const migrationName = '083_care_occurrence_model.sql';
const clock = '2030-06-05T09:00:00.000Z';
const firstId = '00000000-0000-4000-8000-000000000001';
const secondId = '00000000-0000-4000-8000-000000000002';
const firstOccurrenceId = '00000000-0000-4000-8000-000000000003';

let admin;
let db;
let schema;
let dbOptions;

function runMigration() {
  const result = spawnSync(process.execPath, ['scripts/migrate.js', 'up'], {
    cwd: serverDir,
    encoding: 'utf8',
    timeout: 60000,
    env: {
      ...process.env,
      PGOPTIONS: dbOptions,
      NODE_OPTIONS: `--require=${path.resolve(serverDir, 'test/db/helpers/migration083Clock.cjs')}`,
      CARE_MIGRATION_TEST_CLOCK: clock,
    },
  });
  if (result.error) throw result.error;
  return result;
}

async function state() {
  const columns = await db.query(
    `SELECT table_name, column_name FROM information_schema.columns
     WHERE table_schema = $1 AND (
       (table_name = 'health_entries' AND column_name IN (
         'schedule_anchor_date', 'late_completion_choice', 'paused_until', 'series_resumed_on'))
       OR (table_name = 'health_occurrences' AND column_name IN (
         'origin', 'close_reason', 'series_date'))
       OR (table_name = 'care_schedule_events' AND column_name IN ('payload', 'undone_at'))
     ) ORDER BY table_name, column_name`,
    [schema],
  );
  const entries = await db.query(
    `SELECT id, to_char(schedule_anchor_date, 'YYYY-MM-DD') AS anchor
     FROM health_entries ORDER BY id`,
  ).catch(async (err) => {
    if (err.code !== '42703') throw err; // absent before migration
    return db.query('SELECT id, NULL::text AS anchor FROM health_entries ORDER BY id');
  });
  const occurrences = await db.query(
    `SELECT id, health_entry_id, to_char(scheduled_date, 'YYYY-MM-DD') AS day,
       status, origin, to_char(series_date, 'YYYY-MM-DD') AS series_day
     FROM health_occurrences ORDER BY health_entry_id, scheduled_date, id`,
  ).catch(async (err) => {
    if (err.code !== '42703') throw err;
    return db.query(
      `SELECT id, health_entry_id, to_char(scheduled_date, 'YYYY-MM-DD') AS day,
         status, NULL::text AS origin, NULL::text AS series_day
       FROM health_occurrences ORDER BY health_entry_id, scheduled_date, id`,
    );
  });
  const ledger = await db.query('SELECT name FROM _migrations WHERE name = $1', [migrationName]);
  const marker = await db.query('SELECT health_entry_id FROM migration083_markers ORDER BY health_entry_id');
  return {
    columns: columns.rows,
    entries: entries.rows,
    occurrences: occurrences.rows,
    ledger: ledger.rows,
    marker: marker.rows,
  };
}

beforeAll(async () => {
  admin = createDbPool();
  // Existing integration CI migrates public first. Fail explicitly if that
  // prerequisite or the database is absent; these are not mock/skip tests.
  const ready = await admin.query(
    `SELECT count(*)::int AS n FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'health_occurrences'
       AND column_name = 'origin'`,
  );
  if (ready.rows[0].n !== 1) throw new Error('Migration 083 tests require a migrated PostgreSQL public schema');

  schema = `migration083_${randomUUID().replace(/-/g, '')}`;
  await admin.query(`CREATE SCHEMA "${schema}"`);
  dbOptions = `-c search_path=${schema}`;
  const config = process.env.DATABASE_URL
    ? { connectionString: process.env.DATABASE_URL, options: dbOptions }
    : {
      user: process.env.PGUSER || 'user',
      password: process.env.PGPASSWORD || 'password',
      host: process.env.PGHOST || 'localhost',
      port: Number(process.env.PGPORT || 5432),
      database: process.env.PGDATABASE || 'agatha_db',
      options: dbOptions,
    };
  db = new pg.Pool(config);
  expect((await db.query('SELECT current_schema() AS schema')).rows[0].schema).toBe(schema);

  for (const table of ['pets', 'health_entries', 'health_occurrences', 'care_schedule_events']) {
    await db.query(`CREATE TABLE ${table} (LIKE public.${table} INCLUDING ALL)`);
  }
  for (const [table, columns] of [
    ['health_entries', ['schedule_anchor_date', 'late_completion_choice', 'paused_until', 'series_resumed_on']],
    ['health_occurrences', ['origin', 'close_reason', 'series_date']],
    ['care_schedule_events', ['payload', 'undone_at']],
  ]) {
    for (const column of columns) await db.query(`ALTER TABLE ${table} DROP COLUMN ${column} CASCADE`);
  }
  await db.query('CREATE TABLE migration083_markers (health_entry_id uuid NOT NULL)');
  await db.query(`
    CREATE FUNCTION migration083_observe() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      IF NEW.health_entry_id = '${secondId}' THEN
        RAISE EXCEPTION 'injected second-item sync failure';
      END IF;
      INSERT INTO migration083_markers (health_entry_id) VALUES (NEW.health_entry_id);
      RETURN NEW;
    END $$;
    CREATE TRIGGER migration083_observe_insert AFTER INSERT ON health_occurrences
      FOR EACH ROW EXECUTE FUNCTION migration083_observe();
  `);

  // The CLI creates its own ledger table. Preseed every earlier migration so
  // its production discovery/apply path has exactly 083 outstanding.
  await db.query('CREATE TABLE _migrations (id uuid PRIMARY KEY, name varchar(255) NOT NULL, applied_at timestamptz DEFAULT now())');
  const earlier = fs.readdirSync(migrationsDir)
    .filter((name) => /^\d{3}_.+\.sql$/.test(name) && !name.includes('_down') && name < migrationName);
  for (const name of earlier) {
    await db.query('INSERT INTO _migrations (id, name) VALUES ($1, $2)', [randomUUID(), name]);
  }
  const later = fs.readdirSync(migrationsDir)
    .filter((name) => /^\d{3}_.+\.sql$/.test(name) && !name.includes('_down') && name > migrationName);
  for (const name of later) {
    await db.query('INSERT INTO _migrations (id, name) VALUES ($1, $2)', [randomUUID(), name]);
  }
  const petId = randomUUID();
  const userId = randomUUID();
  await db.query(
    `INSERT INTO pets (id, user_id, name, species, home_timezone)
     VALUES ($1, $2, 'Migration pet', 'dog', 'UTC')`,
    [petId, userId],
  );
  for (const [id, anchor] of [[firstId, 'from_due_date'], [secondId, 'from_completion']]) {
    await db.query(
      `INSERT INTO health_entries
         (id, pet_id, user_id, type, name, frequency, recurrence_anchor,
          next_due_date, start_date, status, care_planning, care_importance)
       VALUES ($1, $2, $3, 'medication', 'Migration care', 'daily', $4,
         '2030-06-05', '2030-06-05', 'active', 'planned', 'essential')`,
      [id, petId, userId, anchor],
    );
  }
  await db.query(
    `INSERT INTO health_occurrences (id, health_entry_id, scheduled_date, status)
     VALUES ($1, $2, '2030-06-05', 'pending')`,
    [firstOccurrenceId, firstId],
  );
  await db.query('TRUNCATE migration083_markers');
}, 30000);

afterAll(async () => {
  if (db) await db.end();
  if (schema) await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
  if (admin) await admin.end();
});

describe('migration 083 runner transaction', () => {
  it('rejects the second item and rolls back schema, earlier item, marker and ledger', async () => {
    const before = await state();
    const result = runMigration();
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('injected second-item sync failure');
    const after = await state();
    expect(after).toEqual(before);
    expect(after.columns).toEqual([]);
    expect(after.marker).toEqual([]);
    expect(after.ledger).toEqual([]);
  }, 90000);

  it('retries successfully and stays idempotent at a controlled clock', async () => {
    await db.query('DROP TRIGGER migration083_observe_insert ON health_occurrences');
    await db.query(`
      CREATE TRIGGER migration083_observe_insert AFTER INSERT ON health_occurrences
        FOR EACH ROW WHEN (NEW.health_entry_id = '${firstId}')
        EXECUTE FUNCTION migration083_observe()
    `);
    const result = runMigration();
    expect(result.status).toBe(0);
    const successful = await state();
    expect(successful.columns).toHaveLength(9);
    expect(successful.entries.find((row) => row.id === firstId).anchor).toBe('2030-06-05');
    expect(successful.occurrences.find((row) => row.id === firstOccurrenceId)).toEqual(
      expect.objectContaining({ origin: 'schedule', series_day: '2030-06-05' }),
    );
    expect(successful.occurrences.some((row) => row.health_entry_id === secondId)).toBe(true);
    expect(successful.marker.length).toBeGreaterThan(0);
    expect(successful.ledger).toHaveLength(1);

    // CLI's applied-ledger path (same fixed wall clock) must not resync.
    const rerun = runMigration();
    expect(rerun.status).toBe(0);
    expect(rerun.stdout).toContain('Nothing to migrate');
    expect(await state()).toEqual(successful);

    // Also exercise the hook itself a second time: the ledger shortcut alone
    // would not detect a hook that creates duplicate occurrences.
    const NativeDate = Date;
    const instant = new NativeDate(clock).getTime();
    globalThis.Date = class FixedDate extends NativeDate {
      constructor(...args) {
        super(...(args.length ? args : [instant]));
      }
      static now() { return instant; }
    };
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      await migrateCareOccurrenceModel(client);
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
      globalThis.Date = NativeDate;
    }
    expect(await state()).toEqual(successful);
  }, 90000);
});