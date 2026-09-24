/**
 * Reschedule validation + non-blocking warnings (D-ACP-009).
 */

import { advanceByFrequency } from '../../recurrenceHelper.js';
import { dateToIsoDate } from '../../calendarDate.js';
import {
  calendarDayDiff,
  intervalDaysForEntry,
  resolveScheduleFlexibility,
} from './scheduleFlexibility.js';
import { RECURRENCE_ANCHOR_FROM_DUE_DATE } from './recurrenceAnchorDefaults.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry
 * @returns {Promise<string|null>}
 */
export async function loadLastClosedOccurrenceDateIso(pool, entry) {
  const result = await pool.query(
    `SELECT scheduled_date, completed_on
     FROM health_occurrences
     WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
     ORDER BY scheduled_date DESC, COALESCE(completed_on, scheduled_date) DESC
     LIMIT 1`,
    [entry.id],
  );
  const row = result.rows[0];
  if (!row) return null;
  const anchor = entry.recurrence_anchor || 'from_completion';
  if (anchor === RECURRENCE_ANCHOR_FROM_DUE_DATE) {
    return dateToIsoDate(row.scheduled_date);
  }
  return dateToIsoDate(row.completed_on || row.scheduled_date);
}

/**
 * @param {object} params
 * @param {object} params.entry
 * @param {string} params.occurrenceScheduledDate YYYY-MM-DD
 * @param {string} params.newDate YYYY-MM-DD
 * @param {string} params.todayIso YYYY-MM-DD
 * @param {string|null} [params.lastClosedDate]
 * @returns {{ ok: true, warnings: object[] } | { ok: false, error: string }}
 */
export function validateReschedule({
  entry,
  occurrenceScheduledDate,
  newDate,
  todayIso,
  lastClosedDate = null,
}) {
  if (newDate < todayIso) {
    return { ok: false, error: 'scheduled_date cannot be in the past' };
  }
  if (newDate === occurrenceScheduledDate) {
    return { ok: false, error: 'scheduled_date unchanged' };
  }

  const frequency = entry.frequency || 'once';
  const warnings = [];

  if (frequency !== 'once') {
    const nextHop = advanceByFrequency(occurrenceScheduledDate, entry);
    if (newDate >= nextHop) {
      return {
        ok: false,
        error: 'scheduled_date cannot be on or after the next series occurrence',
      };
    }
    if (lastClosedDate && newDate <= lastClosedDate) {
      return {
        ok: false,
        error: 'scheduled_date cannot be on or before the last closed occurrence',
      };
    }
  }

  const flex = resolveScheduleFlexibility(entry, todayIso);
  const shiftDays = Math.abs(calendarDayDiff(occurrenceScheduledDate, newDate));

  if (flex.flexibility === 'earlier_only' && newDate > occurrenceScheduledDate) {
    warnings.push({ code: 'earlier_only_later_move' });
  }

  if (flex.flexibility === 'fixed' || flex.flexibility === 'carer_task') {
    if (shiftDays > 0) {
      warnings.push({
        code: 'outside_flexibility',
        flexibility: flex.flexibility,
        max_shift_days: flex.max_shift_days,
      });
    }
  } else if (shiftDays > flex.max_shift_days) {
    warnings.push({
      code: 'outside_flexibility',
      flexibility: flex.flexibility,
      max_shift_days: flex.max_shift_days,
    });
  }

  if (frequency !== 'once' && lastClosedDate) {
    const previousGapDays = calendarDayDiff(lastClosedDate, newDate);
    const usualGapDays = intervalDaysForEntry(entry, todayIso);
    if (previousGapDays !== usualGapDays) {
      warnings.push({
        code: 'interval_changed',
        previous_gap_days: previousGapDays,
        usual_gap_days: usualGapDays,
      });
    }
  }

  return { ok: true, warnings };
}
