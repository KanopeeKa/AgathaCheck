import { logger } from '../../logger.js';
import { SUPPORT_RETENTION_JOB_KEY } from './constants.js';
import { runSupportRetentionSweep } from './runRetentionSweep.js';

const STALE_CLAIM_INTERVAL = "INTERVAL '1 hour'";

function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

async function tryClaimDailyRun(pool, day) {
  const inserted = await pool.query(
    `INSERT INTO scheduler_daily_runs (job_key, run_day, claimed_at, completed_at)
     VALUES ($1, $2::date, NOW(), NULL)
     ON CONFLICT (job_key) DO NOTHING
     RETURNING job_key`,
    [SUPPORT_RETENTION_JOB_KEY, day],
  );
  if (inserted.rows.length > 0) return true;

  const updated = await pool.query(
    `UPDATE scheduler_daily_runs
     SET run_day = $2::date,
         claimed_at = NOW(),
         completed_at = NULL,
         updated_at = NOW()
     WHERE job_key = $1
       AND (
         run_day < $2::date
         OR (
           run_day = $2::date
           AND completed_at IS NULL
           AND claimed_at IS NOT NULL
           AND claimed_at < NOW() - ${STALE_CLAIM_INTERVAL}
         )
       )
     RETURNING job_key`,
    [SUPPORT_RETENTION_JOB_KEY, day],
  );
  return updated.rows.length > 0;
}

async function markDailyRunCompleted(pool) {
  await pool.query(
    `UPDATE scheduler_daily_runs
     SET completed_at = NOW(), updated_at = NOW()
     WHERE job_key = $1`,
    [SUPPORT_RETENTION_JOB_KEY],
  );
}

/**
 * Run support retention at most once per UTC day cluster-wide.
 */
export async function maybeRunDailySupportRetention(pool) {
  const day = utcDayKey();
  const claimed = await tryClaimDailyRun(pool, day);
  if (!claimed) return { skipped: true, reason: 'already_ran_today' };

  try {
    const stats = await runSupportRetentionSweep(pool);
    await markDailyRunCompleted(pool);
    logger.info({ stats, day }, 'support retention sweep finished');
    return { skipped: false, stats };
  } catch (err) {
    await pool.query(
      `UPDATE scheduler_daily_runs
       SET run_day = ($2::date - INTERVAL '1 day')::date,
           claimed_at = NULL,
           completed_at = NULL,
           updated_at = NOW()
       WHERE job_key = $1`,
      [SUPPORT_RETENTION_JOB_KEY, day],
    );
    logger.error({ err, day }, 'support retention sweep failed');
    throw err;
  }
}

/** Test hook — bypasses once-per-day guard. */
export async function runSupportRetentionSweepNow(pool, options = {}) {
  return runSupportRetentionSweep(pool, options);
}
