/**
 * Status of one open occurrence (D-CIE-024) — pure.
 *
 * coming_up · due · overdue · not_recorded. "Now" is the pet's home wall
 * clock supplied by the server (D-CIE-028).
 */

import { isFixedSchedule, nextSeriesSlotAfter } from './fixedSlots.js';

export const OCCURRENCE_STATUS_COMING_UP = 'coming_up';
export const OCCURRENCE_STATUS_DUE = 'due';
export const OCCURRENCE_STATUS_OVERDUE = 'overdue';
export const OCCURRENCE_STATUS_NOT_RECORDED = 'not_recorded';

/**
 * A slot's own moment has arrived (untimed: its day has started).
 *
 * @param {{ date: string, time: string|null }} slot
 * @param {{ todayIso: string, nowTimeIso?: string|null }} asOf
 * @returns {boolean}
 */
export function slotHasStarted(slot, asOf) {
  if (slot.date < asOf.todayIso) return true;
  if (slot.date > asOf.todayIso) return false;
  if (slot.time == null) return true;
  return (asOf.nowTimeIso ?? '00:00') >= slot.time;
}

/**
 * Past its time (timed) or its day (untimed).
 *
 * @param {{ date: string, time: string|null }} slot
 * @param {{ todayIso: string, nowTimeIso?: string|null }} asOf
 * @returns {boolean}
 */
export function slotIsPastDue(slot, asOf) {
  if (slot.date < asOf.todayIso) return true;
  if (slot.date > asOf.todayIso) return false;
  if (slot.time == null) return false;
  return (asOf.nowTimeIso ?? '00:00') > slot.time;
}

/**
 * @param {object} params
 * @param {{ scheduled_date: string, scheduled_time: string|null }} params.occurrence
 * @param {object} params.entry health_entries row
 * @param {{ todayIso: string, nowTimeIso?: string|null }} params.asOf
 * @returns {'coming_up'|'due'|'overdue'|'not_recorded'}
 */
export function occurrenceStatus({ occurrence, entry, asOf }) {
  const slot = { date: occurrence.scheduled_date, time: occurrence.scheduled_time ?? null };
  if (slot.date > asOf.todayIso) return OCCURRENCE_STATUS_COMING_UP;
  if (!slotIsPastDue(slot, asOf)) return OCCURRENCE_STATUS_DUE;
  if (isFixedSchedule(entry)) {
    const next = nextSeriesSlotAfter({ entry, date: slot.date, time: slot.time });
    if (next && slotHasStarted(next, asOf)) return OCCURRENCE_STATUS_NOT_RECORDED;
  }
  return OCCURRENCE_STATUS_OVERDUE;
}
