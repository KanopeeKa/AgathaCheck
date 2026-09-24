/**
 * Authoritative occurrence reschedule primitive (CSM-10).
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { syncNextDueDateFromOccurrences } from '../../occurrenceScheduling.js';
import {
  insertCareScheduleEvent,
  SCHEDULE_EVENT_RESCHEDULED,
} from './scheduleEventLedger.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.occurrenceId
 * @param {string} params.userId
 * @param {string} params.newScheduledDate YYYY-MM-DD
 * @param {string} [params.reasonCode]
 * @param {string} [params.reasonNote]
 * @param {Date} [params.rescheduledAt]
 * @returns {Promise<{ occurrence: object, scheduleEventId: string, nextDueDate: string|null }|null>}
 */
export async function rescheduleOccurrence(pool, {
  entry,
  occurrenceId,
  userId,
  newScheduledDate,
  reasonCode = null,
  reasonNote = null,
  rescheduledAt = new Date(),
}) {
  const pending = await pool.query(
    `SELECT * FROM health_occurrences
     WHERE id = $1 AND health_entry_id = $2 AND status = 'pending'`,
    [occurrenceId, entry.id],
  );
  if (pending.rows.length === 0) return null;

  const occ = pending.rows[0];
  const fromDateIso = dateToIsoDate(occ.scheduled_date);

  const result = await pool.query(
    `UPDATE health_occurrences SET scheduled_date = $1, updated_at = NOW()
     WHERE id = $2 AND health_entry_id = $3 AND status = 'pending'
     RETURNING *`,
    [newScheduledDate, occurrenceId, entry.id],
  );
  if (result.rows.length === 0) return null;

  const scheduleEventId = await insertCareScheduleEvent(pool, {
    healthEntryId: entry.id,
    healthOccurrenceId: occurrenceId,
    eventType: SCHEDULE_EVENT_RESCHEDULED,
    fromDate: fromDateIso,
    toDate: newScheduledDate,
    reasonCode,
    reasonNote,
    actorUserId: userId,
    occurredAt: rescheduledAt,
    idempotencyKey: `rescheduled:${occurrenceId}:${newScheduledDate}`,
  });

  const nextDueDate = await syncNextDueDateFromOccurrences(pool, entry.id);

  return {
    occurrence: result.rows[0],
    scheduleEventId,
    nextDueDate,
  };
}
