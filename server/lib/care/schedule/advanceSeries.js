/**
 * Unified series rollover (CSM-3).
 *
 * When all pending occurrences for the earliest open date are closed, compute the
 * next series date via anchor-aware advanceByFrequency — never calendar +1 shortcuts.
 */

import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { advanceByFrequency } from '../../recurrenceHelper.js';
import {
  finalizeOnceEntryIfNoPending,
  isEntrySeriesClosed,
  isOccurrenceDateWithinSeries,
  tryAutoCloseRecurringWithEndDate,
} from '../../occurrenceLifecycle.js';
import {
  insertOccurrencesForDay,
  isOnceEntry,
  isWithinMaterialisationWindow,
  materialisationAnchor,
  syncNextDueDateFromOccurrences,
} from '../../occurrenceScheduling.js';

/**
 * Anchor-aware next series date after a calendar day is fully closed.
 *
 * @param {object} entry health_entries row
 * @param {string} closedScheduledDate YYYY-MM-DD of the due day that closed
 * @param {string|null|undefined} completedOn YYYY-MM-DD actual completion (last slot)
 * @returns {string}
 */
export function resolveNextSeriesDate(entry, closedScheduledDate, completedOn) {
  const anchor = entry.recurrence_anchor || 'from_completion';
  const completedIso = dateToIsoDate(completedOn) || closedScheduledDate;
  const base = anchor === 'from_due_date'
    ? closedScheduledDate
    : completedIso;
  return advanceByFrequency(base, entry);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 * @param {string} [todayIso]
 */
export async function advanceSeries(pool, entry, todayIso = todayCalendarIso()) {
  if (isEntrySeriesClosed(entry, todayIso)) {
    await syncNextDueDateFromOccurrences(pool, entry.id);
    return;
  }

  if (isOnceEntry(entry)) {
    await syncNextDueDateFromOccurrences(pool, entry.id);
    await finalizeOnceEntryIfNoPending(pool, entry);
    return;
  }

  const earliestPending = await pool.query(
    `SELECT scheduled_date FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending'
     ORDER BY scheduled_date ASC
     LIMIT 1`,
    [entry.id],
  );

  if (earliestPending.rows.length > 0) {
    await syncNextDueDateFromOccurrences(pool, entry.id);
    await tryAutoCloseRecurringWithEndDate(pool, entry, todayIso);
    return;
  }

  const lastClosed = await pool.query(
    `SELECT scheduled_date, completed_on FROM health_occurrences
     WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
     ORDER BY scheduled_date DESC,
       COALESCE(scheduled_time, '00:00:00'::time) DESC
     LIMIT 1`,
    [entry.id],
  );

  const closedScheduledDate = lastClosed.rows[0]
    ? dateToIsoDate(lastClosed.rows[0].scheduled_date)
    : materialisationAnchor(dateToIsoDate(entry.start_date), todayIso);
  const completedOn = lastClosed.rows[0]?.completed_on
    ? dateToIsoDate(lastClosed.rows[0].completed_on)
    : closedScheduledDate;

  const nextDate = resolveNextSeriesDate(entry, closedScheduledDate, completedOn);

  if (
    nextDate
    && isOccurrenceDateWithinSeries(entry, nextDate)
    && (isWithinMaterialisationWindow(nextDate, todayIso) || nextDate <= todayIso)
  ) {
    await insertOccurrencesForDay(pool, entry, nextDate);
  }

  await syncNextDueDateFromOccurrences(pool, entry.id);
  await tryAutoCloseRecurringWithEndDate(pool, entry, todayIso);
}
