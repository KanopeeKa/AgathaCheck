#!/usr/bin/env node
/**
 * Care tick (D-CSM-031) — run every 15 minutes from the host cron:
 *
 *   *\/15 * * * * cd <backend> && node scripts/care/care_tick.js >> logs/care_tick.log 2>&1
 *
 * Idempotent and overlap-safe (advisory lock). Every care command also runs
 * the same catch-up for its item, so a late or missing tick never leaves
 * wrong data behind — only later Not recorded closing and reminders.
 */
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import pg from 'pg';

import { runCareTick } from '../../lib/care/occurrence/careTick.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

function createPool() {
  if (process.env.DATABASE_URL) {
    return new pg.Pool({ connectionString: process.env.DATABASE_URL });
  }
  return new pg.Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT || 5432),
    database: process.env.PGDATABASE || 'agatha_db',
  });
}

const pool = createPool();
try {
  const stats = await runCareTick(pool);
  console.log(JSON.stringify({ at: new Date().toISOString(), ...stats }));
} catch (err) {
  console.error('care tick failed', err);
  process.exitCode = 1;
} finally {
  await pool.end();
}
