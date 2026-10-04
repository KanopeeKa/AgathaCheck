import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { acknowledgeCleanupJob, claimCleanupJobs, enqueueCleanupJob } from '../../lib/jobs/cleanupJobsApi.js';
import { runCleanupJobsHousekeeping } from '../../lib/jobs/cleanupJobsHousekeeping.js';
import { createDbPool } from './helpers/careHarness.js';
import { applyCleanupJobsDown, applyCleanupJobsMigration } from './helpers/cleanupJobsSql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  await applyCleanupJobsDown(pool).catch(() => {});
  await applyCleanupJobsMigration(pool);
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('cleanupJobs housekeeping', () => {
  it('clears succeeded payloads and deletes old succeeded rows', async () => {
    await pool.query('DELETE FROM cleanup_jobs');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const jobId = await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: 'hk-1',
        payload: { storage: 'uploads', relative_path: 'x' },
      });
      await client.query('COMMIT');
      const [job] = await claimCleanupJobs(pool, 1);
      await acknowledgeCleanupJob(pool, jobId, job.lease_token);
    } finally {
      client.release();
    }

    await pool.query(
      `UPDATE cleanup_jobs
       SET completed_at = now() - interval '31 days'
       WHERE dedupe_key = 'hk-1'`,
    );
    await pool.query(
      `UPDATE cleanup_jobs
       SET payload = '{"keep":true}'::jsonb
       WHERE dedupe_key = 'hk-1'`,
    );

    const counts = await runCleanupJobsHousekeeping(pool);
    expect(counts.payloadsCleared).toBeGreaterThanOrEqual(1);
    expect(counts.succeededPurged).toBeGreaterThanOrEqual(1);
    const left = await pool.query('SELECT count(*)::int AS n FROM cleanup_jobs');
    expect(left.rows[0].n).toBe(0);
  });
});
