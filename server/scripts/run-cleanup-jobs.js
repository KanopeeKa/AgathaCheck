#!/usr/bin/env node
/**
 * One-shot cleanup job drain (cron-friendly).
 *
 * Usage:
 *   node server/scripts/run-cleanup-jobs.js [--limit N]
 *
 * Exits 0 when no jobs ended dead; exits 1 if any job reached dead in this run.
 */
import '../config/loadEnv.js';
import { Pool } from 'pg';

import { drainCleanupJobs } from '../lib/jobs/cleanupJobsRunner.js';
import { logger } from '../lib/logger.js';

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

function parseLimit(argv) {
  const idx = argv.indexOf('--limit');
  if (idx === -1) return 50;
  const value = Number(argv[idx + 1]);
  return Number.isFinite(value) && value > 0 ? value : 50;
}

async function main() {
  const limit = parseLimit(process.argv.slice(2));
  const pool = createPool();
  try {
    const stats = await drainCleanupJobs(pool, { limit });
    logger.info({ stats, limit }, 'cleanup jobs CLI drain finished');
    process.exitCode = stats.dead > 0 ? 1 : 0;
  } catch (err) {
    logger.error({ err }, 'cleanup jobs CLI drain failed');
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
