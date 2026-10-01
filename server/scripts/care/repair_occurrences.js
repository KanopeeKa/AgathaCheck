#!/usr/bin/env node
/**
 * Report (default, --dry-run) or repair (--apply) care occurrence invariant
 * violations: INV-1 (active planned item with no open date), INV-2 (two
 * computed dates), INV-4 (finished item with open dates), INV-5
 * (next_due_date not the earliest open date). --apply runs the occurrence
 * sync for each violating item. Use after a UAT reset or a failed tick.
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';

import { repairOccurrences } from '../../lib/care/occurrence/repair.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

const apply = process.argv.includes('--apply');
const pool = process.env.DATABASE_URL
  ? new pg.Pool({ connectionString: process.env.DATABASE_URL })
  : new pg.Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT || 5432),
    database: process.env.PGDATABASE || 'agatha_db',
  });

try {
  const report = await repairOccurrences(pool, { apply });
  for (const v of report.violations) console.log(`${v.codes.join(',')}\t${v.id}\t${v.name}`);
  console.log(`checked ${report.checked} care items; ${report.violations.length} with violations${apply ? `; repaired ${report.repaired}` : ' (dry run)'}`);
  if (!apply && report.violations.length > 0) process.exitCode = 2;
} catch (err) {
  console.error('repair_occurrences failed', err);
  process.exitCode = 1;
} finally {
  await pool.end();
}
