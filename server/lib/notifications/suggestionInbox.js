import { v4 as uuidv4 } from 'uuid';

import {
  NOTIFICATION_KIND_SUGGESTION,
  NOTIFICATION_PRIORITY_NORMAL,
} from '../../lib/notificationKind.js';
import { CO_PARENT_ROLE } from '../../lib/petAccess.js';
import {
  isAgathaSuggestionsInAppEnabled,
  isSuggestionTypeEnabled,
  loadNotificationPreferences,
} from '../../lib/notificationPreferences.js';

export const SUGGESTION_TYPE_CARE_FAMILY = 'suggestionCareFamily';

export const SUGGESTION_STATES_ACTIVE_INBOX = ['new', 'seen'];

const DEFAULT_SUGGESTION_CONFIDENCE = 0.85;
const SUGGESTION_TTL_DAYS = 14;
const DISMISS_SUPPRESS_DAYS = 30;
const NOT_RELEVANT_SUPPRESS_DAYS = 90;
const NOT_RELEVANT_ACCOUNT_WIDE_PET_STRIKES = 3;

/**
 * FR-SG-7 / care-family banner parity: `care_family:suggestion_key:petId`.
 */
export function buildCareFamilySuggestionDedupeKey(careFamily, suggestionKey, petId) {
  return `${careFamily}:${suggestionKey}:${petId}`;
}

export function parseCareFamilySuggestionDedupeKey(dedupeKey) {
  if (!dedupeKey || typeof dedupeKey !== 'string') return null;
  const parts = dedupeKey.split(':');
  if (parts.length < 3) return null;
  const petId = parts[parts.length - 1];
  const suggestionKey = parts[parts.length - 2];
  const careFamily = parts.slice(0, -2).join(':');
  if (!careFamily || !suggestionKey || !petId) return null;
  return { careFamily, suggestionKey, petId };
}

/** Record owner, co-parents, and household full-access members (S1–S6 recipients). */
export async function listSuggestionRecipientUserIds(pool, petId) {
  const result = await pool.query(
    `SELECT p.user_id FROM pets p WHERE p.id = $1
     UNION
     SELECT pa.user_id FROM pet_access pa
     WHERE pa.pet_id = $1
       AND pa.role = $2
       AND COALESCE(pa.hidden, false) = false
     UNION
     SELECT hm.user_id FROM household_pets hp
     INNER JOIN household_members hm ON hm.household_id = hp.household_id
     WHERE hp.pet_id = $1 AND hm.access_tier = 'full_access'`,
    [petId, CO_PARENT_ROLE],
  );
  return result.rows.map((r) => r.user_id);
}

function buildSuggestionPayload(recommendationRow) {
  return {
    recommendation_id: recommendationRow.id,
    care_family: recommendationRow.care_family,
    suggestion_key: recommendationRow.suggestion_key,
    rationale_key: recommendationRow.rationale_key,
    suggested_name: recommendationRow.suggested_name,
    suggested_frequency: recommendationRow.suggested_frequency,
    suggested_frequency_interval: recommendationRow.suggested_frequency_interval,
  };
}

function buildSuggestionCopy(pet, recommendationRow) {
  const petName = pet.name || pet.pet_name || 'your pet';
  const title = `${petName}: ${recommendationRow.suggested_name}`;
  const message = recommendationRow.rationale_key || 'Care rhythm suggestion';
  return { title, message };
}

export async function upsertSuggestionNotificationFromRecommendation(
  pool,
  { userId, pet, recommendationRow },
) {
  const petId = pet.id;
  const dedupeKey = buildCareFamilySuggestionDedupeKey(
    recommendationRow.care_family,
    recommendationRow.suggestion_key,
    petId,
  );
  const { title, message } = buildSuggestionCopy(pet, recommendationRow);
  const payload = buildSuggestionPayload(recommendationRow);
  const expiresAt = new Date();
  expiresAt.setUTCDate(expiresAt.getUTCDate() + SUGGESTION_TTL_DAYS);

  const inserted = await pool.query(
    `INSERT INTO notifications (
       id, user_id, pet_id, pet_name, title, message, type, kind, priority,
       suggestion_dedupe_key, suggestion_state, suggestion_confidence,
       suggestion_expires_at, suggestion_payload
     ) VALUES (
       $1, $2, $3, $4, $5, $6, $7, $8, $9,
       $10, 'new', $11, $12, $13::jsonb
     )
     ON CONFLICT (user_id, suggestion_dedupe_key)
       WHERE kind = 'suggestion'
         AND archived_at IS NULL
         AND suggestion_state IN ('new', 'seen')
     DO UPDATE SET
       title = EXCLUDED.title,
       message = EXCLUDED.message,
       pet_name = EXCLUDED.pet_name,
       suggestion_confidence = EXCLUDED.suggestion_confidence,
       suggestion_expires_at = EXCLUDED.suggestion_expires_at,
       suggestion_payload = EXCLUDED.suggestion_payload
     RETURNING *`,
    [
      uuidv4(),
      userId,
      petId,
      pet.name || pet.pet_name || null,
      title,
      message,
      SUGGESTION_TYPE_CARE_FAMILY,
      NOTIFICATION_KIND_SUGGESTION,
      NOTIFICATION_PRIORITY_NORMAL,
      dedupeKey,
      DEFAULT_SUGGESTION_CONFIDENCE,
      expiresAt,
      JSON.stringify(payload),
    ],
  );
  return inserted.rows[0];
}

export async function archiveActiveSuggestionsForUser(pool, userId) {
  await pool.query(
    `UPDATE notifications
     SET archived_at = NOW(), suggestion_state = 'suppressed'
     WHERE user_id = $1
       AND kind = $2
       AND archived_at IS NULL
       AND (suggestion_state IS NULL OR suggestion_state IN ('new', 'seen'))`,
    [userId, NOTIFICATION_KIND_SUGGESTION],
  );
}

export async function syncPetRecommendationsToInbox(pool, userId, petId) {
  void userId;
  const petResult = await pool.query(
    'SELECT id, name FROM pets WHERE id = $1',
    [petId],
  );
  if (petResult.rows.length === 0) return [];
  const pet = petResult.rows[0];

  const recsResult = await pool.query(
    `SELECT * FROM care_recommendations
     WHERE pet_id = $1 AND status = 'pending'
     ORDER BY created_at ASC`,
    [petId],
  );

  const recipientIds = await listSuggestionRecipientUserIds(pool, petId);
  const upserted = [];
  for (const recipientId of recipientIds) {
    const prefs = await loadNotificationPreferences(pool, recipientId);
    if (!isAgathaSuggestionsInAppEnabled(prefs)) continue;
    const muted = prefs.muted_pet_ids || [];
    if (muted.includes(String(petId))) continue;
    if (!isSuggestionTypeEnabled(prefs, SUGGESTION_TYPE_CARE_FAMILY)) continue;

    for (const row of recsResult.rows) {
      const notification = await upsertSuggestionNotificationFromRecommendation(pool, {
        userId: recipientId,
        pet,
        recommendationRow: row,
      });
      upserted.push(notification);
    }
  }
  return upserted;
}

export async function markSuggestionsSeen(pool, userId, { petId = null } = {}) {
  const params = [userId, NOTIFICATION_KIND_SUGGESTION];
  let petFilter = '';
  if (petId) {
    petFilter = ' AND pet_id = $3';
    params.push(petId);
  }
  await pool.query(
    `UPDATE notifications
     SET suggestion_state = 'seen'
     WHERE user_id = $1
       AND kind = $2
       AND archived_at IS NULL
       AND suggestion_state = 'new'${petFilter}`,
    params,
  );
}

async function syncRecommendationStatusFromNotification(pool, notification, status) {
  const payload = notification.suggestion_payload || {};
  if (payload.recommendation_id) {
    await pool.query(
      `UPDATE care_recommendations
       SET status = $1, responded_at = NOW(), updated_at = NOW()
       WHERE id = $2 AND pet_id = $3`,
      [status, payload.recommendation_id, notification.pet_id],
    );
    return;
  }
  const parsed = parseCareFamilySuggestionDedupeKey(notification.suggestion_dedupe_key);
  if (!parsed) return;
  await pool.query(
    `UPDATE care_recommendations
     SET status = $1, responded_at = NOW(), updated_at = NOW()
     WHERE pet_id = $2 AND care_family = $3 AND suggestion_key = $4`,
    [status, parsed.petId, parsed.careFamily, parsed.suggestionKey],
  );
}

export async function applySuggestionFeedback(pool, userId, notificationId, action) {
  const normalized = String(action || '').trim();
  if (normalized !== 'dismiss' && normalized !== 'not_relevant') {
    return { error: 'Invalid action', status: 400 };
  }

  const result = await pool.query(
    `SELECT * FROM notifications
     WHERE id = $1 AND user_id = $2 AND kind = $3 AND archived_at IS NULL`,
    [notificationId, userId, NOTIFICATION_KIND_SUGGESTION],
  );
  if (result.rows.length === 0) {
    return { error: 'Notification not found', status: 404 };
  }
  const row = result.rows[0];
  const recStatus = normalized === 'not_relevant' ? 'not_relevant' : 'dismissed';
  const suppressDays = normalized === 'not_relevant'
    ? NOT_RELEVANT_SUPPRESS_DAYS
    : DISMISS_SUPPRESS_DAYS;
  const suppressUntil = new Date();
  suppressUntil.setUTCDate(suppressUntil.getUTCDate() + suppressDays);

  const updated = await pool.query(
    `UPDATE notifications
     SET suggestion_state = $1,
         archived_at = NOW(),
         suggestion_expires_at = $2
     WHERE id = $3
     RETURNING *`,
    [recStatus, suppressUntil, notificationId],
  );

  await syncRecommendationStatusFromNotification(pool, row, recStatus);
  if (normalized === 'not_relevant') {
    await maybeDisableSuggestionTypeAfterNotRelevantStrikes(pool, userId, row.type);
  }
  return { notification: updated.rows[0] };
}

/**
 * FR-FB-2 — suppress suggestion type for a pet until suggestion_expires_at on archived rows.
 */
const SUGGESTION_SUPPRESS_STATES = ['dismissed', 'not_relevant', 'expired'];

/**
 * FR-FB-1 / FR-FB-2 — consult the latest row for this dedupe key (any archive state).
 * Dismiss, expiry, and not-relevant all set suggestion_expires_at as the quiet window end.
 */
export async function isSuggestionDedupeSuppressedForUser(
  pool,
  userId,
  dedupeKey,
  now = new Date(),
) {
  if (!userId || !dedupeKey) return false;
  const result = await pool.query(
    `SELECT suggestion_state, suggestion_expires_at
     FROM notifications
     WHERE user_id = $1
       AND suggestion_dedupe_key = $2
       AND kind = $3
     ORDER BY COALESCE(archived_at, created_at) DESC, created_at DESC
     LIMIT 1`,
    [userId, dedupeKey, NOTIFICATION_KIND_SUGGESTION],
  );
  const row = result.rows[0];
  if (!row) return false;
  if (!SUGGESTION_SUPPRESS_STATES.includes(row.suggestion_state)) return false;
  if (!row.suggestion_expires_at) return false;
  return new Date(row.suggestion_expires_at) > now;
}

/** @deprecated Prefer isSuggestionDedupeSuppressedForUser at generation time. */
export async function isSuggestionTypeSuppressedForPet(pool, userId, petId, wireType) {
  const result = await pool.query(
    `SELECT 1 FROM notifications
     WHERE user_id = $1
       AND pet_id = $2
       AND type = $3
       AND kind = $4
       AND suggestion_state = 'not_relevant'
       AND suggestion_expires_at IS NOT NULL
       AND suggestion_expires_at > NOW()
     LIMIT 1`,
    [userId, petId, wireType, NOTIFICATION_KIND_SUGGESTION],
  );
  return result.rows.length > 0;
}

async function maybeDisableSuggestionTypeAfterNotRelevantStrikes(pool, userId, wireType) {
  const result = await pool.query(
    `SELECT COUNT(DISTINCT pet_id)::int AS pet_count
     FROM notifications
     WHERE user_id = $1
       AND type = $2
       AND kind = $3
       AND suggestion_state = 'not_relevant'
       AND created_at > NOW() - ($4::text || ' days')::interval`,
    [userId, wireType, NOTIFICATION_KIND_SUGGESTION, String(NOT_RELEVANT_SUPPRESS_DAYS)],
  );
  const petCount = result.rows[0]?.pet_count ?? 0;
  if (petCount < NOT_RELEVANT_ACCOUNT_WIDE_PET_STRIKES) return;
  const { disableSuggestionTypeForUser } = await import('../notificationPreferences.js');
  await disableSuggestionTypeForUser(pool, userId, wireType);
}

export const SUGGESTION_INBOX_ACTIVE_WHERE = `kind = '${NOTIFICATION_KIND_SUGGESTION}'
  AND archived_at IS NULL
  AND (suggestion_state IS NULL OR suggestion_state IN ('new', 'seen'))`;
