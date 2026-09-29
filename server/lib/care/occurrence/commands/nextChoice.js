/**
 * Apply Keep / Skip next / Move this and following (D-CSM-026).
 */

import { dateToIsoDate } from '../../../calendarDate.js';
import { isFixedSchedule } from '../../schedule/fixedSlots.js';
import { instantMinutes } from '../../schedule/lateCompletion.js';
import { scheduleTimesFromEntry } from '../../schedule/scheduleTimes.js';
import { addDaysIso } from '../../schedule/seriesDates.js';
import { updateEntryFields } from '../entryRepository.js';
import {
  deleteOpenOccurrences,
  markSkipped,
  moveOpenOccurrence,
} from '../occurrenceRepository.js';

function addMinutesToTime(time, minutes) {
  const [h, m] = time.split(':').map(Number);
  const total = h * 60 + m + minutes;
  const dayShift = Math.floor(total / 1440);
  const t = ((total % 1440) + 1440) % 1440;
  return {
    time: `${String(Math.floor(t / 60)).padStart(2, '0')}:${String(t % 60).padStart(2, '0')}`,
    dayShift,
  };
}

/**
 * Fixed schedule: move the series phase; open future slots are rebuilt by sync.
 */
async function shiftFixedSchedule(ctx, { waiting, shift, completedOn }) {
  const { db, entry, trace } = ctx;
  const anchor = dateToIsoDate(entry.schedule_anchor_date) || waiting.scheduled_date;
  const fields = { series_resumed_on: addDaysIso(completedOn, 1) };
  if (shift.minutes != null) {
    const times = scheduleTimesFromEntry(entry);
    const moved = addMinutesToTime(times[0], shift.minutes);
    fields.schedule_times = [moved.time];
    fields.schedule_anchor_date = addDaysIso(anchor, moved.dayShift);
  } else {
    fields.schedule_anchor_date = addDaysIso(anchor, shift.days);
  }
  const waitingAt = instantMinutes(waiting.scheduled_date, waiting.scheduled_time);
  const futureSlots = ctx.openRows.filter((o) => o.origin === 'schedule'
    && instantMinutes(o.scheduled_date, o.scheduled_time) >= waitingAt);
  // Undo restores the anchor; the sync then rebuilds these slots.
  await deleteOpenOccurrences(db, entry.id, futureSlots.map((o) => o.id), 'schedule');
  await updateEntryFields(db, entry.id, fields);
  trace.markEntryChanged();
}

/**
 * After it's done: shift every waiting planned date after the closed one.
 */
async function shiftPlannedDates(ctx, { closed, shift, remainingOpen }) {
  const { db, entry, trace } = ctx;
  const days = shift.days ?? Math.round((shift.minutes ?? 0) / 1440);
  if (!days) return;
  const closedAt = instantMinutes(closed.scheduled_date, closed.scheduled_time);
  const later = remainingOpen.filter((o) => o.origin === 'planned'
    && instantMinutes(o.scheduled_date, o.scheduled_time) > closedAt)
    .sort((a, b) => instantMinutes(b.scheduled_date, b.scheduled_time)
      - instantMinutes(a.scheduled_date, a.scheduled_time));
  for (const row of later) {
    trace.movedRow(row);
    await moveOpenOccurrence(db, {
      entryId: entry.id,
      occurrenceId: row.id,
      date: addDaysIso(row.scheduled_date, days),
    });
  }
}

/**
 * @param {object} ctx
 * @param {object} params
 */
export async function applyNextChoice(ctx, {
  choice, closed, waiting, shift, completedOn, remainingOpen,
}) {
  if (choice === 'keep') return;
  if (choice === 'skip_next') {
    await markSkipped(ctx.db, {
      entryId: ctx.entry.id,
      occurrenceId: waiting.id,
      closeReason: 'user',
      userId: ctx.userId,
    });
    ctx.trace.closedRow(waiting);
    return;
  }
  if (isFixedSchedule(ctx.entry)) {
    await shiftFixedSchedule(ctx, { waiting, shift, completedOn });
  } else {
    await shiftPlannedDates(ctx, { closed, shift, remainingOpen });
  }
}
