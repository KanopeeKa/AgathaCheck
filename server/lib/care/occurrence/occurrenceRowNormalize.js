/**
 * Calendar-safe shaping of `health_occurrences` rows.
 */

import { dateToIsoDate } from '../../calendarDate.js';

/**
 * @param {object} row
 * @returns {{ date: string, time: string|null }}
 */
export function rowSlot(row) {
  return {
    date: dateToIsoDate(row.scheduled_date),
    time: row.scheduled_time ? String(row.scheduled_time).slice(0, 5) : null,
  };
}

/**
 * @param {object} row DB row
 * @returns {object} row with calendar strings
 */
export function normalizeOccurrenceRow(row) {
  if (!row) return row;
  const slot = rowSlot(row);
  return {
    ...row,
    scheduled_date: slot.date,
    scheduled_time: slot.time,
    series_date: row.series_date ? dateToIsoDate(row.series_date) : null,
    completed_on: row.completed_on ? dateToIsoDate(row.completed_on) : null,
    origin: row.origin || 'computed',
  };
}
