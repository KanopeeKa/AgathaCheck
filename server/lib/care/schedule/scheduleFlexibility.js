/**
 * Read-only schedule flexibility (D-ACP-006).
 */

import { advanceByFrequency, toDateOnly } from '../../recurrenceHelper.js';
import { todayCalendarIso } from '../../calendarDate.js';

const FIXED_CARE_SOURCES = new Set(['vet_instruction', 'treatment_schedule']);
const EARLIER_ONLY_CARE_FAMILIES = new Set(['vaccination', 'parasite_prevention']);

/**
 * @param {string} fromIso
 * @param {string} toIso
 * @returns {number}
 */
export function calendarDayDiff(fromIso, toIso) {
  const fromMs = toDateOnly(fromIso).getTime();
  const toMs = toDateOnly(toIso).getTime();
  return Math.round((toMs - fromMs) / 86_400_000);
}

/**
 * Day gap of one advanceByFrequency step from [todayIso].
 *
 * @param {object} entry health_entries row
 * @param {string} [todayIso]
 * @returns {number}
 */
export function intervalDaysForEntry(entry, todayIso = todayCalendarIso()) {
  const base = todayIso || todayCalendarIso();
  const next = advanceByFrequency(base, entry);
  return Math.max(1, calendarDayDiff(base, next));
}

/**
 * @param {object} entry
 * @returns {boolean}
 */
function isCarerTask(entry) {
  const times = entry.schedule_times;
  if (Array.isArray(times) && times.length > 1) return true;
  const freq = entry.frequency || 'once';
  if (freq === 'daily') return true;
  const customDays = entry.frequency_days;
  if (customDays != null && Number(customDays) < 7) return true;
  if (freq === 'custom') {
    const step = Number(customDays ?? entry.frequency_interval ?? 1);
    if (step < 7) return true;
  }
  return false;
}

/**
 * @param {object} entry health_entries row
 * @param {string} [todayIso] YYYY-MM-DD
 * @returns {{ flexibility: string, max_shift_days: number }}
 */
export function resolveScheduleFlexibility(entry, todayIso = todayCalendarIso()) {
  const careSource = entry.care_source || 'guardian_defined';
  if (FIXED_CARE_SOURCES.has(careSource)) {
    return { flexibility: 'fixed', max_shift_days: 0 };
  }

  const careFamily = entry.care_family || '';
  if (EARLIER_ONLY_CARE_FAMILIES.has(careFamily)) {
    const intervalDays = intervalDaysForEntry(entry, todayIso);
    return {
      flexibility: 'earlier_only',
      max_shift_days: Math.min(7, Math.floor(intervalDays * 0.1)),
    };
  }

  if (isCarerTask(entry)) {
    return { flexibility: 'carer_task', max_shift_days: 0 };
  }

  const intervalDays = intervalDaysForEntry(entry, todayIso);
  return {
    flexibility: 'flexible',
    max_shift_days: Math.min(14, Math.floor(intervalDays * 0.25)),
  };
}
