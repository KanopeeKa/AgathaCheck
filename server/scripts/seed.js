#!/usr/bin/env node
/**
 * Idempotent UAT/demo seed data (non-production only).
 *
 * Usage:
 *   node scripts/seed.js --scenario=org-clinic
 *   node scripts/seed.js --scenario=all
 *   node scripts/seed.js --scenario=guardian,rescue-hearts
 *
 * Scenarios live in server/db/seeds/scenarios/ — see docs/e2e/uat-demo-data.md
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';
import { assertNonProduction } from './lib/guard-non-prod.js';
import { ALL_SCENARIOS, SCENARIOS } from '../db/seeds/scenarios/index.js';

export { DEMO_IDS, DEMO_PASSWORD } from '../db/seeds/demo-constants.js';

const { Pool } = pg;
const __dirname = path.dirname(fileURLToPath(import.meta.url));

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

async function runScenario(pool, name) {
  const fn = SCENARIOS[name];
  if (!fn) {
    throw new Error(`Unknown scenario: ${name}`);
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await fn(client);
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

function parseScenarios(argv) {
  const arg = argv.find((a) => a.startsWith('--scenario='));
  if (!arg) return ['all'];
  const value = arg.slice('--scenario='.length);
  if (value === 'all') return ALL_SCENARIOS;
  return value.split(',').map((s) => s.trim()).filter(Boolean);
}

async function main() {
  assertNonProduction('database seed');
  const scenarios = parseScenarios(process.argv.slice(2));
  const pool = createPool();
  try {
    for (const scenario of scenarios) {
      await runScenario(pool, scenario);
    }
    console.log(`seed: completed (${scenarios.join(', ')})`);
  } finally {
    await pool.end();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(`seed ERROR: ${err.message}`);
    process.exit(1);
  });
}
