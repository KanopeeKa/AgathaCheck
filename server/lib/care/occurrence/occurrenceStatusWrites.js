/**
 * Status transitions on `health_occurrences` (user and system closes).
 */

import { normalizeOccurrenceRow } from './occurrenceRowNormalize.js';

/**
 * Reclassify an auto-closed Not recorded dose as an intentional skip (FR-3, AC-C5).
 *
 * @param {import('pg').PoolClient} db
 * @param {object} params
 * @returns {Promise<object|null>}
 */
export async function confirmNotRecordedAsSkipped(db, {
  entryId, occurrenceId, userId = null, markedAt = new Date(),
}) {
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'skipped',
       marked_at = $1, marked_by_user_id = $2, updated_at = NOW()
     WHERE id = $3 AND health_entry_id = $4 AND status = 'not_recorded'
     RETURNING *`,
    [markedAt, userId, occurrenceId, entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * System-only: the date passed without a user outcome (CARE-STATUS-R-003, R-004).
 *
 * @param {import('pg').PoolClient} db
 * @param {object} params
 * @returns {Promise<object|null>}
 */
export async function markNotRecorded(db, {
  entryId, occurrenceId, userId = null, markedAt = new Date(),
}) {
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'not_recorded',
       marked_at = $1, marked_by_user_id = $2, updated_at = NOW()
     WHERE id = $3 AND health_entry_id = $4 AND status = 'pending'
     RETURNING *`,
    [markedAt, userId, occurrenceId, entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/** User-initiated skip only (CARE-STATUS-R-003). */
export async function markSkipped(db, {
  entryId, occurrenceId, userId = null, notes = null, markedAt = new Date(),
}) {
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'skipped',
       marked_at = $1, marked_by_user_id = $2, notes = COALESCE($3, notes), updated_at = NOW()
     WHERE id = $4 AND health_entry_id = $5 AND status = 'pending'
     RETURNING *`,
    [markedAt, userId, notes, occurrenceId, entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * Close an open (or Not recorded) occurrence as done.
 *
 * @param {import('pg').PoolClient} db
 * @param {object} params
 * @returns {Promise<object|null>}
 */
export async function markCompleted(db, {
  entryId,
  occurrenceId,
  completedOn,
  completionTiming,
  userId,
  notes = '',
  markedAt = new Date(),
  performedByUserId = null,
  markedSnapshot = null,
  performedSnapshot = null,
  provider = { contactId: null, typedName: null, snapshot: null },
  fromNotRecorded = false,
}) {
  const statusClause = fromNotRecorded
    ? "status = 'not_recorded'"
    : "status = 'pending'";
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'completed',
       completed_on = $1, completion_timing = $2, marked_at = $3, marked_by_user_id = $4,
       notes = $5, performed_by_user_id = $6,
       marked_by_snapshot = $7::jsonb, performed_by_snapshot = $8::jsonb,
       provider_contact_id = $9, provider_typed_name = $10, provider_contact_snapshot = $11::jsonb,
       updated_at = NOW()
     WHERE id = $12 AND health_entry_id = $13 AND ${statusClause}
     RETURNING *`,
    [
      completedOn,
      completionTiming,
      markedAt,
      userId,
      notes,
      performedByUserId,
      markedSnapshot ? JSON.stringify(markedSnapshot) : null,
      performedSnapshot ? JSON.stringify(performedSnapshot) : null,
      provider.contactId ?? null,
      provider.typedName ?? null,
      provider.snapshot ? JSON.stringify(provider.snapshot) : null,
      occurrenceId,
      entryId,
    ],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}
