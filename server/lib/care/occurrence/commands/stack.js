/**
 * Record earlier doses (stack review) and Record as given (D-CSM-023).
 */

import {
  SCHEDULE_EVENT_RECORDED,
  SCHEDULE_EVENT_STACK_RESOLVED,
} from '../../schedule/scheduleEventLedger.js';
import { badRequest, notOpen } from '../careCommandError.js';
import { findOccurrence, markSkipped } from '../occurrenceRepository.js';
import { closeAsDone } from './complete.js';

/**
 * @param {object} ctx
 * @param {{ given?: string[], notGiven?: string[], completedOnById?: Record<string,string> }} params
 */
export async function resolveStackCommand(ctx, { given = [], notGiven = [], completedOnById = {} }) {
  const { db, entry, openRows, trace, userId, asOf } = ctx;
  const ids = [...given, ...notGiven];
  if (ids.length === 0) throw badRequest('nothing_to_record', 'given or not_given is required');
  if (new Set(ids).size !== ids.length) throw badRequest('duplicate_ids', 'An id appears twice');
  const byId = new Map(openRows.map((o) => [o.id, o]));
  for (const id of ids) {
    if (!byId.has(id)) throw notOpen();
  }
  for (const id of given) {
    const row = byId.get(id);
    const completedOn = completedOnById[id] || (row.scheduled_date <= asOf.todayIso ? row.scheduled_date : asOf.todayIso);
    await closeAsDone(ctx, row, { completedOn });
    trace.closedRow(row);
  }
  for (const id of notGiven) {
    const row = byId.get(id);
    await markSkipped(db, { entryId: entry.id, occurrenceId: id, closeReason: 'user', userId });
    trace.closedRow(row);
  }
  return {
    event: {
      type: SCHEDULE_EVENT_STACK_RESOLVED,
      extra: { given, not_given: notGiven },
    },
    result: { given, notGiven },
  };
}

/**
 * @param {object} ctx
 * @param {{ occurrenceId: string, completedOn?: string|null }} params
 */
export async function recordAsGivenCommand(ctx, { occurrenceId, completedOn = null }) {
  const { db, entry, trace, asOf } = ctx;
  const row = await findOccurrence(db, entry.id, occurrenceId);
  if (!row || row.status !== 'skipped' || row.close_reason !== 'not_recorded') {
    throw badRequest('not_a_not_recorded_dose', 'Only a dose closed as Not recorded can be recorded as given');
  }
  const date = completedOn || row.scheduled_date;
  if (date > asOf.todayIso) throw badRequest('completed_on_in_future', 'completed_on cannot be in the future');
  const recorded = await closeAsDone(ctx, row, { completedOn: date, fromNotRecorded: true });
  trace.recordedRow(row);
  return {
    event: { type: SCHEDULE_EVENT_RECORDED, occurrenceId, fromDate: row.scheduled_date, toDate: date },
    result: { occurrence: recorded },
  };
}
