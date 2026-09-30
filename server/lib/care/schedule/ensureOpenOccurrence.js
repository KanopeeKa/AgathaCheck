/**
 * Intent-based materialisation of the canonical open occurrence (D-CSM-018).
 */

import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import {
  insertOccurrencesForDay,
  isOnceEntry,
  occurrenceToMap,
  syncNextDueDateFromOccurrences,
} from '../../occurrenceScheduling.js';
import {
  isEntrySeriesClosed,
  isOccurrenceDateWithinSeries,
} from '../../occurrenceLifecycle.js';
import { resolveNextSeriesDate } from './advanceSeries.js';
/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry
 * @param {string} todayIso
 * @returns {Promise<string|null>} YYYY-MM-DD head date to materialise or act on
 */
export async function resolveCanonicalOpenDateIso(pool, entry, todayIso) {
  if (isEntrySeriesClosed(entry, todayIso)) {
    return null;
  }

  if (isOnceEntry(entry)) {
    const nextDue = dateToIsoDate(entry.next_due_date);
    const start = dateToIsoDate(entry.start_date);
    return nextDue || start || null;
  }

  const earliestPending = await pool.query(
    `SELECT scheduled_date FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending'
     ORDER BY scheduled_date ASC
     LIMIT 1`,
    [entry.id],
  );

  if (earliestPending.rows.length > 0) {
    return dateToIsoDate(earliestPending.rows[0].scheduled_date);
  }

  const lastClosed = await pool.query(
    `SELECT scheduled_date, completed_on FROM health_occurrences
     WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
     ORDER BY scheduled_date DESC,
       COALESCE(scheduled_time, '00:00:00'::time) DESC
     LIMIT 1`,
    [entry.id],
  );

  if (lastClosed.rows.length === 0) {
    // Never materialised: the head is the deferred next due date (T-1 rule).
    const nextDue = dateToIsoDate(entry.next_due_date);
    if (nextDue && isOccurrenceDateWithinSeries(entry, nextDue)) {
      return nextDue;
    }
  }

  const closedScheduledDate = lastClosed.rows[0]
    ? dateToIsoDate(lastClosed.rows[0].scheduled_date)
    : dateToIsoDate(entry.start_date) || todayIso;
  const completedOn = lastClosed.rows[0]?.completed_on
    ? dateToIsoDate(lastClosed.rows[0].completed_on)
    : closedScheduledDate;

  const nextDate = resolveNextSeriesDate(entry, closedScheduledDate, completedOn);
  if (!nextDate || !isOccurrenceDateWithinSeries(entry, nextDate)) {
    return null;
  }
  return nextDate;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string} [params.requestedDateIso] optional; must match canonical head
 * @param {string} [params.todayIso]
 * @returns {Promise<
 *   | { ok: true, occurrences: object[], created: boolean, next_due_date: string|null, head_date: string }
 *   | { ok: false, error: string, head_date?: string }
 * >}
 */
export async function ensureOpenOccurrence(pool, {
  entry,
  requestedDateIso = null,
  todayIso = todayCalendarIso(),
}) {
  if (entry.status === 'paused') {
    return { ok: false, error: 'entry_paused' };
  }

  const headDate = await resolveCanonicalOpenDateIso(pool, entry, todayIso);
  if (!headDate) {
    return { ok: false, error: 'no_open_date' };
  }

  if (requestedDateIso && requestedDateIso !== headDate) {
    return { ok: false, error: 'not_open_head', head_date: headDate };
  }

  const pendingOnHead = await pool.query(
    `SELECT id FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending' AND scheduled_date = $2::date
     LIMIT 1`,
    [entry.id, headDate],
  );

  let created = false;
  if (pendingOnHead.rows.length === 0) {
    await insertOccurrencesForDay(pool, entry, headDate);
    created = true;
  }

  await syncNextDueDateFromOccurrences(pool, entry.id);

  const openRows = await pool.query(
    `SELECT * FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending' AND scheduled_date = $2::date
     ORDER BY scheduled_time ASC NULLS FIRST`,
    [entry.id, headDate],
  );

  const nextDueDate = dateToIsoDate(
    (
      await pool.query(
        'SELECT next_due_date FROM health_entries WHERE id = $1',
        [entry.id],
      )
    ).rows[0]?.next_due_date,
  );

  return {
    ok: true,
    occurrences: openRows.rows.map(occurrenceToMap),
    created,
    next_due_date: nextDueDate,
    head_date: headDate,
  };
}
