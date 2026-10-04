import { deletePostHogPersonForJob } from '../../posthogServer.js';

/**
 * @param {object} payload
 * @returns {Promise<{ retryable: boolean, message?: string, analyticsOutcome?: string }>}
 */
export async function runPosthogPersonDeleteJob(payload) {
  const distinctId = payload?.distinct_id;
  if (!distinctId) {
    return { retryable: false, message: 'missing distinct_id' };
  }
  const outcome = await deletePostHogPersonForJob(distinctId);
  if (outcome.kind === 'not_configured') {
    return { retryable: false, analyticsOutcome: 'not_configured' };
  }
  if (outcome.kind === 'succeeded') {
    return { retryable: false };
  }
  if (outcome.kind === 'retryable') {
    return { retryable: true, message: outcome.message };
  }
  return { retryable: false, message: outcome.message };
}
