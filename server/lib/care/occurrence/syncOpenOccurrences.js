/**
 * Restore the occurrence invariants for one care item (INV-1 … INV-5).
 *
 * Runs at the start (catch-up) and end of every command and from the care
 * tick, always inside `withCareItemLock`:
 *
 * 1. `paused_until` reached → resume (Fixed schedule).
 * 2. Fixed schedule: slots older than today − 3 close as Not recorded.
 * 3. Fixed schedule, active: create the missing D-CSM-023 slots.
 * 4. After it's done, active: nothing open → create the computed next date.
 * 5. End date: nothing open and nothing more to create → the item finishes.
 * 6. `next_due_date` = earliest open occurrence.
 */

import { dateToIsoDate } from '../../calendarDate.js';
import {
  expectedFixedSlots,
  isFixedSchedule,
  nextSeriesSlotAfter,
  scheduleAnchorIso,
  stackWindowStart,
} from '../schedule/fixedSlots.js';
import { nextComputedDate } from '../schedule/nextComputed.js';
import { scheduleTimesFromEntry } from '../schedule/scheduleTimes.js';
import { seriesDateAfter, seriesStep } from '../schedule/seriesDates.js';
import { insertCareScheduleEvent } from '../schedule/scheduleEventLedger.js';
import { reloadEntry, updateEntryFields } from './entryRepository.js';
import {
  deleteOpenOccurrences,
  existingSeriesSlotKeys,
  insertOpenOccurrence,
  lastRuleClosedRow,
  listOpenRows,
  markSkipped,
} from './occurrenceRepository.js';

/**
 * @param {object} entry
 * @returns {boolean} planned care that keeps a schedule
 */
export function isPlannedCare(entry) {
  return (entry.care_planning || 'planned') !== 'unplanned';
}

/**
 * @param {object} entry
 * @returns {boolean}
 */
export function isRecurring(entry) {
  return Boolean(seriesStep(entry));
}

async function resumeIfPausedUntilReached(db, entry, asOf) {
  const until = dateToIsoDate(entry.paused_until);
  if (entry.status !== 'paused' || !until || until > asOf.todayIso) return entry;
  const resumed = await updateEntryFields(db, entry.id, {
    status: 'active',
    paused_since: null,
    paused_until: null,
    series_resumed_on: until,
  });
  await insertCareScheduleEvent(db, {
    healthEntryId: entry.id,
    eventType: 'resumed',
    fromDate: dateToIsoDate(entry.paused_since),
    toDate: until,
    reasonCode: 'paused_until_reached',
    payload: { automatic: true },
  });
  return resumed;
}

/**
 * A Not recorded dose closes once the dose after it fell on or before
 * today − 3 (for daily care: doses dated before today − 3). A dose that is
 * still only Overdue — its next dose not due yet — is never closed here.
 */
async function closeStackOutsideWindow(db, entry, asOf) {
  const windowStart = stackWindowStart(asOf.todayIso);
  const open = await listOpenRows(db, entry.id);
  const closed = [];
  for (const row of open) {
    if (row.scheduled_date >= windowStart) continue;
    const next = nextSeriesSlotAfter({ entry, date: row.scheduled_date, time: row.scheduled_time });
    if (!next || next.date > windowStart) continue;
    const done = await markSkipped(db, {
      entryId: entry.id,
      occurrenceId: row.id,
      closeReason: 'not_recorded',
    });
    if (done) closed.push(row.id);
  }
  if (closed.length) {
    await insertCareScheduleEvent(db, {
      healthEntryId: entry.id,
      eventType: 'not_recorded_closed',
      toDate: windowStart,
      payload: { occurrence_ids: closed },
    });
  }
  return closed;
}

/**
 * The next series date must have an open slot (INV-1). When a person already
 * closed it (Skip, Skip next), the date after it takes its place.
 */
function withOpenFutureDate(entry, slots, existing, todayIso) {
  const future = slots.filter((s) => s.date > todayIso);
  if (future.length === 0) return slots;
  const futureDate = future[0].date;
  const times = scheduleTimesFromEntry(entry);
  const endIso = dateToIsoDate(entry.repeat_end_date);
  let date = futureDate;
  for (let i = 0; i < 12; i += 1) {
    const allClosed = times.every((t) => {
      const status = existing.get(`${date}|${t ?? ''}`);
      return status && status !== 'pending';
    });
    if (!allClosed) break;
    date = seriesDateAfter(scheduleAnchorIso(entry), entry, date);
    if (endIso && date > endIso) return slots;
    if (!slots.some((s) => s.date === date)) {
      for (const time of times) slots.push({ date, time });
    }
  }
  return slots;
}

async function createMissingFixedSlots(db, entry, asOf) {
  let slots = expectedFixedSlots({ entry, todayIso: asOf.todayIso });
  if (slots.length === 0) return [];
  const existing = await existingSeriesSlotKeys(db, entry.id, slots[0].date);
  slots = withOpenFutureDate(entry, slots, existing, asOf.todayIso);
  const created = [];
  for (const slot of slots) {
    if (existing.has(`${slot.date}|${slot.time ?? ''}`)) continue;
    const id = await insertOpenOccurrence(db, {
      entryId: entry.id,
      date: slot.date,
      time: slot.time,
      origin: 'schedule',
      seriesDate: slot.date,
    });
    if (id) created.push(id);
  }
  return created;
}

async function createComputedIfNothingOpen(db, entry, asOf, open) {
  if (open.length > 0) return [];
  const lastClosed = await lastRuleClosedRow(db, entry.id);
  const date = nextComputedDate({
    entry,
    lastClosed,
    todayIso: asOf.todayIso,
    firstDate: dateToIsoDate(entry.next_due_date) || dateToIsoDate(entry.start_date),
  });
  if (!date) return [];
  const endIso = dateToIsoDate(entry.repeat_end_date);
  if (endIso && date > endIso) return [];
  const times = scheduleTimesFromEntry(entry);
  const time = times.length === 1 ? times[0] : null;
  const id = await insertOpenOccurrence(db, {
    entryId: entry.id, date, time, origin: 'computed',
  });
  return id ? [id] : [];
}

async function enforceSingleComputed(db, entry, open) {
  const computed = open.filter((o) => o.origin === 'computed');
  if (computed.length <= 1) return [];
  return deleteOpenOccurrences(db, entry.id, computed.slice(1).map((o) => o.id), 'computed');
}

async function finishIfNothingLeft(db, entry, asOf) {
  if ((entry.status || 'active') !== 'active') return entry;
  const open = await listOpenRows(db, entry.id);
  if (open.length > 0) return entry;
  if (!isRecurring(entry)) {
    const closed = await db.query(
      `SELECT completed_on, scheduled_date FROM health_occurrences
       WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
       ORDER BY marked_at DESC NULLS LAST LIMIT 1`,
      [entry.id],
    );
    if (closed.rows.length === 0) return entry;
    const row = closed.rows[0];
    return updateEntryFields(db, entry.id, {
      status: 'completed',
      completed_on: dateToIsoDate(row.completed_on) || dateToIsoDate(row.scheduled_date) || asOf.todayIso,
      completed_at: new Date(),
    });
  }
  const endIso = dateToIsoDate(entry.repeat_end_date);
  if (!endIso) return entry;
  return updateEntryFields(db, entry.id, { status: 'completed' });
}

async function writeNextDueDate(db, entry) {
  const open = await listOpenRows(db, entry.id);
  const next = open[0]?.scheduled_date ?? null;
  if (dateToIsoDate(entry.next_due_date) !== next) {
    await db.query(
      'UPDATE health_entries SET next_due_date = $1, updated_at = NOW() WHERE id = $2',
      [next, entry.id],
    );
  }
  return next;
}

/**
 * @param {import('pg').PoolClient} db
 * @param {object} entryRow health_entries row (locked)
 * @param {{ todayIso: string, nowTimeIso: string }} asOf
 * @returns {Promise<{ entry: object, created: string[], createdComputed: string[], closedNotRecorded: string[] }>}
 */
export async function syncOpenOccurrences(db, entryRow, asOf) {
  let entry = entryRow;
  const result = { created: [], createdComputed: [], closedNotRecorded: [] };
  if (!isPlannedCare(entry) || entry.status === 'completed') {
    await writeNextDueDate(db, entry);
    return { entry: await reloadEntry(db, entry.id), ...result };
  }

  entry = await resumeIfPausedUntilReached(db, entry, asOf);

  if (isFixedSchedule(entry)) {
    if (!scheduleAnchorIso(entry)) {
      const open = await listOpenRows(db, entry.id);
      const anchor = open[0]?.scheduled_date
        || dateToIsoDate(entry.next_due_date)
        || dateToIsoDate(entry.start_date)
        || asOf.todayIso;
      entry = await updateEntryFields(db, entry.id, { schedule_anchor_date: anchor });
    }
    result.closedNotRecorded = await closeStackOutsideWindow(db, entry, asOf);
    if (entry.status === 'active') {
      result.created = await createMissingFixedSlots(db, entry, asOf);
    }
  } else if (isRecurring(entry) && entry.status === 'active') {
    const open = await listOpenRows(db, entry.id);
    await enforceSingleComputed(db, entry, open);
    result.createdComputed = await createComputedIfNothingOpen(db, entry, asOf, open);
    result.created = [...result.createdComputed];
  }

  entry = await finishIfNothingLeft(db, entry, asOf);
  await writeNextDueDate(db, entry);
  return { entry: await reloadEntry(db, entry.id), ...result };
}
