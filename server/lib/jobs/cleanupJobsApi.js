import { randomUUID } from 'crypto';

import { Pool } from 'pg';

import {
  DEFAULT_MAX_CLEANUP_ATTEMPTS,
  nextAttemptAfterFailure,
} from './cleanupJobsBackoff.js';
import { redactJobError } from './redactJobError.js';

export const CLEANUP_JOB_STATUSES = Object.freeze([
  'pending',
  'running',
  'succeeded',
  'retryable',
  'dead',
]);

function assertPgClient(client) {
  if (!client || typeof client.query !== 'function') {
    throw new TypeError('enqueueCleanupJob requires a PostgreSQL client');
  }
  if (client instanceof Pool) {
    throw new TypeError('enqueueCleanupJob requires a checked-out client, not a Pool');
  }
}

/**
 * @param {import('pg').PoolClient} client
 * @param {{ type: string, dedupeKey: string, correlationId?: string|null, payload?: object, maxAttempts?: number }} job
 * @returns {Promise<string>} job id
 */
export async function enqueueCleanupJob(client, {
  type,
  dedupeKey,
  correlationId = null,
  payload = {},
  maxAttempts = DEFAULT_MAX_CLEANUP_ATTEMPTS,
}) {
  assertPgClient(client);
  if (!type || !dedupeKey) {
    throw new Error('cleanup job requires type and dedupeKey');
  }
  const id = randomUUID();
  const insert = await client.query(
    `INSERT INTO cleanup_jobs (
       id, job_type, dedupe_key, correlation_id, payload, max_attempts
     ) VALUES ($1, $2, $3, $4, $5::jsonb, $6)
     ON CONFLICT (dedupe_key) DO NOTHING
     RETURNING id`,
    [id, type, dedupeKey, correlationId, JSON.stringify(payload ?? {}), maxAttempts],
  );
  if (insert.rows[0]?.id) {
    return insert.rows[0].id;
  }
  const existing = await client.query(
    'SELECT id FROM cleanup_jobs WHERE dedupe_key = $1',
    [dedupeKey],
  );
  if (!existing.rows[0]) {
    throw new Error('cleanup job dedupe conflict without row');
  }
  return existing.rows[0].id;
}

function defaultLeaseMs() {
  const raw = process.env.CLEANUP_JOBS_LEASE_MS;
  const parsed = raw ? Number(raw) : 5 * 60 * 1000;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 5 * 60 * 1000;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {number} limit
 */
export async function claimCleanupJobs(db, limit = 10) {
  const leaseToken = randomUUID();
  const leaseMs = defaultLeaseMs();
  const result = await db.query(
    `WITH picked AS (
       SELECT id
       FROM cleanup_jobs
       WHERE (
         status IN ('pending', 'retryable')
         AND next_attempt_at <= now()
       ) OR (
         status = 'running'
         AND lease_expires_at IS NOT NULL
         AND lease_expires_at <= now()
       )
       ORDER BY next_attempt_at ASC, created_at ASC
       FOR UPDATE SKIP LOCKED
       LIMIT $2
     )
     UPDATE cleanup_jobs j
     SET status = 'running',
         lease_token = $1,
         lease_expires_at = now() + ($3::text || ' milliseconds')::interval,
         updated_at = now()
     FROM picked
     WHERE j.id = picked.id
     RETURNING j.*`,
    [leaseToken, limit, String(leaseMs)],
  );
  return result.rows.map((row) => ({
    ...row,
    lease_token: leaseToken,
  }));
}

/**
 * @returns {Promise<boolean>} whether the ack applied
 */
export async function acknowledgeCleanupJob(db, jobId, leaseToken) {
  const result = await db.query(
    `UPDATE cleanup_jobs
     SET status = 'succeeded',
         lease_token = NULL,
         lease_expires_at = NULL,
         payload = NULL,
         completed_at = now(),
         updated_at = now(),
         last_error_redacted = NULL
     WHERE id = $1 AND lease_token = $2 AND status = 'running'
     RETURNING id`,
    [jobId, leaseToken],
  );
  return result.rowCount > 0;
}

/**
 * @param {{ retryable: boolean, message?: string }} outcome
 * @returns {Promise<boolean>}
 */
export async function failCleanupJob(db, jobId, leaseToken, outcome) {
  const redacted = redactJobError(outcome?.message || 'job failed');
  const current = await db.query(
    `SELECT attempts, max_attempts FROM cleanup_jobs
     WHERE id = $1 AND lease_token = $2 AND status = 'running'`,
    [jobId, leaseToken],
  );
  if (!current.rows[0]) {
    return false;
  }
  const attempts = current.rows[0].attempts + 1;
  const maxAttempts = current.rows[0].max_attempts;
  const retryable = Boolean(outcome?.retryable);
  let status = 'dead';
  let nextAttemptAt = null;
  if (retryable && attempts < maxAttempts) {
    status = 'retryable';
    nextAttemptAt = nextAttemptAfterFailure(attempts);
  }
  const result = await db.query(
    `UPDATE cleanup_jobs
     SET status = $3::varchar,
         attempts = $4,
         next_attempt_at = COALESCE($5::timestamptz, next_attempt_at),
         lease_token = NULL,
         lease_expires_at = NULL,
         last_error_redacted = $6,
         updated_at = now(),
         completed_at = CASE WHEN $3::text = 'dead' THEN now() ELSE completed_at END
     WHERE id = $1 AND lease_token = $2 AND status = 'running'
     RETURNING id, status, job_type, correlation_id`,
    [jobId, leaseToken, status, attempts, nextAttemptAt, redacted],
  );
  return result.rowCount > 0;
}
