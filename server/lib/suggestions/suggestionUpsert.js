import { v4 as uuidv4 } from 'uuid';

import {
  NOTIFICATION_KIND_SUGGESTION,
  NOTIFICATION_PRIORITY_NORMAL,
} from '../notificationKind.js';
import { SUGGESTION_TTL_DAYS } from './suggestionConstants.js';

/**
 * Upsert an active suggestion inbox row (FR-SG-5). Updates copy/evidence on conflict.
 *
 * @returns {Promise<{ row: object, created: boolean }>}
 */
export async function upsertWave1Suggestion(pool, {
  userId,
  petId,
  petName,
  wireType,
  dedupeKey,
  title,
  message,
  confidence,
  payload,
}) {
  const expiresAt = new Date();
  expiresAt.setUTCDate(expiresAt.getUTCDate() + SUGGESTION_TTL_DAYS);

  const existing = await pool.query(
    `SELECT id FROM notifications
     WHERE user_id = $1
       AND suggestion_dedupe_key = $2
       AND kind = $3
       AND archived_at IS NULL
       AND suggestion_state IN ('new', 'seen')
     LIMIT 1`,
    [userId, dedupeKey, NOTIFICATION_KIND_SUGGESTION],
  );

  if (existing.rows.length > 0) {
    const updated = await pool.query(
      `UPDATE notifications
       SET title = $1,
           message = $2,
           pet_name = $3,
           type = $4,
           suggestion_confidence = $5,
           suggestion_expires_at = $6,
           suggestion_payload = $7::jsonb
       WHERE id = $8
       RETURNING *`,
      [
        title,
        message,
        petName,
        wireType,
        confidence,
        expiresAt,
        JSON.stringify(payload),
        existing.rows[0].id,
      ],
    );
    return { row: updated.rows[0], created: false };
  }

  const inserted = await pool.query(
    `INSERT INTO notifications (
       id, user_id, pet_id, pet_name, title, message, type, kind, priority,
       suggestion_dedupe_key, suggestion_state, suggestion_confidence,
       suggestion_expires_at, suggestion_payload
     ) VALUES (
       $1, $2, $3, $4, $5, $6, $7, $8, $9,
       $10, 'new', $11, $12, $13::jsonb
     )
     RETURNING *`,
    [
      uuidv4(),
      userId,
      petId,
      petName,
      title,
      message,
      wireType,
      NOTIFICATION_KIND_SUGGESTION,
      NOTIFICATION_PRIORITY_NORMAL,
      dedupeKey,
      confidence,
      expiresAt,
      JSON.stringify(payload),
    ],
  );
  return { row: inserted.rows[0], created: true };
}

export async function completeSuggestionsForDedupeKeys(pool, dedupeKeys) {
  if (!dedupeKeys.length) return;
  await pool.query(
    `UPDATE notifications
     SET suggestion_state = 'completed',
         archived_at = NOW()
     WHERE kind = $1
       AND archived_at IS NULL
       AND suggestion_dedupe_key = ANY($2::text[])
       AND suggestion_state IN ('new', 'seen')`,
    [NOTIFICATION_KIND_SUGGESTION, dedupeKeys],
  );
}

export async function expireStaleSuggestions(pool, now = new Date()) {
  await pool.query(
    `UPDATE notifications
     SET suggestion_state = 'expired',
         archived_at = NOW()
     WHERE kind = $1
       AND archived_at IS NULL
       AND suggestion_state IN ('new', 'seen')
       AND suggestion_expires_at IS NOT NULL
       AND suggestion_expires_at < $2`,
    [NOTIFICATION_KIND_SUGGESTION, now],
  );
}
