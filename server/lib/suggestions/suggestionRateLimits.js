import { NOTIFICATION_KIND_SUGGESTION } from '../notificationKind.js';
import {
  MAX_ACTIVE_SUGGESTIONS_PER_USER,
  MAX_NEW_SUGGESTIONS_PER_PET_7D,
  MAX_NEW_SUGGESTIONS_PER_USER_7D,
} from './suggestionConstants.js';

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * Count suggestion rows created in the rolling 7-day window (FR-RL-1).
 */
export async function countNewSuggestionsForPetLast7Days(pool, petId) {
  const since = new Date(Date.now() - SEVEN_DAYS_MS);
  const result = await pool.query(
    `SELECT COUNT(*)::int AS c FROM notifications
     WHERE pet_id = $1
       AND kind = $2
       AND created_at >= $3`,
    [petId, NOTIFICATION_KIND_SUGGESTION, since],
  );
  return result.rows[0]?.c ?? 0;
}

export async function countNewSuggestionsForUserLast7Days(pool, userId) {
  const since = new Date(Date.now() - SEVEN_DAYS_MS);
  const result = await pool.query(
    `SELECT COUNT(*)::int AS c FROM notifications
     WHERE user_id = $1
       AND kind = $2
       AND created_at >= $3`,
    [userId, NOTIFICATION_KIND_SUGGESTION, since],
  );
  return result.rows[0]?.c ?? 0;
}

export async function countActiveSuggestionsForUser(pool, userId) {
  const result = await pool.query(
    `SELECT COUNT(*)::int AS c FROM notifications
     WHERE user_id = $1
       AND kind = $2
       AND archived_at IS NULL
       AND (suggestion_state IS NULL OR suggestion_state IN ('new', 'seen'))`,
    [userId, NOTIFICATION_KIND_SUGGESTION],
  );
  return result.rows[0]?.c ?? 0;
}

/**
 * @returns {{ allowed: boolean, reason?: string }}
 */
export async function canCreateNewSuggestion(pool, { userId, petId }) {
  const [petCount, userCount, active] = await Promise.all([
    countNewSuggestionsForPetLast7Days(pool, petId),
    countNewSuggestionsForUserLast7Days(pool, userId),
    countActiveSuggestionsForUser(pool, userId),
  ]);
  if (petCount >= MAX_NEW_SUGGESTIONS_PER_PET_7D) {
    return { allowed: false, reason: 'pet_rate_limit' };
  }
  if (userCount >= MAX_NEW_SUGGESTIONS_PER_USER_7D) {
    return { allowed: false, reason: 'user_rate_limit' };
  }
  if (active >= MAX_ACTIVE_SUGGESTIONS_PER_USER) {
    return { allowed: false, reason: 'active_cap' };
  }
  return { allowed: true };
}
