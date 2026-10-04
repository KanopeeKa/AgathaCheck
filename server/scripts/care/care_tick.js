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

import { createAppPool, nodeProcessTimeZone, verifyPgDateParser } from '../../lib/db/createPool.js';
import { runCareTick } from '../../lib/care/occurrence/careTick.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

const pool = createAppPool();
try {
  await verifyPgDateParser(pool);
  const stats = await runCareTick(pool);
  console.log(JSON.stringify({
    at: new Date().toISOString(),
    tz: nodeProcessTimeZone(),
    ...stats,
  }));
} catch (err) {
  console.error('care tick failed', err);
  process.exitCode = 1;
} finally {
  await pool.end();
}
