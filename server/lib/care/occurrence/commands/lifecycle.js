/**
 * Create, edit reconciliation, close and reopen (D-CSM-019, D-CSM-032).
 * None of these is undoable; they write no primary ledger event.
 */

import { dateToIsoDate } from '../../../calendarDate.js';
import { isFixedSchedule } from '../../schedule/fixedSlots.js';
import { slotHasStarted } from '../../schedule/occurrenceStatus.js';
import { scheduleTimesFromEntry } from '../../schedule/scheduleTimes.js';
import { seriesStep } from '../../schedule/seriesDates.js';
import { insertCareScheduleEvent } from '../../schedule/scheduleEventLedger.js';
import { CareCommandError } from '../careCommandError.js';
import { updateEntryFields } from '../entryRepository.js';
import {
  closeAllOpen,
  deleteOpenOccurrences,
  insertOpenOccurrence,
  markSkipped,
  moveOpenOccurrence,
} from '../occurrenceRepository.js';

/**
 * First occurrences of a new planned item — same transaction as the insert.
 *
 * @param {object} ctx
 * @param {{ firstDate: string, plannedDates?: string[] }} params
 */
export async function createInitialOccurrences(ctx, { firstDate: requested, plannedDates = [] }) {
  const { db, entry, trace, asOf } = ctx;
  const firstDate = requested || asOf.todayIso;
  if ((entry.care_planning || 'planned') === 'unplanned' || entry.status === 'completed') {
    return { event: null };
  }
  const times = scheduleTimesFromEntry(entry);
  if (!seriesStep(entry)) {
    for (const time of times) {
      trace.createdRow(await insertOpenOccurrence(db, {
        entryId: entry.id, date: firstDate, time, origin: 'planned',
      }), 'planned');
    }
  } else if (isFixedSchedule(entry)) {
    await updateEntryFields(db, entry.id, { schedule_anchor_date: firstDate });
  } else {
    trace.createdRow(await insertOpenOccurrence(db, {
      entryId: entry.id, date: firstDate, time: times.length === 1 ? times[0] : null, origin: 'computed',
    }), 'computed');
  }
  for (const date of plannedDates) {
    if (!date || date === firstDate) continue;
    trace.createdRow(await insertOpenOccurrence(db, {
      entryId: entry.id, date, time: times.length === 1 ? times[0] : null, origin: 'planned',
    }), 'planned');
  }
  return { event: null };
}

function sameTimes(a, b) {
  return JSON.stringify(scheduleTimesFromEntry(a)) === JSON.stringify(scheduleTimesFromEntry(b));
}

function cadenceChanged(before, after) {
  return (before.frequency || 'once') !== (after.frequency || 'once')
    || Number(before.frequency_interval ?? 1) !== Number(after.frequency_interval ?? 1)
    || Number(before.frequency_days ?? 0) !== Number(after.frequency_days ?? 0);
}

/**
 * Apply schedule edits made through PUT as commands (D-CSM-032).
 *
 * @param {object} ctx context after the row update (entry = new values)
 * @param {{ before: object, requestedNextDate?: string|null }} params
 */
export async function reconcileScheduleEdit(ctx, { before, requestedNextDate = null }) {
  const { db, entry, openRows, asOf } = ctx;
  const changes = [];
  if ((entry.care_planning || 'planned') === 'unplanned' || entry.status === 'completed') {
    return { event: null, result: { changes } };
  }
  const wasFixed = isFixedSchedule(before);
  const isFixed = isFixedSchedule(entry);
  const nowStarted = (o) => slotHasStarted({ date: o.scheduled_date, time: o.scheduled_time }, asOf);
  let anchorFields = null;

  if (wasFixed && !isFixed) {
    for (const row of openRows.filter((o) => o.origin === 'schedule')) {
      await markSkipped(db, { entryId: entry.id, occurrenceId: row.id, closeReason: 'not_recorded' });
    }
    changes.push('fixed_to_after_done');
  } else if (!wasFixed && isFixed) {
    const computed = openRows.filter((o) => o.origin === 'computed');
    const anchor = requestedNextDate || openRows[0]?.scheduled_date || asOf.todayIso;
    await deleteOpenOccurrences(db, entry.id, computed.map((o) => o.id), 'computed');
    anchorFields = { schedule_anchor_date: anchor, series_resumed_on: null };
    changes.push('after_done_to_fixed');
  } else if (isFixed) {
    const future = openRows.filter((o) => o.origin === 'schedule' && !nowStarted(o));
    const rebuild = cadenceChanged(before, entry) || !sameTimes(before, entry)
      || (requestedNextDate && requestedNextDate !== openRows[0]?.scheduled_date);
    if (rebuild) {
      await deleteOpenOccurrences(db, entry.id, future.map((o) => o.id), 'schedule');
      const anchor = requestedNextDate && requestedNextDate !== openRows[0]?.scheduled_date
        ? requestedNextDate
        : (future[0]?.scheduled_date || dateToIsoDate(entry.schedule_anchor_date) || asOf.todayIso);
      anchorFields = { schedule_anchor_date: anchor, series_resumed_on: null };
      changes.push('fixed_rebuilt');
    }
  } else if (requestedNextDate && openRows.length && requestedNextDate !== openRows[0].scheduled_date) {
    const target = openRows[0];
    const moved = await moveOpenOccurrence(db, {
      entryId: entry.id,
      occurrenceId: target.id,
      date: requestedNextDate,
      origin: target.origin === 'computed' ? 'planned' : target.origin,
    });
    if (!moved) {
      throw new CareCommandError(409, 'date_already_planned', 'Another open date already uses that day');
    }
    changes.push('next_date_moved');
  }

  if (!isFixed && !sameTimes(before, entry)) {
    const times = scheduleTimesFromEntry(entry);
    if (times.length === 1) {
      for (const row of openRows.filter((o) => o.origin === 'computed' && !nowStarted(o))) {
        await moveOpenOccurrence(db, {
          entryId: entry.id, occurrenceId: row.id, date: row.scheduled_date, time: times[0],
        });
      }
    }
  }

  const endIso = dateToIsoDate(entry.repeat_end_date);
  if (endIso) {
    for (const row of openRows.filter((o) => o.scheduled_date > endIso)) {
      await markSkipped(db, { entryId: entry.id, occurrenceId: row.id, closeReason: 'system' });
    }
  }
  if (anchorFields) await updateEntryFields(db, entry.id, anchorFields);
  if (changes.length) {
    await insertCareScheduleEvent(db, {
      healthEntryId: entry.id,
      eventType: 'schedule_changed',
      actorUserId: ctx.userId,
      payload: { changes },
    });
  }
  return { event: null, result: { changes } };
}

/**
 * Close a care item and every open date (Archive / legacy Close).
 *
 * @param {object} ctx
 */
export async function closeSeriesCommand(ctx) {
  const { db, entry, userId, asOf } = ctx;
  await closeAllOpen(db, entry.id, userId, 'system');
  const once = !seriesStep(entry);
  await db.query(
    `UPDATE health_entries SET status = 'completed',
       completed_on = CASE WHEN $1 THEN COALESCE(completed_on, $2::date) ELSE completed_on END,
       completed_at = CASE WHEN $1 THEN COALESCE(completed_at, NOW()) ELSE completed_at END,
       repeat_end_date = CASE WHEN $1 THEN NULL ELSE ($2::date - 1) END,
       next_due_date = NULL, paused_since = NULL, paused_until = NULL, updated_at = NOW()
     WHERE id = $3`,
    [once, asOf.todayIso, entry.id],
  );
  return { event: null };
}

/**
 * Reopen a closed item; the sync creates its next date at once.
 *
 * @param {object} ctx
 */
export async function reopenSeriesCommand(ctx) {
  const { db, entry, asOf } = ctx;
  await db.query(
    `UPDATE health_entries SET status = 'active', repeat_end_date = NULL,
       completed_on = CASE WHEN frequency = 'once' OR frequency IS NULL THEN NULL ELSE completed_on END,
       completed_at = NULL, updated_at = NOW()
     WHERE id = $1`,
    [entry.id],
  );
  if (!seriesStep(entry)) {
    await insertOpenOccurrence(db, {
      entryId: entry.id, date: asOf.todayIso, time: null, origin: 'planned',
    });
  }
  return { event: null };
}
