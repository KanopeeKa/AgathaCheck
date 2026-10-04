import { dateToIsoDate } from '../../calendarDate.js';
import { addDaysIso, nominalIntervalDays } from '../schedule/seriesDates.js';

/**
 * Lower bound of the CSM half-interval window (D-WM-004).
 *
 * @param {object} entry health_entries row
 * @param {{ scheduled_date: string }} occurrence
 * @returns {string} YYYY-MM-DD
 */
export function fulfilmentWindowStart(entry, occurrence) {
  const scheduled = dateToIsoDate(occurrence.scheduled_date);
  const intervalDays = nominalIntervalDays(entry, scheduled);
  if (!intervalDays) return scheduled;
  const half = Math.floor(intervalDays / 2);
  return addDaysIso(scheduled, -half);
}

/**
 * @param {{
 *   entry: { care_family?: string|null, status?: string, start_date?: string|Date|null },
 *   occurrence: { status?: string, scheduled_date: string|Date },
 *   dateIso: string,
 *   todayIso: string,
 *   latestCompletedOn: string|null,
 * }} params
 * @returns {boolean}
 */
export function isFulfilmentEligible({
  entry,
  occurrence,
  dateIso,
  todayIso,
  latestCompletedOn,
}) {
  if (entry.care_family !== 'weight_monitoring') return false;
  if (entry.status !== 'active') return false;
  if (occurrence.status !== 'pending') return false;
  if (dateIso > todayIso) return false;
  const windowStart = fulfilmentWindowStart(entry, occurrence);
  if (dateIso < windowStart) return false;
  const startDate = entry.start_date ? dateToIsoDate(entry.start_date) : null;
  if (startDate && dateIso < startDate) return false;
  if (latestCompletedOn && dateIso < latestCompletedOn) return false;
  return true;
}
