/**
 * Create/edit rules for the schedule shape (D-CSM-020, D-CIE-027).
 */

import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';

/**
 * @param {object} params
 * @param {string} params.carePlanning planned | unplanned
 * @param {string|null} params.completedOn
 * @param {string} params.recurrenceAnchor
 * @param {string} params.frequency
 * @param {string[]|null|undefined} params.scheduleTimes
 * @param {unknown} [params.plannedDates] booster / extra planned dates on create
 * @param {string|null} [params.existingCompletedOn] edit: completed_on already stored
 * @returns {{ ok: true, plannedDates: string[] } | { ok: false, error: string, code: string }}
 */
export function validateScheduleShape({
  carePlanning,
  completedOn,
  recurrenceAnchor,
  frequency,
  scheduleTimes,
  plannedDates = undefined,
  existingCompletedOn = null,
}) {
  if (carePlanning !== 'unplanned' && completedOn && completedOn !== existingCompletedOn) {
    return {
      ok: false,
      code: 'completed_on_not_allowed',
      error: 'Planned care takes a due date, not a completed date',
    };
  }
  const times = Array.isArray(scheduleTimes) ? scheduleTimes.filter(Boolean) : [];
  if (
    (frequency || 'once') !== 'once'
    && recurrenceAnchor === 'from_completion'
    && times.length > 1
  ) {
    return {
      ok: false,
      code: 'times_require_fixed_schedule',
      error: 'Several times of day need a fixed schedule',
    };
  }
  let dates = [];
  if (plannedDates != null) {
    if (!Array.isArray(plannedDates)) {
      return { ok: false, code: 'invalid_planned_dates', error: 'planned_dates must be a list of dates' };
    }
    dates = plannedDates.map((d) => normalizeCalendarDateInput(d));
    if (dates.some((d) => !d)) {
      return { ok: false, code: 'invalid_planned_dates', error: 'planned_dates must be a list of dates' };
    }
  }
  return { ok: true, plannedDates: dates };
}
