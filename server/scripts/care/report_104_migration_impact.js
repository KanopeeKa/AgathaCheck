#!/usr/bin/env node
/**
 * Read-only counts for migration 104 backfill (run before production apply).
 * Groups rows that 104 would convert to not_recorded or delete, by close_reason.
 *
 * Usage: node scripts/care/report_104_migration_impact.js
 */
import { createAppPool } from '../../lib/db/createPool.js';
import { loadBackendEnv } from '../lib/loadBackendEnv.js';

loadBackendEnv();

async function main() {
  const pool = createAppPool();
  try {
    const legacy = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_schema = current_schema()
         AND table_name = 'health_occurrences' AND column_name = 'close_reason'`,
    );
    if (legacy.rows.length === 0) {
      console.log('close_reason column absent — migration 104 already applied or not applicable.');
      return;
    }

    const convertNotRecorded = await pool.query(
      `SELECT close_reason, COUNT(*)::int AS count
       FROM health_occurrences
       WHERE status = 'skipped' AND close_reason = 'not_recorded'
       GROUP BY close_reason
       ORDER BY close_reason`,
    );

    const convertStarted = await pool.query(
      `SELECT close_reason, COUNT(*)::int AS count
       FROM health_occurrences
       WHERE status = 'skipped'
         AND close_reason IN ('system', 'paused', 'covered')
         AND (
           scheduled_date < CURRENT_DATE
           OR (
             scheduled_date = CURRENT_DATE
             AND (scheduled_time IS NULL OR scheduled_time <= LOCALTIME)
           )
         )
       GROUP BY close_reason
       ORDER BY close_reason`,
    );

    const deleteFuture = await pool.query(
      `SELECT close_reason, COUNT(*)::int AS count
       FROM health_occurrences
       WHERE status = 'skipped'
         AND close_reason IN ('system', 'paused', 'covered')
         AND NOT (
           scheduled_date < CURRENT_DATE
           OR (
             scheduled_date = CURRENT_DATE
             AND (scheduled_time IS NULL OR scheduled_time <= LOCALTIME)
           )
         )
       GROUP BY close_reason
       ORDER BY close_reason`,
    );

    console.log(JSON.stringify({
      generated_at: new Date().toISOString(),
      note: 'Uses CURRENT_DATE/LOCALTIME at run time — see CARE-STATUS-MODEL-D-019.',
      convert_to_not_recorded: convertNotRecorded.rows,
      convert_started_skipped: convertStarted.rows,
      delete_future_skipped: deleteFuture.rows,
    }, null, 2));
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
