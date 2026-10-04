/**
 * Change when a completed occurrence was done (D-CSM-034).
 *
 * Fixed schedule: only that occurrence changes. After it's done: when this is
 * the item's latest completion and the computed next date its completion
 * created is still open and still `computed`, that date moves to the new done
 * date + interval in the same transaction. A moved (planned) next date stays;
 * the result says `nextUnchanged`. Undo reverses the whole command.
 */

import { dateToIsoDate } from '../../../calendarDate.js';
import { deriveCompletionTiming } from '../../schedule/completionTiming.js';
import { isFixedSchedule } from '../../schedule/fixedSlots.js';
import { nextComputedDate } from '../../schedule/nextComputed.js';
import {
  SCHEDULE_EVENT_COMPLETED,
  SCHEDULE_EVENT_COMPLETION_DATE_CHANGED,
} from '../../schedule/scheduleEventLedger.js';
import { CareCommandError, badRequest } from '../careCommandError.js';
import {
  findOccurrence,
  moveOpenOccurrence,
  updateCompletedOn,
} from '../occurrenceRepository.js';

/**
 * The open computed date created by this occurrence's completion, when that
 * completion is the item's latest still-standing one.
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {string} occurrenceId
 * @returns {Promise<{ next: object|null, createdNextId: string|null }>}
 */
async function nextCreatedByLatestCompletion(db, entryId, occurrenceId) {
  const latest = await db.query(
    `SELECT health_occurrence_id, payload FROM care_schedule_events
     WHERE health_entry_id = $1 AND event_type = $2 AND undone_at IS NULL
     ORDER BY occurred_at DESC, created_at DESC
     LIMIT 1`,
    [entryId, SCHEDULE_EVENT_COMPLETED],
  );
  const event = latest.rows[0];
  if (!event || event.health_occurrence_id !== occurrenceId) {
    return { next: null, createdNextId: null };
  }
  const created = (event.payload?.created || []).find((c) => c.origin === 'computed' && !c.primary);
  if (!created) return { next: null, createdNextId: null };
  const next = await findOccurrence(db, entryId, created.id);
  return { next, createdNextId: created.id };
}

/**
 * @param {object} ctx command context from executeCareCommand
 * @param {{ occurrenceId: string, completedOn: string|null }} params
 */
export async function changeCompletionDateCommand(ctx, { occurrenceId, completedOn }) {
  const { db, entry, asOf, trace } = ctx;
  if (!completedOn) throw badRequest('invalid_completed_on', 'completed_on must be a date (YYYY-MM-DD)');
  if (completedOn > asOf.todayIso) {
    throw badRequest('completed_on_in_future', 'completed_on cannot be in the future');
  }
  const startIso = dateToIsoDate(entry.start_date);
  if (startIso && completedOn < startIso) {
    throw badRequest('completed_on_before_start', 'completed_on cannot be before the care item starts');
  }

  const row = await findOccurrence(db, entry.id, occurrenceId);
  if (!row || row.status !== 'completed') {
    throw new CareCommandError(409, 'occurrence_not_completed', 'Only a completed date can change when it was done');
  }
  const fromIso = dateToIsoDate(row.completed_on);
  if (fromIso === completedOn) {
    return { event: null, result: { occurrence: row, movedNextId: null, nextUnchanged: false } };
  }

  trace.closedRow(row);
  const updated = await updateCompletedOn(db, {
    entryId: entry.id,
    occurrenceId,
    completedOn,
    completionTiming: deriveCompletionTiming(row.scheduled_date, completedOn),
  });

  let movedNextId = null;
  let nextUnchanged = false;
  if (!isFixedSchedule(entry)) {
    const { next, createdNextId } = await nextCreatedByLatestCompletion(db, entry.id, occurrenceId);
    if (next && next.status === 'pending' && next.origin === 'computed') {
      const date = nextComputedDate({
        entry,
        lastClosed: { status: 'completed', scheduled_date: row.scheduled_date, completed_on: completedOn },
        todayIso: asOf.todayIso,
      });
      if (date && date !== next.scheduled_date) {
        const moved = await moveOpenOccurrence(db, {
          entryId: entry.id, occurrenceId: next.id, date, origin: 'computed',
        });
        if (moved) {
          trace.movedRow(next);
          movedNextId = next.id;
        } else {
          nextUnchanged = true;
        }
      }
    } else if (createdNextId && next && next.status === 'pending') {
      nextUnchanged = true;
    }
  }

  return {
    event: {
      type: SCHEDULE_EVENT_COMPLETION_DATE_CHANGED,
      occurrenceId,
      fromDate: fromIso,
      toDate: completedOn,
      extra: { moved_computed_id: movedNextId, next_unchanged: nextUnchanged },
    },
    result: { occurrence: updated, movedNextId, nextUnchanged },
  };
}
