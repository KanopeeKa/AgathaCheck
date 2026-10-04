#!/usr/bin/env node
/**
 * Daily audit retention job: hot (14d) → warm (90d) → cold (730d) → purge.
 *
 * Usage:
 *   PGUSER=user PGPASSWORD=password PGHOST=localhost PGDATABASE=agatha_db \
 *     node scripts/audit-retention.js
 */
import '../config/loadEnv.js';
import { createAppPool } from '../lib/db/createPool.js';
import { runAuditRetention } from '../lib/auditRetention.js';
import { logger } from '../lib/logger.js';

function createPool() {
  return createAppPool();
}

async function main() {
  const pool = createPool();
  try {
    const counts = await runAuditRetention(pool);
    logger.info({ counts }, 'audit retention completed');
    process.exitCode = 0;
  } catch (err) {
    logger.error({ err }, 'audit retention failed');
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
