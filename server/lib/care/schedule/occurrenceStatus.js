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

// Status is evaluated for every open row on every read. Keep formatters and
// effective slot times bounded; the costly spring-gap search runs once per
// (zone, date, time), not for every status update.
const FORMATTER_LIMIT = 32;
const SLOT_LIMIT = 512;
const formatters = new Map();
const effectiveTimes = new Map();

function cachedFormatter(timeZone) {
  if (formatters.has(timeZone)) return formatters.get(timeZone);
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone, year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  });
  if (formatters.size >= FORMATTER_LIMIT) formatters.delete(formatters.keys().next().value);
  formatters.set(timeZone, formatter);
  return formatter;
}

/**
 * Keep the stored calendar date and time intact. If a wall time never occurs
 * during a spring-forward gap, its effective due time is the first real
 * minute after the gap (not the requested minute plus the DST jump).
 * Repeated autumn wall times are real and need no adjustment.
 */
function effectiveSlotTime(slot, timeZone) {
  if (!slot.time || !timeZone) return slot.time;
  const key = `${timeZone}|${slot.date}|${slot.time}`;
  if (effectiveTimes.has(key)) return effectiveTimes.get(key);
  const remember = (value) => {
    if (effectiveTimes.size >= SLOT_LIMIT) effectiveTimes.delete(effectiveTimes.keys().next().value);
    effectiveTimes.set(key, value);
    return value;
  };
  const [year, month, day] = slot.date.split('-').map(Number);
  const [hour, minute] = slot.time.split(':').map(Number);
  const naive = Date.UTC(year, month - 1, day, hour, minute);
  const format = cachedFormatter(timeZone);
  const local = (instant) => {
    const parts = format.formatToParts(new Date(instant));
    const part = (name) => Number(parts.find((p) => p.type === name).value);
    return {
      date: `${part('year')}-${String(part('month')).padStart(2, '0')}-${String(part('day')).padStart(2, '0')}`,
      time: `${String(part('hour')).padStart(2, '0')}:${String(part('minute')).padStart(2, '0')}`,
      offset: Date.UTC(part('year'), part('month') - 1, part('day'), part('hour'), part('minute')) - instant,
    };
  };
  // Probe both sides of the local day so a transition's old and new UTC
  // offsets are considered. A normal or repeated wall time matches either.
  const offsets = [...new Set([local(naive - 86400000).offset, local(naive + 86400000).offset])];
  const matches = (time) => offsets.some((offset) => {
    const wall = local(Date.UTC(year, month - 1, day, ...time.split(':').map(Number)) - offset);
    return wall.date === slot.date && wall.time === time;
  });
  if (matches(slot.time)) return remember(slot.time);
  // Only a nonexistent local time reaches here. Advance within this same
  // calendar day to the earliest representable minute.
  for (let next = hour * 60 + minute + 1; next < 1440; next += 1) {
    const time = `${String(Math.floor(next / 60)).padStart(2, '0')}:${String(next % 60).padStart(2, '0')}`;
    if (matches(time)) return remember(time);
  }
  return remember(slot.time);
}

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
  return (asOf.nowTimeIso ?? '00:00') >= effectiveSlotTime(slot, asOf.timeZone);
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
  return (asOf.nowTimeIso ?? '00:00') > effectiveSlotTime(slot, asOf.timeZone);
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
