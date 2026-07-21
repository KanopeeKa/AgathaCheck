#!/usr/bin/env node
/**
 * Pre-seed _migrations from migration-manifest.json after canonical bootstrap.
 * Fresh installs only — production always runs migrate.js up on live DBs.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';
import { v4 as uuidv4 } from 'uuid';

const { Pool } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '../..');
const MANIFEST_PATH = path.join(ROOT, 'db/schema/migration-manifest.json');

dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

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

async function main() {
  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
  const migrations = manifest.incremental_migrations;
  if (!Array.isArray(migrations) || migrations.length === 0) {
    throw new Error('incremental_migrations missing or empty in manifest');
  }

  const pool = createPool();
  try {
    const { rows } = await pool.query('SELECT name FROM _migrations');
    const applied = new Set(rows.map((r) => r.name));
    let inserted = 0;

    for (const name of migrations) {
      if (applied.has(name)) continue;
      await pool.query(
        'INSERT INTO _migrations (id, name) VALUES ($1, $2)',
        [uuidv4(), name]
      );
      inserted++;
    }

    if (inserted === 0) {
      console.log('migration-ledger: all manifest migrations already recorded');
    } else {
      console.log(`migration-ledger: recorded ${inserted} migration(s) in _migrations`);
    }
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(`migration-ledger ERROR: ${err.message}`);
    process.exit(1);
  });
}
