import {
  POSTHOG_HOST,
  POSTHOG_PERSONAL_API_KEY,
  POSTHOG_PROJECT_ID,
} from '../config/observability.js';
import { logger } from './logger.js';

export function isPostHogPersonDeleteConfigured() {
  return Boolean(POSTHOG_PROJECT_ID && POSTHOG_PERSONAL_API_KEY);
}

function isConfigured() {
  return isPostHogPersonDeleteConfigured();
}

/**
 * @param {string} distinctId
 * @returns {Promise<{ kind: 'succeeded' | 'retryable' | 'not_configured' | 'dead', message?: string }>}
 */
export async function deletePostHogPersonForJob(distinctId) {
  if (!isConfigured() || !distinctId) {
    return { kind: 'not_configured' };
  }

  const base = POSTHOG_HOST.replace(/\/$/, '');
  const url = `${base}/api/projects/${POSTHOG_PROJECT_ID}/persons/${encodeURIComponent(distinctId)}/?delete_events=true`;

  try {
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${POSTHOG_PERSONAL_API_KEY}`,
      },
    });
    if (response.ok || response.status === 404) {
      return { kind: 'succeeded' };
    }
    if (response.status === 429 || response.status >= 500) {
      const body = await response.text();
      return { kind: 'retryable', message: `PostHog HTTP ${response.status}: ${body.slice(0, 200)}` };
    }
    if (response.status === 401 || response.status === 403) {
      const body = await response.text();
      logger.error(
        { status: response.status, distinctId },
        'PostHog person deletion auth failure',
      );
      return { kind: 'retryable', message: `PostHog HTTP ${response.status}: ${body.slice(0, 200)}` };
    }
    const body = await response.text();
    return { kind: 'dead', message: `PostHog HTTP ${response.status}: ${body.slice(0, 200)}` };
  } catch (err) {
    return { kind: 'retryable', message: err?.message || 'PostHog request failed' };
  }
}

/**
 * Request PostHog to delete a person and their events (GDPR Art. 17).
 * @deprecated Use cleanup_jobs posthog_person_delete handler instead.
 */
export async function deletePostHogPerson(distinctId) {
  const outcome = await deletePostHogPersonForJob(distinctId);
  if (outcome.kind === 'succeeded' || outcome.kind === 'not_configured') return;
  logger.warn({ distinctId, outcome }, 'PostHog person deletion failed');
}
