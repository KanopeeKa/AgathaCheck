/**
 * Authoritative occurrence skip primitive (CSM-6).
 */

import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { advanceSeries } from './advanceSeries.js';
import {
  insertCareScheduleEvent,
  SCHEDULE_EVENT_SKIPPED,
} from './scheduleEventLedger.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.occurrenceId
 * @param {string} params.userId
 * @param {string} [params.notes]
 * @param {string} [params.reasonCode]
 * @param {Date} [params.markedAt]
 * @param {string} [params.todayIso]
 * @returns {Promise<{ occurrence: object, nextDueDate: string|null, scheduleEventId: string }|null>}
 */
export async function skipOccurrence(pool, {
  entry,
  occurrenceId,
  userId,
  notes = '',
  reasonCode = null,
  markedAt = new Date(),
  todayIso = todayCalendarIso(),
}) {
  const pending = await pool.query(
    `SELECT * FROM health_occurrences
     WHERE id = $1 AND health_entry_id = $2 AND status = 'pending'`,
    [occurrenceId, entry.id],
  );
  if (pending.rows.length === 0) return null;

  const occ = pending.rows[0];
  const scheduledDateIso = dateToIsoDate(occ.scheduled_date);

  const result = await pool.query(
    `UPDATE health_occurrences SET status = 'skipped', marked_at = $1,
      marked_by_user_id = $2, notes = $3, updated_at = NOW()
     WHERE id = $4 AND health_entry_id = $5 AND status = 'pending'
     RETURNING *`,
    [markedAt, userId, notes, occurrenceId, entry.id],
  );
  if (result.rows.length === 0) return null;

  const scheduleEventId = await insertCareScheduleEvent(pool, {
    healthEntryId: entry.id,
    healthOccurrenceId: occurrenceId,
    eventType: SCHEDULE_EVENT_SKIPPED,
    fromDate: scheduledDateIso,
    reasonCode,
    reasonNote: notes || null,
    actorUserId: userId,
    occurredAt: markedAt,
    idempotencyKey: `skipped:${occurrenceId}`,
  });

  await advanceSeries(pool, entry, todayIso);

  const refreshed = await pool.query(
    'SELECT next_due_date FROM health_entries WHERE id = $1',
    [entry.id],
  );

  return {
    occurrence: result.rows[0],
    nextDueDate: dateToIsoDate(refreshed.rows[0]?.next_due_date),
    scheduleEventId,
  };
}

/**
 * Skip pending occurrences in chronological order (skip-missed and batch helpers).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry
 * @param {string} params.userId
 * @param {string[]} params.occurrenceIds
 * @param {string} [params.todayIso]
 * @param {Date} [params.markedAt]
 * @returns {Promise<{ skipped: string[], count: number }>}
 */
export async function skipMissedOccurrences(pool, {
  entry,
  userId,
  occurrenceIds,
  todayIso = todayCalendarIso(),
  markedAt = new Date(),
}) {
  if (!occurrenceIds.length) {
    return { skipped: [], count: 0 };
  }

  const ordered = await pool.query(
    `SELECT id FROM health_occurrences
     WHERE id = ANY($1::uuid[]) AND health_entry_id = $2 AND status = 'pending'
     ORDER BY scheduled_date ASC,
       COALESCE(scheduled_time, '00:00:00'::time) ASC`,
    [occurrenceIds, entry.id],
  );

  const skipped = [];
  for (const row of ordered.rows) {
    const result = await skipOccurrence(pool, {
      entry,
      occurrenceId: row.id,
      userId,
      markedAt,
      todayIso,
    });
    if (result) skipped.push(row.id);
  }

  return { skipped, count: skipped.length };
}
