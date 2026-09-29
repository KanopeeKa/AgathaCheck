/**
 * After-it's-done rule (D-CSM-022) — pure.
 */

import { addSteps, seriesStep } from './seriesDates.js';

/**
 * Next computed date after the last qualifying closed occurrence.
 * Done → done date + interval; skipped by a person → max(due, today) + interval.
 * No qualifying close yet (a new item, or only Not recorded doses after a
 * type switch) → the item's first date, else today.
 *
 * @param {object} params
 * @param {object} params.entry
 * @param {{ status: string, scheduled_date: string, completed_on?: string|null }|null} params.lastClosed
 * @param {string} params.todayIso
 * @param {string|null} [params.firstDate] the date the person set (next_due_date / start_date)
 * @returns {string|null}
 */
export function nextComputedDate({ entry, lastClosed, todayIso, firstDate = null }) {
  if (!seriesStep(entry)) return null;
  if (!lastClosed) return firstDate || todayIso;
  if (lastClosed.status === 'completed') {
    return addSteps(lastClosed.completed_on || lastClosed.scheduled_date, entry, 1);
  }
  const base = lastClosed.scheduled_date > todayIso ? lastClosed.scheduled_date : todayIso;
  return addSteps(base, entry, 1);
}

/**
 * "Estimated next" for an overdue After-it's-done item: today + interval.
 * Display only — never a row, an action or a reminder.
 *
 * @param {object} params
 * @param {object} params.entry
 * @param {string} params.todayIso
 * @returns {string|null}
 */
export function estimatedNextWhileOverdue({ entry, todayIso }) {
  if (!seriesStep(entry)) return null;
  return addSteps(todayIso, entry, 1);
}
