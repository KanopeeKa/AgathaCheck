/**
 * The only SQL that writes `health_occurrences` (write-path guard,
 * `scripts/check_occurrence_writes.js`). Reads live here too.
 */

import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate } from '../../calendarDate.js';

/**
 * @param {object} row
 * @returns {{ date: string, time: string|null }}
 */
export function rowSlot(row) {
  return {
    date: dateToIsoDate(row.scheduled_date),
    time: row.scheduled_time ? String(row.scheduled_time).slice(0, 5) : null,
  };
}

/**
 * @param {object} row DB row
 * @returns {object} row with calendar strings
 */
export function normalizeOccurrenceRow(row) {
  if (!row) return row;
  const slot = rowSlot(row);
  return {
    ...row,
    scheduled_date: slot.date,
    scheduled_time: slot.time,
    series_date: row.series_date ? dateToIsoDate(row.series_date) : null,
    completed_on: row.completed_on ? dateToIsoDate(row.completed_on) : null,
    origin: row.origin || 'computed',
  };
}

const ORDER_ASC = `ORDER BY scheduled_date ASC, COALESCE(scheduled_time, '00:00:00'::time) ASC`;

/**
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 */
export async function listOpenRows(db, entryId) {
  const result = await db.query(
    `SELECT * FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending'
     ${ORDER_ASC}`,
    [entryId],
  );
  return result.rows.map(normalizeOccurrenceRow);
}

/**
 * Open rows for many items (list reads — one query, no per-row fetch).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string[]} entryIds
 * @returns {Promise<Map<string, object[]>>}
 */
export async function listOpenRowsByEntry(db, entryIds) {
  const map = new Map(entryIds.map((id) => [id, []]));
  if (entryIds.length === 0) return map;
  const result = await db.query(
    `SELECT * FROM health_occurrences
     WHERE health_entry_id = ANY($1::uuid[]) AND status = 'pending'
     ${ORDER_ASC}`,
    [entryIds],
  );
  for (const row of result.rows) {
    const list = map.get(row.health_entry_id);
    if (list) list.push(normalizeOccurrenceRow(row));
  }
  return map;
}

/**
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {string} occurrenceId
 */
export async function findOccurrence(db, entryId, occurrenceId) {
  const result = await db.query(
    'SELECT * FROM health_occurrences WHERE id = $1 AND health_entry_id = $2',
    [occurrenceId, entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * Slots already present from a series date onwards: key `date|time` → status.
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {string} fromIso
 * @returns {Promise<Map<string, string>>}
 */
export async function existingSeriesSlotKeys(db, entryId, fromIso) {
  const result = await db.query(
    `SELECT COALESCE(series_date, scheduled_date) AS slot_date, scheduled_time, status
     FROM health_occurrences
     WHERE health_entry_id = $1 AND COALESCE(series_date, scheduled_date) >= $2`,
    [entryId, fromIso],
  );
  const keys = new Map();
  for (const row of result.rows) {
    const time = row.scheduled_time ? String(row.scheduled_time).slice(0, 5) : '';
    const key = `${dateToIsoDate(row.slot_date)}|${time}`;
    if (keys.get(key) !== 'pending') keys.set(key, row.status);
  }
  return keys;
}

/**
 * Latest closed occurrence that counts for the After-it's-done rule:
 * done, or skipped by a person.
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 */
export async function lastRuleClosedRow(db, entryId) {
  const result = await db.query(
    `SELECT * FROM health_occurrences
     WHERE health_entry_id = $1
       AND (status = 'completed' OR (status = 'skipped' AND COALESCE(close_reason, 'user') = 'user'))
     ORDER BY scheduled_date DESC, COALESCE(scheduled_time, '00:00:00'::time) DESC,
       marked_at DESC NULLS LAST
     LIMIT 1`,
    [entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 */
export async function countClosedRows(db, entryId) {
  const result = await db.query(
    `SELECT COUNT(*)::int AS n FROM health_occurrences
     WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')`,
    [entryId],
  );
  return result.rows[0]?.n ?? 0;
}

/**
 * Insert an open occurrence; returns its id, or null when that open slot exists.
 *
 * @param {import('pg').PoolClient} db
 * @param {object} params
 * @param {string} params.entryId
 * @param {string} params.date
 * @param {string|null} params.time
 * @param {'schedule'|'computed'|'planned'} params.origin
 * @param {string|null} [params.seriesDate]
 * @returns {Promise<string|null>}
 */
export async function insertOpenOccurrence(db, {
  entryId, date, time, origin, seriesDate = null,
}) {
  const id = uuidv4();
  const result = await db.query(
    `INSERT INTO health_occurrences
       (id, health_entry_id, scheduled_date, scheduled_time, status, origin, series_date)
     VALUES ($1, $2, $3, $4, 'pending', $5, $6)
     ON CONFLICT DO NOTHING
     RETURNING id`,
    [id, entryId, date, time, origin, seriesDate],
  );
  return result.rows[0]?.id ?? null;
}

/**
 * Close an open occurrence as skipped.
 *
 * @param {import('pg').PoolClient} db
 * @param {object} params
 * @returns {Promise<object|null>}
 */
export async function markSkipped(db, {
  entryId, occurrenceId, closeReason, userId = null, notes = null, markedAt = new Date(),
}) {
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'skipped', close_reason = $1,
       marked_at = $2, marked_by_user_id = $3, notes = COALESCE($4, notes), updated_at = NOW()
     WHERE id = $5 AND health_entry_id = $6 AND status = 'pending'
     RETURNING *`,
    [closeReason, markedAt, userId, notes, occurrenceId, entryId],
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
    ? "status = 'skipped' AND close_reason = 'not_recorded'"
    : "status = 'pending'";
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'completed', close_reason = 'user',
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

/**
 * Restore a closed occurrence to a previous state (undo).
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {object} before row snapshot taken before the command
 */
export async function restoreOccurrence(db, entryId, before) {
  if (before.status === 'pending') {
    const clash = await db.query(
      `SELECT 1 FROM health_occurrences
       WHERE health_entry_id = $1 AND status = 'pending' AND id <> $2
         AND scheduled_date = $3
         AND COALESCE(scheduled_time, '00:00:00'::time) = COALESCE($4::time, '00:00:00'::time)
       LIMIT 1`,
      [entryId, before.id, before.scheduled_date, before.scheduled_time ?? null],
    );
    if (clash.rows.length > 0) return null;
  }
  const result = await db.query(
    `UPDATE health_occurrences SET status = $1, close_reason = $2, completed_on = $3,
       completion_timing = $4, marked_at = $5, marked_by_user_id = $6, notes = $7,
       performed_by_user_id = $8, marked_by_snapshot = $9::jsonb, performed_by_snapshot = $10::jsonb,
       provider_contact_id = $11, provider_typed_name = $12, provider_contact_snapshot = $13::jsonb,
       scheduled_date = $14, origin = $15, updated_at = NOW()
     WHERE id = $16 AND health_entry_id = $17
     RETURNING *`,
    [
      before.status,
      before.close_reason ?? null,
      before.completed_on ?? null,
      before.completion_timing ?? null,
      before.marked_at ?? null,
      before.marked_by_user_id ?? null,
      before.notes ?? '',
      before.performed_by_user_id ?? null,
      before.marked_by_snapshot ? JSON.stringify(before.marked_by_snapshot) : null,
      before.performed_by_snapshot ? JSON.stringify(before.performed_by_snapshot) : null,
      before.provider_contact_id ?? null,
      before.provider_typed_name ?? null,
      before.provider_contact_snapshot ? JSON.stringify(before.provider_contact_snapshot) : null,
      before.scheduled_date,
      before.origin || 'computed',
      before.id,
      entryId,
    ],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * Move an open occurrence to another date (and optionally time / origin).
 *
 * @param {import('pg').PoolClient} db
 * @param {object} params
 */
export async function moveOpenOccurrence(db, {
  entryId, occurrenceId, date, time, origin,
}) {
  // The open-slot unique index would abort the transaction; check first.
  const clash = await db.query(
    `SELECT 1 FROM health_occurrences target
     JOIN health_occurrences moving ON moving.id = $2
     WHERE target.health_entry_id = $1 AND target.status = 'pending' AND target.id <> $2
       AND target.scheduled_date = $3
       AND COALESCE(target.scheduled_time, '00:00:00'::time)
         = COALESCE(CASE WHEN $4::boolean THEN $5::time ELSE moving.scheduled_time END, '00:00:00'::time)
     LIMIT 1`,
    [entryId, occurrenceId, date, time !== undefined, time ?? null],
  );
  if (clash.rows.length > 0) return null;
  const result = await db.query(
    `UPDATE health_occurrences SET scheduled_date = $1,
       scheduled_time = CASE WHEN $2::boolean THEN $3::time ELSE scheduled_time END,
       origin = COALESCE($4, origin), updated_at = NOW()
     WHERE id = $5 AND health_entry_id = $6 AND status = 'pending'
     RETURNING *`,
    [date, time !== undefined, time ?? null, origin ?? null, occurrenceId, entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * Delete open occurrences by id (only rows still open).
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {string[]} ids
 * @param {string|null} [onlyOrigin] restrict to an origin
 * @returns {Promise<string[]>} deleted ids
 */
export async function deleteOpenOccurrences(db, entryId, ids, onlyOrigin = null) {
  if (!ids.length) return [];
  const result = await db.query(
    `DELETE FROM health_occurrences
     WHERE health_entry_id = $1 AND id = ANY($2::uuid[]) AND status = 'pending'
       AND ($3::text IS NULL OR origin = $3)
     RETURNING id`,
    [entryId, ids, onlyOrigin],
  );
  return result.rows.map((r) => r.id);
}

/**
 * Edit notes / provider on a completed occurrence (Add details).
 *
 * @param {import('pg').PoolClient|import('pg').Pool} db
 * @param {object} params
 */
export async function updateCompletedDetails(db, {
  entryId, occurrenceId, notes, provider,
}) {
  const sets = ['notes = $1', 'updated_at = NOW()'];
  const params = [notes];
  if (provider) {
    sets.push(`provider_contact_id = $${params.length + 1}`);
    params.push(provider.contactId);
    sets.push(`provider_typed_name = $${params.length + 1}`);
    params.push(provider.typedName);
    sets.push(`provider_contact_snapshot = $${params.length + 1}::jsonb`);
    params.push(provider.snapshot ? JSON.stringify(provider.snapshot) : null);
  }
  params.push(occurrenceId, entryId);
  const result = await db.query(
    `UPDATE health_occurrences SET ${sets.join(', ')}
     WHERE id = $${params.length - 1} AND health_entry_id = $${params.length}
       AND status = 'completed'
     RETURNING *`,
    params,
  );
  return result.rows[0] || null;
}

/**
 * Change when a completed occurrence was done (D-CSM-034). Completed rows only.
 *
 * @param {import('pg').PoolClient} db
 * @param {{ entryId: string, occurrenceId: string, completedOn: string, completionTiming: string }} params
 * @returns {Promise<object|null>}
 */
export async function updateCompletedOn(db, {
  entryId, occurrenceId, completedOn, completionTiming,
}) {
  const result = await db.query(
    `UPDATE health_occurrences SET completed_on = $1, completion_timing = $2, updated_at = NOW()
     WHERE id = $3 AND health_entry_id = $4 AND status = 'completed'
     RETURNING *`,
    [completedOn, completionTiming, occurrenceId, entryId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}

/**
 * Close every open occurrence of an item (series closed / archived).
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {string|null} userId
 * @param {'system'|'user'} closeReason
 */
export async function closeAllOpen(db, entryId, userId, closeReason = 'system') {
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'skipped', close_reason = $1,
       marked_at = NOW(), marked_by_user_id = $2, updated_at = NOW()
     WHERE health_entry_id = $3 AND status = 'pending'
     RETURNING id`,
    [closeReason, userId, entryId],
  );
  return result.rows.map((r) => r.id);
}

/**
 * Reopen a closed occurrence (weight-entry deletion without a ledger event).
 *
 * @param {import('pg').PoolClient} db
 * @param {string} occurrenceId
 * @returns {Promise<object|null>}
 */
export async function reopenClosedOccurrence(db, occurrenceId) {
  const result = await db.query(
    `UPDATE health_occurrences SET status = 'pending', close_reason = NULL, completed_on = NULL,
       completion_timing = NULL, marked_at = NULL, marked_by_user_id = NULL, notes = '',
       updated_at = NOW()
     WHERE id = $1 AND status IN ('completed', 'skipped')
     RETURNING *`,
    [occurrenceId],
  );
  return normalizeOccurrenceRow(result.rows[0] || null);
}
