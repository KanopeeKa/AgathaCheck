/**
 * Pure candidate dates for rescheduling the open occurrence (D-ACP-008, BR-2).
 */

import { addCalendarDaysIso } from '../../calendarDate.js';
import { isDateInCareWindow } from '../schedule/projectSchedule.js';
import { resolveNextSeriesDate } from '../schedule/index.js';

/**
 * @param {object} params
 * @param {object} params.entry
 * @param {object} params.openOccurrence `{ scheduled_date }`
 * @param {string} params.today YYYY-MM-DD
 * @param {string} params.startsOn
 * @param {string} params.endsOn
 * @param {string|null} params.lastClosedDate
 * @param {number} params.maxShiftDays
 * @param {string} params.flexibility
 * @returns {{ date: string, direction: 'earlier' | 'later', k: number }[]}
 */
export function candidateMoves({
  entry,
  openOccurrence,
  today,
  startsOn,
  endsOn,
  lastClosedDate,
  maxShiftDays,
  flexibility,
}) {
  if (!openOccurrence?.scheduled_date || maxShiftDays <= 0) {
    return [];
  }

  const fromDate = openOccurrence.scheduled_date;
  const nextHop = resolveNextSeriesDate(entry, fromDate, fromDate);
  const allowLater = flexibility !== 'earlier_only';
  const candidates = [];

  for (let k = 1; k <= maxShiftDays; k += 1) {
    const shifts = allowLater
      ? [
          { direction: 'earlier', date: addCalendarDaysIso(fromDate, -k) },
          { direction: 'later', date: addCalendarDaysIso(fromDate, k) },
        ]
      : [{ direction: 'earlier', date: addCalendarDaysIso(fromDate, -k) }];

    for (const { direction, date } of shifts) {
      if (date < today) continue;
      if (isDateInCareWindow(date, startsOn, endsOn)) continue;
      if (lastClosedDate && date <= lastClosedDate) continue;
      if (nextHop && date >= nextHop) continue;
      candidates.push({ date, direction, k });
    }
  }

  return candidates;
}
