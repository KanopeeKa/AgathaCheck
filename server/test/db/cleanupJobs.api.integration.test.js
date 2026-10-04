import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import {
  acknowledgeCleanupJob,
  claimCleanupJobs,
  enqueueCleanupJob,
  failCleanupJob,
} from '../../lib/jobs/cleanupJobsApi.js';
import { createDbPool } from './helpers/careHarness.js';
import {
  applyCleanupJobsDown,
  applyCleanupJobsMigration,
} from './helpers/cleanupJobsSql.js';

let pool;

async function resetJobs() {
  await pool.query('DELETE FROM cleanup_jobs');
}

beforeAll(async () => {
  pool = createDbPool();
  await applyCleanupJobsDown(pool).catch(() => {});
  await applyCleanupJobsMigration(pool);
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('cleanupJobs API (real PG)', () => {
  it('enqueueCleanupJob rejects a Pool', async () => {
    await expect(
      enqueueCleanupJob(pool, { type: 'file_delete', dedupeKey: 'x', payload: {} }),
    ).rejects.toThrow(/not a Pool/);
  });

  it('enqueueCleanupJob is idempotent on dedupe_key', async () => {
    await resetJobs();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const first = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'dedupe:one',
        payload: { storage: 'uploads', relative_path: 'a.txt' },
      });
      const second = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'dedupe:one',
        payload: { storage: 'uploads', relative_path: 'b.txt' },
      });
      await client.query('COMMIT');
      expect(second).toBe(first);
      const rows = await pool.query('SELECT count(*)::int AS n FROM cleanup_jobs WHERE dedupe_key = $1', ['dedupe:one']);
      expect(rows.rows[0].n).toBe(1);
    } finally {
      client.release();
    }
  });

  it('two concurrent claimers each claim distinct jobs exactly once', async () => {
    await resetJobs();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (let i = 0; i < 20; i += 1) {
        await enqueueCleanupJob(client, {
          type: 'noop',
          dedupeKey: `job-${i}`,
          payload: { i },
        });
      }
      await client.query('COMMIT');
    } finally {
      client.release();
    }

    const [batchA, batchB] = await Promise.all([
      claimCleanupJobs(pool, 15),
      claimCleanupJobs(pool, 15),
    ]);
    const ids = [...batchA, ...batchB].map((j) => j.id);
    expect(ids).toHaveLength(20);
    expect(new Set(ids).size).toBe(20);
  });

  it('stale lease token cannot ack; expired lease is reclaimed once', async () => {
    await resetJobs();
    const prevLease = process.env.CLEANUP_JOBS_LEASE_MS;
    process.env.CLEANUP_JOBS_LEASE_MS = '80';
    const client = await pool.connect();
    let jobId;
    try {
      await client.query('BEGIN');
      jobId = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'lease-test',
        payload: {},
      });
      await client.query('COMMIT');
    } finally {
      client.release();
    }

    const [job] = await claimCleanupJobs(pool, 1);
    expect(job.id).toBe(jobId);
    const stale = await acknowledgeCleanupJob(pool, jobId, randomUUID());
    expect(stale).toBe(false);

    await new Promise((r) => setTimeout(r, 120));
    const [reclaimed] = await claimCleanupJobs(pool, 1);
    expect(reclaimed.id).toBe(jobId);

    const acked = await acknowledgeCleanupJob(pool, jobId, reclaimed.lease_token);
    expect(acked).toBe(true);

    const third = await claimCleanupJobs(pool, 1);
    expect(third).toHaveLength(0);

    const runs = await pool.query(
      'SELECT status, attempts FROM cleanup_jobs WHERE id = $1',
      [jobId],
    );
    expect(runs.rows[0]).toEqual({ status: 'succeeded', attempts: 0 });
    process.env.CLEANUP_JOBS_LEASE_MS = prevLease;
  });

  it('redacts last_error_redacted paths tokens and emails', async () => {
    await resetJobs();
    const client = await pool.connect();
    let jobId;
    try {
      await client.query('BEGIN');
      jobId = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'redact',
        payload: {},
        maxAttempts: 2,
      });
      await client.query('COMMIT');
    } finally {
      client.release();
    }
    const [job] = await claimCleanupJobs(pool, 1);
    const secret = 'Bearer abc.def.ghi user@secret.com /etc/passwd';
    await failCleanupJob(pool, jobId, job.lease_token, { retryable: true, message: secret });
    const row = await pool.query(
      'SELECT last_error_redacted FROM cleanup_jobs WHERE id = $1',
      [jobId],
    );
    const stored = row.rows[0].last_error_redacted;
    expect(stored).not.toMatch(/@secret\.com/);
    expect(stored).not.toMatch(/\/etc\/passwd/);
    expect(stored).not.toMatch(/Bearer abc/);
    expect(stored).toContain('[email]');
  });

  it('non-retryable failure goes dead immediately; retryable exhausts to dead', async () => {
    await resetJobs();
    const client = await pool.connect();
    let retryId;
    let deadId;
    try {
      await client.query('BEGIN');
      deadId = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'dead-now',
        payload: {},
      });
      retryId = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'retry-exhaust',
        payload: {},
        maxAttempts: 2,
      });
      await client.query('COMMIT');
    } finally {
      client.release();
    }

    async function claimOne(targetId) {
      await pool.query(
        `UPDATE cleanup_jobs
         SET next_attempt_at = now() + interval '1 day'
         WHERE id <> $1 AND status IN ('pending', 'retryable', 'running')
           AND (status <> 'running' OR lease_expires_at IS NULL OR lease_expires_at <= now())`,
        [targetId],
      );
      await pool.query(
        `UPDATE cleanup_jobs
         SET next_attempt_at = now() - interval '1 minute',
             status = 'pending',
             lease_token = NULL,
             lease_expires_at = NULL
         WHERE id = $1 AND status IN ('pending', 'retryable', 'running')`,
        [targetId],
      );
      const [job] = await claimCleanupJobs(pool, 1);
      expect(job?.id).toBe(targetId);
      return job;
    }

    const deadJob = await claimOne(deadId);
    await failCleanupJob(pool, deadId, deadJob.lease_token, { retryable: false, message: 'nope' });
    const deadRow = await pool.query('SELECT status FROM cleanup_jobs WHERE id = $1', [deadId]);
    expect(deadRow.rows[0].status).toBe('dead');

    const retryJob = await claimOne(retryId);
    await failCleanupJob(pool, retryId, retryJob.lease_token, { retryable: true, message: 'again' });
    const retryJob2 = await claimOne(retryId);
    await failCleanupJob(pool, retryId, retryJob2.lease_token, { retryable: true, message: 'final' });
    const retryRow = await pool.query('SELECT status, attempts FROM cleanup_jobs WHERE id = $1', [retryId]);
    expect(retryRow.rows[0].status).toBe('dead');
    expect(retryRow.rows[0].attempts).toBe(2);
  });
});
