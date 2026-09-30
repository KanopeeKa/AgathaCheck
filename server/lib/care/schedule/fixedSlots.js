/**
 * Fixed-schedule slots (D-CSM-023) — pure.
 *
 * Stored open slots for a Fixed-schedule item: every series date from
 * today − 3 days through today, the latest series date on or before today
 * (still Overdue until the next one is due), plus the next series date after
 * today, each multiplied by the item's times of day.
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { scheduleTimesFromEntry } from './scheduleTimes.js';
import {
  addDaysIso,
  seriesDateAfter,
  seriesDateOnOrAfter,
  seriesDateOnOrBefore,
  seriesDatesBetween,
  seriesStep,
} from './seriesDates.js';

export const STACK_WINDOW_DAYS = 3;

/**
 * @param {string} todayIso
 * @returns {string} first calendar day still kept open (today − 3)
 */
export function stackWindowStart(todayIso) {
  return addDaysIso(todayIso, -STACK_WINDOW_DAYS);
}

/**
 * @param {object} entry health_entries row
 * @returns {boolean}
 */
export function isFixedSchedule(entry) {
  return (entry?.recurrence_anchor || 'from_completion') === 'from_due_date'
    && Boolean(seriesStep(entry));
}

/**
 * Date slots of the series are counted from (D-CSM-023).
 *
 * @param {object} entry
 * @returns {string|null}
 */
export function scheduleAnchorIso(entry) {
  return dateToIsoDate(entry?.schedule_anchor_date);
}

function maxIso(...values) {
  return values.filter(Boolean).sort().pop() || null;
}

/**
 * Slots that must exist (open or closed) for an active Fixed-schedule item.
 *
 * @param {object} params
 * @param {object} params.entry
 * @param {string} params.todayIso pet-home calendar day
 * @returns {{ date: string, time: string|null }[]}
 */
export function expectedFixedSlots({ entry, todayIso }) {
  if (!isFixedSchedule(entry)) return [];
  if ((entry.status || 'active') !== 'active') return [];
  const anchor = scheduleAnchorIso(entry);
  if (!anchor) return [];
  const floor = maxIso(anchor, stackWindowStart(todayIso), dateToIsoDate(entry.series_resumed_on));
  const endIso = dateToIsoDate(entry.repeat_end_date);

  const dates = floor <= todayIso ? seriesDatesBetween(anchor, entry, floor, todayIso) : [];
  // The latest date on or before today stays open while it is only Overdue
  // (a weekly or monthly dose whose next date has not come yet).
  const resumeFloor = maxIso(anchor, dateToIsoDate(entry.series_resumed_on));
  const latest = seriesDateOnOrBefore(anchor, entry, todayIso);
  if (latest && latest >= resumeFloor && !dates.includes(latest)) dates.unshift(latest);
  const nextAfterToday = seriesDateOnOrAfter(anchor, entry, maxIso(floor, addDaysIso(todayIso, 1)));
  dates.push(nextAfterToday);

  const times = scheduleTimesFromEntry(entry);
  const slots = [];
  for (const date of dates) {
    if (endIso && date > endIso) continue;
    for (const time of times) slots.push({ date, time });
  }
  return slots;
}

/**
 * The series slot that follows a given date/time (used for Not recorded).
 *
 * @param {object} params
 * @param {object} params.entry
 * @param {string} params.date
 * @param {string|null} params.time
 * @returns {{ date: string, time: string|null }|null}
 */
export function nextSeriesSlotAfter({ entry, date, time }) {
  const anchor = scheduleAnchorIso(entry);
  if (!anchor || !seriesStep(entry)) return null;
  const times = scheduleTimesFromEntry(entry);
  const endIso = dateToIsoDate(entry.repeat_end_date);
  const within = (d) => !endIso || d <= endIso;

  const sameDay = seriesDateOnOrAfter(anchor, entry, date);
  if (sameDay === date && time != null) {
    const later = times.find((t) => t != null && t > time);
    if (later && within(date)) return { date, time: later };
  }
  const nextDate = sameDay > date ? sameDay : seriesDateAfter(anchor, entry, date);
  if (!within(nextDate)) return null;
  return { date: nextDate, time: times[0] ?? null };
}

/**
 * @param {{ date: string, time: string|null }} slot
 * @returns {string} sortable key
 */
export function slotKey(slot) {
  return `${slot.date}|${slot.time ?? ''}`;
}
