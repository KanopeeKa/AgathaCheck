import { afterEach, describe, expect, it, jest } from '@jest/globals';

import { runPosthogPersonDeleteJob } from '../../lib/jobs/handlers/posthogPersonDelete.js';
import * as posthogServer from '../../lib/posthogServer.js';

describe('posthog_person_delete handler', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('maps not_configured to succeeded job outcome', async () => {
    jest.spyOn(posthogServer, 'deletePostHogPersonForJob').mockResolvedValue({
      kind: 'not_configured',
    });
    const outcome = await runPosthogPersonDeleteJob({ distinct_id: 'user-1' });
    expect(outcome.retryable).toBe(false);
    expect(outcome.analyticsOutcome).toBe('not_configured');
  });

  it('maps retryable provider errors', async () => {
    jest.spyOn(posthogServer, 'deletePostHogPersonForJob').mockResolvedValue({
      kind: 'retryable',
      message: 'HTTP 503',
    });
    const outcome = await runPosthogPersonDeleteJob({ distinct_id: 'user-1' });
    expect(outcome.retryable).toBe(true);
  });

  it('maps succeeded responses', async () => {
    jest.spyOn(posthogServer, 'deletePostHogPersonForJob').mockResolvedValue({
      kind: 'succeeded',
    });
    const outcome = await runPosthogPersonDeleteJob({ distinct_id: 'user-1' });
    expect(outcome.retryable).toBe(false);
    expect(outcome.message).toBeUndefined();
  });
});
