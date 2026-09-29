/**
 * Done after the due date with a waiting date (D-CSM-026) — pure.
 */

import { daysBetween } from './seriesDates.js';

export const NEXT_CHOICE_KEEP = 'keep';
export const NEXT_CHOICE_SKIP_NEXT = 'skip_next';
export const NEXT_CHOICE_SHIFT_FOLLOWING = 'shift_following';
export const NEXT_CHOICES = [NEXT_CHOICE_KEEP, NEXT_CHOICE_SKIP_NEXT, NEXT_CHOICE_SHIFT_FOLLOWING];

/**
 * @param {string|null} time HH:MM
 * @returns {number}
 */
function minutesOfDay(time) {
  if (!time) return 0;
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
}

/**
 * @param {string} date
 * @param {string|null} time
 * @returns {number} minutes since 2000-01-01
 */
export function instantMinutes(date, time) {
  return daysBetween('2000-01-01', date) * 1440 + minutesOfDay(time);
}

/**
 * The open date the late completion affects: the earliest open `planned` or
 * `schedule` occurrence after the closed one that is still in the future.
 *
 * @param {object} params
 * @param {{ id: string, scheduled_date: string, scheduled_time: string|null }} params.closed
 * @param {object[]} params.openOccurrences other open rows (origin, scheduled_date, scheduled_time)
 * @param {{ todayIso: string, nowTimeIso?: string|null }} params.asOf
 * @returns {object|null}
 */
export function pickWaitingOccurrence({ closed, openOccurrences, asOf }) {
  const closedAt = instantMinutes(closed.scheduled_date, closed.scheduled_time);
  const nowAt = instantMinutes(asOf.todayIso, asOf.nowTimeIso ?? '00:00');
  const candidates = openOccurrences
    .filter((o) => o.id !== closed.id)
    .filter((o) => o.origin === 'planned' || o.origin === 'schedule')
    .filter((o) => {
      const at = instantMinutes(o.scheduled_date, o.scheduled_time);
      return at > closedAt && at > nowAt;
    })
    .sort((a, b) => instantMinutes(a.scheduled_date, a.scheduled_time)
      - instantMinutes(b.scheduled_date, b.scheduled_time));
  return candidates[0] || null;
}

/**
 * Whether completing `closed` late needs the next-date choice.
 *
 * Timed slots compare minutes, otherwise days. The choice is needed when the
 * completion is after the due moment and the gap to the waiting date shrank
 * by more than half of the originally planned gap.
 *
 * @param {object} params
 * @param {{ scheduled_date: string, scheduled_time: string|null }} params.closed
 * @param {{ scheduled_date: string, scheduled_time: string|null }|null} params.waiting
 * @param {string} params.completedOn YYYY-MM-DD
 * @param {string|null} [params.completedTime] HH:MM when done today; else the slot's time
 * @param {boolean} [params.multiTime] item has several times of day
 * @returns {{ required: false } | { required: true, shift: { days?: number, minutes?: number }, options: string[] }}
 */
export function evaluateNextChoice({
  closed,
  waiting,
  completedOn,
  completedTime = null,
  multiTime = false,
}) {
  if (!waiting) return { required: false };
  const timed = closed.scheduled_time != null && waiting.scheduled_time != null;

  let due;
  let done;
  let next;
  if (timed) {
    due = instantMinutes(closed.scheduled_date, closed.scheduled_time);
    done = instantMinutes(completedOn, completedTime ?? closed.scheduled_time);
    next = instantMinutes(waiting.scheduled_date, waiting.scheduled_time);
  } else {
    due = daysBetween('2000-01-01', closed.scheduled_date);
    done = daysBetween('2000-01-01', completedOn);
    next = daysBetween('2000-01-01', waiting.scheduled_date);
  }
  if (done <= due) return { required: false };
  const original = next - due;
  const remaining = next - done;
  if (original <= 0 || remaining * 2 >= original) return { required: false };

  const lateBy = done - due;
  const minuteShift = timed && lateBy % 1440 !== 0;
  const shift = timed
    ? (minuteShift ? { minutes: lateBy } : { days: lateBy / 1440 })
    : { days: lateBy };
  const options = [NEXT_CHOICE_KEEP, NEXT_CHOICE_SKIP_NEXT];
  if (!(minuteShift && multiTime)) options.push(NEXT_CHOICE_SHIFT_FOLLOWING);
  return { required: true, shift, options };
}
