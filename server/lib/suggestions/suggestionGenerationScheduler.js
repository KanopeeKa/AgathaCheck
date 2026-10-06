import { logger } from '../logger.js';
import { runSuggestionGeneration } from './suggestionGeneration.js';

let lastRunUtcDay = null;

function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

/**
 * Run wave-1 suggestion generation at most once per UTC day per process (FR-SG-1).
 * Invoked from the cleanup jobs poll loop on long-running servers.
 */
export async function maybeRunDailySuggestionGeneration(pool) {
  const day = utcDayKey();
  if (lastRunUtcDay === day) return { skipped: true, reason: 'already_ran_today' };
  lastRunUtcDay = day;
  try {
    const stats = await runSuggestionGeneration(pool, { limit: 500 });
    logger.info({ stats, day }, 'daily suggestion generation finished');
    return { skipped: false, stats };
  } catch (err) {
    lastRunUtcDay = null;
    logger.error({ err, day }, 'daily suggestion generation failed');
    throw err;
  }
}

/** Test / script hook — bypasses the once-per-day guard. */
export async function runSuggestionGenerationNow(pool, options = {}) {
  return runSuggestionGeneration(pool, options);
}
