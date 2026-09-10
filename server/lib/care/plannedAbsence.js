/**
 * Planned absence helpers — Care Context V1 (declarer-scoped).
 */

import {
  addCalendarDaysIso,
  normalizeCalendarDateInput,
  todayCalendarIso,
} from '../calendarDate.js';

export const PLANNED_ABSENCE_PROVENANCE_USER_DECLARED = 'user_declared';
export const PLANNED_ABSENCE_STATUS_ACTIVE = 'active';
export const PLANNED_ABSENCE_STATUS_CANCELLED = 'cancelled';

/** Max forward request horizon (calendar months approximated as days). */
export const PLANNED_ABSENCE_MAX_HORIZON_DAYS = 366;

/**
 * @param {string|null|undefined} startsOn
 * @param {string|null|undefined} endsOn
 * @param {string} [todayIso]
 * @returns {{ ok: true, starts_on: string, ends_on: string } | { ok: false, error: string }}
 */
export function validateAbsenceDateWindow(startsOn, endsOn, todayIso = todayCalendarIso()) {
  const starts = normalizeCalendarDateInput(startsOn);
  const ends = normalizeCalendarDateInput(endsOn);
  if (!starts || !ends) {
    return { ok: false, error: 'starts_on and ends_on are required calendar dates (YYYY-MM-DD)' };
  }
  if (ends < starts) {
    return { ok: false, error: 'ends_on must be on or after starts_on' };
  }
  const maxEnd = addCalendarDaysIso(todayIso, PLANNED_ABSENCE_MAX_HORIZON_DAYS);
  if (ends > maxEnd) {
    return { ok: false, error: 'Absence end date exceeds the maximum planning horizon' };
  }
  return { ok: true, starts_on: starts, ends_on: ends };
}

/**
 * Calendar ranges overlap when both are inclusive date intervals.
 *
 * @param {string} aStart
 * @param {string} aEnd
 * @param {string} bStart
 * @param {string} bEnd
 */
export function dateRangesOverlap(aStart, aEnd, bStart, bEnd) {
  return aStart <= bEnd && bStart <= aEnd;
}

/**
 * @param {object} row
 * @param {string[]} petIds
 */
export function absenceToMap(row, petIds = []) {
  return {
    id: row.id,
    user_id: row.user_id,
    starts_on: normalizeCalendarDateInput(row.starts_on),
    ends_on: normalizeCalendarDateInput(row.ends_on),
    provenance: row.provenance || PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
    source_ref: row.source_ref || null,
    status: row.status || PLANNED_ABSENCE_STATUS_ACTIVE,
    pet_ids: petIds,
    created_at: row.created_at?.toISOString?.() || String(row.created_at),
    updated_at: row.updated_at?.toISOString?.() || String(row.updated_at),
    cancelled_at: row.cancelled_at
      ? row.cancelled_at.toISOString?.() || String(row.cancelled_at)
      : null,
  };
}

/**
 * Active for overlap/list: not cancelled and ends_on >= today.
 *
 * @param {string} [todayIso]
 */
export function activeAbsenceSqlPredicate(todayIso = todayCalendarIso()) {
  return {
    sql: `pa.status != $cancelled AND pa.ends_on >= $today::date`,
    params: { cancelled: PLANNED_ABSENCE_STATUS_CANCELLED, today: todayIso },
  };
}
