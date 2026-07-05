import {
  POSTHOG_HOST,
  POSTHOG_PERSONAL_API_KEY,
  POSTHOG_PROJECT_ID,
} from '../config/observability.js';
import { logger } from './logger.js';

function isConfigured() {
  return Boolean(POSTHOG_PROJECT_ID && POSTHOG_PERSONAL_API_KEY);
}

/**
 * Request PostHog to delete a person and their events (GDPR Art. 17).
 * Best-effort: failures are logged but do not block account deletion.
 */
export async function deletePostHogPerson(distinctId) {
  if (!isConfigured() || !distinctId) return;

  const base = POSTHOG_HOST.replace(/\/$/, '');
  const url = `${base}/api/projects/${POSTHOG_PROJECT_ID}/persons/${encodeURIComponent(distinctId)}/?delete_events=true`;

  try {
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${POSTHOG_PERSONAL_API_KEY}`,
      },
    });
    if (!response.ok) {
      const body = await response.text();
      logger.warn(
        { status: response.status, body, distinctId },
        'PostHog person deletion failed'
      );
    }
  } catch (err) {
    logger.warn({ err, distinctId }, 'PostHog person deletion request failed');
  }
}
