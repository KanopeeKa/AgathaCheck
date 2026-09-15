/**
 * Authoritative occurrence completion primitive (CSM-5).
 */

import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { resolveCompletedOn } from '../../occurrenceScheduling.js';
import { advanceSeries } from './advanceSeries.js';
import { deriveCompletionTiming } from './completionTiming.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} params.occurrenceId
 * @param {string} params.userId
 * @param {string} [params.completedOn] YYYY-MM-DD; defaults via resolveCompletedOn
 * @param {string} [params.notes]
 * @param {Date} [params.markedAt]
 * @param {string} [params.todayIso] calendar day for advanceSeries window
 * @returns {Promise<{ occurrence: object, nextDueDate: string|null }|null>}
 */
export async function completeOccurrence(pool, {
  entry,
  occurrenceId,
  userId,
  completedOn,
  notes = '',
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
  const completedOnIso = resolveCompletedOn(completedOn, todayIso);
  const scheduledDateIso = dateToIsoDate(occ.scheduled_date);
  const completionTiming = deriveCompletionTiming(scheduledDateIso, completedOnIso);

  const result = await pool.query(
    `UPDATE health_occurrences SET status = 'completed', completed_on = $1,
      marked_at = $2, marked_by_user_id = $3, notes = $4, completion_timing = $5,
      updated_at = NOW()
     WHERE id = $6 AND health_entry_id = $7 AND status = 'pending'
     RETURNING *`,
    [
      completedOnIso,
      markedAt,
      userId,
      notes,
      completionTiming,
      occurrenceId,
      entry.id,
    ],
  );
  if (result.rows.length === 0) return null;

  await advanceSeries(pool, entry, todayIso);

  const refreshed = await pool.query(
    'SELECT next_due_date FROM health_entries WHERE id = $1',
    [entry.id],
  );

  return {
    occurrence: result.rows[0],
    nextDueDate: dateToIsoDate(refreshed.rows[0]?.next_due_date),
  };
}
