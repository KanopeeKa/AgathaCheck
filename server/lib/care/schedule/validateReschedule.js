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
  const map = await loadLastClosedOccurrenceDatesByEntryId(pool, [entry]);
  return map.get(entry.id) ?? null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object[]} entries
 * @returns {Promise<Map<string, string|null>>}
 */
export async function loadLastClosedOccurrenceDatesByEntryId(pool, entries) {
  const ids = (entries || []).map((row) => row.id).filter(Boolean);
  const resultMap = new Map();
  if (ids.length === 0) return resultMap;

  const result = await pool.query(
    `SELECT DISTINCT ON (health_entry_id)
       health_entry_id,
       scheduled_date,
       completed_on
     FROM health_occurrences
     WHERE health_entry_id = ANY($1::uuid[])
       AND status IN ('completed', 'skipped')
     ORDER BY health_entry_id, scheduled_date DESC,
       COALESCE(completed_on, scheduled_date) DESC`,
    [ids],
  );

  const entryById = new Map((entries || []).map((row) => [row.id, row]));
  for (const id of ids) {
    resultMap.set(id, null);
  }
  for (const row of result.rows) {
    const entry = entryById.get(row.health_entry_id);
    if (!entry) continue;
    const anchor = entry.recurrence_anchor || 'from_completion';
    if (anchor === RECURRENCE_ANCHOR_FROM_DUE_DATE) {
      resultMap.set(row.health_entry_id, dateToIsoDate(row.scheduled_date));
    } else {
      resultMap.set(
        row.health_entry_id,
        dateToIsoDate(row.completed_on || row.scheduled_date),
      );
    }
  }
  return resultMap;
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
      care_source: entry.care_source ?? null,
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
