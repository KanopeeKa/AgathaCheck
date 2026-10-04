import { logger } from '../logger.js';
import {
  acknowledgeCleanupJob,
  claimCleanupJobs,
  failCleanupJob,
} from './cleanupJobsApi.js';
import { runCleanupJobsHousekeeping } from './cleanupJobsHousekeeping.js';
import { runFileDeleteJob, runPosthogPersonDeleteJob } from './handlers/index.js';

const TABLE_MISSING = '42P01';

let activePool = null;
let pollTimer = null;
let draining = false;
let kickPending = false;
let missingTableLoggedAt = 0;

function pollIntervalMs() {
  const raw = process.env.CLEANUP_JOBS_POLL_MS;
  const parsed = raw ? Number(raw) : 60_000;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 60_000;
}

function runnerEnabled() {
  const flag = (process.env.CLEANUP_JOBS_RUNNER || 'on').toLowerCase();
  return flag !== 'off' && flag !== '0' && flag !== 'false';
}

async function executeJob(db, job) {
  if (job.job_type === 'file_delete') {
    const outcome = await runFileDeleteJob(job.payload);
    if (!outcome.retryable && !outcome.message) {
      await acknowledgeCleanupJob(db, job.id, job.lease_token);
      return 'succeeded';
    }
    await failCleanupJob(db, job.id, job.lease_token, {
      retryable: Boolean(outcome.retryable),
      message: outcome.message || 'file_delete failed',
    });
    const row = await db.query('SELECT status FROM cleanup_jobs WHERE id = $1', [job.id]);
    return row.rows[0]?.status;
  }
  if (job.job_type === 'posthog_person_delete') {
    const outcome = await runPosthogPersonDeleteJob(job.payload);
    if (!outcome.retryable && !outcome.message) {
      await acknowledgeCleanupJob(db, job.id, job.lease_token);
      return 'succeeded';
    }
    await failCleanupJob(db, job.id, job.lease_token, {
      retryable: Boolean(outcome.retryable),
      message: outcome.message || 'posthog_person_delete failed',
    });
    const row = await db.query('SELECT status FROM cleanup_jobs WHERE id = $1', [job.id]);
    return row.rows[0]?.status;
  }
  await failCleanupJob(db, job.id, job.lease_token, {
    retryable: false,
    message: `unknown job_type ${job.job_type}`,
  });
  return 'dead';
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ limit?: number }} [options]
 */
export async function drainCleanupJobs(pool, { limit = 10 } = {}) {
  const stats = { claimed: 0, succeeded: 0, retryable: 0, dead: 0 };
  let jobs;
  try {
    jobs = await claimCleanupJobs(pool, limit);
  } catch (err) {
    if (err?.code === TABLE_MISSING) {
      const now = Date.now();
      if (now - missingTableLoggedAt >= pollIntervalMs()) {
        missingTableLoggedAt = now;
        logger.warn('cleanup_jobs table missing; runner idle until migration applies');
      }
      return stats;
    }
    throw err;
  }

  stats.claimed = jobs.length;
  for (const job of jobs) {
    const status = await executeJob(pool, job);
    if (status === 'succeeded') {
      stats.succeeded += 1;
    } else if (status === 'retryable') {
      stats.retryable += 1;
    } else if (status === 'dead') {
      stats.dead += 1;
      logger.error({
        jobId: job.id,
        jobType: job.job_type,
        correlationId: job.correlation_id,
      }, 'cleanup job reached dead status');
    }
  }

  try {
    await runCleanupJobsHousekeeping(pool);
  } catch (err) {
    if (err?.code !== TABLE_MISSING) {
      logger.warn({ err }, 'cleanup jobs housekeeping failed');
    }
  }

  logger.info(stats, 'cleanup jobs drain finished');
  return stats;
}

async function drainLoop(pool) {
  if (draining || !activePool) return;
  if (kickPending) {
    kickPending = false;
  }
  try {
    await drainCleanupJobs(pool);
  } catch (err) {
    logger.error({ err }, 'cleanup jobs drain failed');
  }
}

/**
 * Request an immediate drain on the active runner.
 */
export function kickCleanupJobs() {
  if (!activePool || draining) return;
  kickPending = true;
  drainLoop(activePool).catch((err) => {
    logger.error({ err }, 'cleanup jobs kick failed');
  });
}

export function startCleanupJobsRunner(pool) {
  if (!runnerEnabled()) {
    return { stop: () => {} };
  }
  activePool = pool;
  draining = false;
  const interval = pollIntervalMs();
  pollTimer = setInterval(() => {
    if (!kickPending) {
      drainLoop(pool).catch(() => {});
    }
  }, interval);
  pollTimer.unref?.();
  drainLoop(pool).catch(() => {});

  return {
    stop() {
      draining = true;
      if (pollTimer) {
        clearInterval(pollTimer);
        pollTimer = null;
      }
      activePool = null;
    },
  };
}
