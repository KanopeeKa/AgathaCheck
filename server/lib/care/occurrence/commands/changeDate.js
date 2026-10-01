/**
 * Change date (D-CSM-027) and Plan another date (D-CSM-025).
 */

import { isFixedSchedule } from '../../schedule/fixedSlots.js';
import { normalizeTime } from '../../schedule/scheduleTimes.js';
import {
  SCHEDULE_EVENT_PLANNED,
  SCHEDULE_EVENT_RESCHEDULED,
  SCHEDULE_EVENT_SCOPE_CHANGED,
} from '../../schedule/scheduleEventLedger.js';
import { daysBetween, nominalIntervalDays } from '../../schedule/seriesDates.js';
import {
  loadLastClosedOccurrenceDateIso,
  validateReschedule,
} from '../../schedule/validateReschedule.js';
import { CareCommandError, badRequest, notOpen } from '../careCommandError.js';
import { updateEntryFields } from '../entryRepository.js';
import {
  deleteOpenOccurrences,
  insertOpenOccurrence,
  moveOpenOccurrence,
} from '../occurrenceRepository.js';

export const CHANGE_SCOPE_THIS = 'this';
export const CHANGE_SCOPE_FOLLOWING = 'following';

/**
 * @param {object} ctx
 * @param {object} params
 * @param {string} params.occurrenceId
 * @param {string} params.newDate
 * @param {'this'|'following'} [params.scope]
 * @param {string|null} [params.reasonCode]
 * @param {string|null} [params.reasonNote]
 * @param {boolean} [params.skipHopLimit] edits from the form move without the one-hop limit
 */
export async function changeDateCommand(ctx, {
  occurrenceId,
  newDate,
  scope = CHANGE_SCOPE_THIS,
  reasonCode = null,
  reasonNote = null,
  skipHopLimit = false,
}) {
  const { db, entry, openRows, trace, asOf } = ctx;
  const row = openRows.find((o) => o.id === occurrenceId);
  if (!row) throw notOpen();
  if (![CHANGE_SCOPE_THIS, CHANGE_SCOPE_FOLLOWING].includes(scope)) {
    throw badRequest('invalid_scope', 'scope must be this or following');
  }
  const fixed = isFixedSchedule(entry);
  const following = fixed && scope === CHANGE_SCOPE_FOLLOWING;

  let warnings = [];
  if (!following && !skipHopLimit) {
    const lastClosedDate = fixed ? null : await loadLastClosedOccurrenceDateIso(db, entry);
    const validation = validateReschedule({
      entry,
      occurrenceScheduledDate: row.scheduled_date,
      newDate,
      todayIso: asOf.todayIso,
      lastClosedDate,
    });
    if (!validation.ok) throw badRequest('invalid_date', validation.error);
    warnings = validation.warnings;
  } else {
    if (newDate < asOf.todayIso) throw badRequest('invalid_date', 'scheduled_date cannot be in the past');
    if (newDate === row.scheduled_date) throw badRequest('invalid_date', 'scheduled_date unchanged');
  }

  if (following) {
    const futureSlots = openRows.filter((o) => o.origin === 'schedule'
      && (o.scheduled_date > row.scheduled_date
        || (o.scheduled_date === row.scheduled_date && (o.scheduled_time ?? '') >= (row.scheduled_time ?? ''))));
    await deleteOpenOccurrences(db, entry.id, futureSlots.map((o) => o.id), 'schedule');
    await updateEntryFields(db, entry.id, {
      schedule_anchor_date: newDate,
      series_resumed_on: null,
    });
    trace.markEntryChanged();
    return {
      event: {
        // The moved slot is rebuilt from the new anchor, so no occurrence id.
        type: SCHEDULE_EVENT_SCOPE_CHANGED,
        occurrenceId: null,
        fromDate: row.scheduled_date,
        toDate: newDate,
        reasonCode,
        reasonNote,
        extra: { scope },
      },
      result: { occurrence: null, warnings, scope },
    };
  }

  trace.movedRow(row);
  const moved = await moveOpenOccurrence(db, {
    entryId: entry.id,
    occurrenceId,
    date: newDate,
    origin: row.origin === 'schedule' || row.origin === 'computed' ? 'planned' : row.origin,
  });
  if (!moved) {
    throw new CareCommandError(409, 'date_already_planned', 'Another open date already uses that day and time');
  }
  return {
    event: {
      type: SCHEDULE_EVENT_RESCHEDULED,
      occurrenceId,
      fromDate: row.scheduled_date,
      toDate: newDate,
      reasonCode,
      reasonNote,
      extra: { scope: CHANGE_SCOPE_THIS },
    },
    result: { occurrence: moved, warnings, scope: CHANGE_SCOPE_THIS },
  };
}

/**
 * @param {object} ctx
 * @param {{ date: string, time?: string|null, reasonCode?: string|null }} params
 */
export async function planAnotherDateCommand(ctx, { date, time = null, reasonCode = null }) {
  const { db, entry, openRows, trace, asOf } = ctx;
  if (!date) throw badRequest('scheduled_date_required', 'scheduled_date is required');
  if (date < asOf.todayIso) throw badRequest('invalid_date', 'scheduled_date cannot be in the past');
  if ((entry.status || 'active') === 'completed') {
    throw badRequest('item_finished', 'This care item is finished');
  }
  const normalizedTime = time ? normalizeTime(time) : null;
  const halfInterval = Math.floor(nominalIntervalDays(entry, date) / 2);
  const warnings = openRows
    .filter((o) => Math.abs(daysBetween(o.scheduled_date, date)) <= halfInterval)
    .map((o) => ({ code: 'another_date_near', scheduled_date: o.scheduled_date }));
  const id = await insertOpenOccurrence(db, {
    entryId: entry.id,
    date,
    time: normalizedTime,
    origin: 'planned',
  });
  if (!id) {
    throw new CareCommandError(409, 'date_already_planned', 'That date is already planned');
  }
  trace.createdRow(id, 'planned', true);
  return {
    event: { type: SCHEDULE_EVENT_PLANNED, occurrenceId: id, toDate: date, reasonCode },
    result: { occurrenceId: id, warnings },
  };
}
