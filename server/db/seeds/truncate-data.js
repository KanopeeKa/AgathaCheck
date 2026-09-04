#!/usr/bin/env node
/**
 * Wipe all application data while preserving schema and migration ledger.
 * Discovers tables dynamically so new migrations stay covered automatically.
 * Non-production only — use before re-seeding UAT/demo databases.
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';
import { assertNonProduction } from '../../scripts/lib/guard-non-prod.js';

const { Pool } = pg;
const __dirname = path.dirname(fileURLToPath(import.meta.url));

dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

const PRESERVED_TABLES = new Set(['_migrations']);

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

export async function listApplicationTables(client) {
  const { rows } = await client.query(
    `SELECT tablename
     FROM pg_tables
     WHERE schemaname = 'public'
       AND tablename <> ALL($1::text[])
     ORDER BY tablename`,
    [[...PRESERVED_TABLES]],
  );
  return rows.map((row) => row.tablename);
}

export async function truncateDemoData(pool) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const tables = await listApplicationTables(client);
    if (tables.length === 0) {
      console.log('truncate: no application tables found');
      await client.query('COMMIT');
      return;
    }
    const tableList = tables.map((table) => `public.${table}`).join(', ');
    await client.query(`TRUNCATE TABLE ${tableList} RESTART IDENTITY CASCADE`);
    await client.query('COMMIT');
    console.log(`truncate: cleared ${tables.length} application tables`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function main() {
  assertNonProduction('truncate demo data');
  const pool = createPool();
  try {
    await truncateDemoData(pool);
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(`truncate ERROR: ${err.message}`);
    process.exit(1);
  });
}
