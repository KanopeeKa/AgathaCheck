import { logger } from '../logger.js';
import { runSuggestionGeneration } from './suggestionGeneration.js';

const JOB_KEY = 'suggestion_wave1';

function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

/**
 * Claim once-per-UTC-day execution across app instances (scheduler_daily_runs).
 */
async function tryClaimDailyRun(pool, day) {
  const inserted = await pool.query(
    `INSERT INTO scheduler_daily_runs (job_key, run_day)
     VALUES ($1, $2::date)
     ON CONFLICT (job_key) DO NOTHING
     RETURNING job_key`,
    [JOB_KEY, day],
  );
  if (inserted.rows.length > 0) return true;

  const updated = await pool.query(
    `UPDATE scheduler_daily_runs
     SET run_day = $2::date, updated_at = NOW()
     WHERE job_key = $1 AND run_day < $2::date
     RETURNING job_key`,
    [JOB_KEY, day],
  );
  return updated.rows.length > 0;
}

/**
 * Run wave-1 suggestion generation at most once per UTC day cluster-wide (FR-SG-1).
 */
export async function maybeRunDailySuggestionGeneration(pool) {
  const day = utcDayKey();
  const claimed = await tryClaimDailyRun(pool, day);
  if (!claimed) return { skipped: true, reason: 'already_ran_today' };

  try {
    const stats = await runSuggestionGeneration(pool, { limit: 200 });
    logger.info({ stats, day }, 'daily suggestion generation finished');
    return { skipped: false, stats };
  } catch (err) {
    await pool.query(
      `UPDATE scheduler_daily_runs
       SET run_day = ($2::date - INTERVAL '1 day')::date, updated_at = NOW()
       WHERE job_key = $1`,
      [JOB_KEY, day],
    );
    logger.error({ err, day }, 'daily suggestion generation failed');
    throw err;
  }
}

/** Test / script hook — bypasses the once-per-day guard. */
export async function runSuggestionGenerationNow(pool, options = {}) {
  return runSuggestionGeneration(pool, options);
}
