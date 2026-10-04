import { describe, expect, it, jest } from '@jest/globals';

import { drainCleanupJobs } from '../../lib/jobs/cleanupJobsRunner.js';

describe('cleanupJobs runner', () => {
  it('logs once per interval when cleanup_jobs table is missing', async () => {
    const pool = {
      query: jest.fn(async () => {
        const err = new Error('relation missing');
        err.code = '42P01';
        throw err;
      }),
    };
    const stats = await drainCleanupJobs(pool, { limit: 1 });
    expect(stats).toEqual({ claimed: 0, succeeded: 0, retryable: 0, dead: 0 });
    const again = await drainCleanupJobs(pool, { limit: 1 });
    expect(again.claimed).toBe(0);
    expect(pool.query).toHaveBeenCalledTimes(2);
  });
});
