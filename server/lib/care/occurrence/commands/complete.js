/**
 * Mark as done (D-CSM-022, D-CSM-026, D-CSM-030; D-CIE-009).
 *
 * Never asks (D-CSM-026 v4): when a next-date choice is needed and none is
 * sent, the remembered choice applies if it fits, otherwise Keep. A later
 * After-it's-done date completed while an earlier one is open leaves the
 * earlier one open unless `earlier_choice` says otherwise (PL-5 v4).
 */

import { fetchUserSnapshot } from '../../../people/userSnapshot.js';
import { resolveProviderUsedForCompletion } from '../../providerUsed.js';
import { deriveCompletionTiming } from '../../schedule/completionTiming.js';
import { isFixedSchedule } from '../../schedule/fixedSlots.js';
import {
  NEXT_CHOICES,
  NEXT_CHOICE_KEEP,
  evaluateNextChoice,
  instantMinutes,
  pickWaitingOccurrence,
} from '../../schedule/lateCompletion.js';
import { scheduleTimesFromEntry } from '../../schedule/scheduleTimes.js';
import { SCHEDULE_EVENT_COMPLETED } from '../../schedule/scheduleEventLedger.js';
import { badRequest, notOpen } from '../careCommandError.js';
import { applyNextChoice } from './nextChoice.js';
import { markCompleted, markSkipped } from '../occurrenceRepository.js';
import { updateEntryFields } from '../entryRepository.js';

export const EARLIER_CHOICE_KEEP = 'keep';
export const EARLIER_CHOICES = ['complete', 'skip', EARLIER_CHOICE_KEEP];

/**
 * Close one open occurrence as done (no choices) — shared with stack review.
 *
 * @param {object} ctx command context
 * @param {object} row open row
 * @param {object} params
 */
export async function closeAsDone(ctx, row, {
  completedOn, notes = '', body = {}, markedAt = new Date(), fromNotRecorded = false,
}) {
  const { db, entry, userId } = ctx;
  const markedSnapshot = userId ? await fetchUserSnapshot(db, userId) : null;
  const provider = userId
    ? await resolveProviderUsedForCompletion(db, userId, entry, body)
    : { contactId: null, typedName: null, snapshot: null };
  return markCompleted(db, {
    entryId: entry.id,
    occurrenceId: row.id,
    completedOn,
    completionTiming: deriveCompletionTiming(row.scheduled_date, completedOn),
    userId,
    notes,
    markedAt,
    performedByUserId: userId,
    markedSnapshot,
    performedSnapshot: markedSnapshot,
    provider,
    fromNotRecorded,
  });
}

/**
 * @param {object} ctx command context from executeCareCommand
 * @param {object} params
 * @param {string} params.occurrenceId
 * @param {string|null} [params.completedOn] YYYY-MM-DD (default today)
 * @param {string} [params.notes]
 * @param {string|null} [params.nextChoice]
 * @param {boolean} [params.rememberChoice]
 * @param {string|null} [params.earlierChoice]
 * @param {object} [params.body] provider overrides
 */
export async function completeOccurrenceCommand(ctx, {
  occurrenceId,
  completedOn = null,
  notes = '',
  nextChoice = null,
  rememberChoice = false,
  earlierChoice = null,
  body = {},
}) {
  const { db, entry, asOf, trace, openRows } = ctx;
  const row = openRows.find((o) => o.id === occurrenceId);
  if (!row) throw notOpen();

  const completedOnIso = completedOn || asOf.todayIso;
  if (completedOnIso > asOf.todayIso) {
    throw badRequest('completed_on_in_future', 'completed_on cannot be in the future');
  }
  if (nextChoice && !NEXT_CHOICES.includes(nextChoice)) {
    throw badRequest('invalid_next_choice', `next_choice must be one of ${NEXT_CHOICES.join(', ')}`);
  }
  if (earlierChoice && !EARLIER_CHOICES.includes(earlierChoice)) {
    throw badRequest('invalid_earlier_choice', `earlier_choice must be one of ${EARLIER_CHOICES.join(', ')}`);
  }

  // After it's done: a later date completed while an earlier one is open
  // (PL-5). Without a choice the earlier date stays open.
  let remaining = openRows.filter((o) => o.id !== row.id);
  let appliedEarlier = null;
  if (!isFixedSchedule(entry)) {
    const rowAt = instantMinutes(row.scheduled_date, row.scheduled_time);
    const earlier = remaining.filter(
      (o) => instantMinutes(o.scheduled_date, o.scheduled_time) < rowAt,
    );
    if (earlier.length > 0) {
      appliedEarlier = earlierChoice || EARLIER_CHOICE_KEEP;
      for (const e of earlier) {
        if (appliedEarlier === 'complete') {
          await closeAsDone(ctx, e, { completedOn: completedOnIso });
          trace.closedRow(e);
        } else if (appliedEarlier === 'skip') {
          await markSkipped(db, { entryId: entry.id, occurrenceId: e.id, closeReason: 'user', userId: ctx.userId });
          trace.closedRow(e);
        }
      }
      if (appliedEarlier !== EARLIER_CHOICE_KEEP) {
        const earlierIds = new Set(earlier.map((e) => e.id));
        remaining = remaining.filter((o) => !earlierIds.has(o.id));
      }
    }
  }

  // Done after the due date with a waiting date (D-CSM-026).
  const waiting = pickWaitingOccurrence({ closed: row, openOccurrences: remaining, asOf });
  const evaluation = evaluateNextChoice({
    closed: row,
    waiting,
    completedOn: completedOnIso,
    completedTime: completedOnIso === asOf.todayIso ? asOf.nowTimeIso : null,
    multiTime: scheduleTimesFromEntry(entry).length > 1,
  });
  let appliedChoice = null;
  if (evaluation.required) {
    const remembered = entry.late_completion_choice && evaluation.options.includes(entry.late_completion_choice)
      ? entry.late_completion_choice
      : null;
    appliedChoice = nextChoice || remembered || NEXT_CHOICE_KEEP;
    if (!evaluation.options.includes(appliedChoice)) {
      throw badRequest('next_choice_not_available', `next_choice ${appliedChoice} is not available here`);
    }
  }

  const done = await closeAsDone(ctx, row, { completedOn: completedOnIso, notes, body });
  if (!done) throw notOpen();
  trace.closedRow(row);

  if (evaluation.required) {
    await applyNextChoice(ctx, {
      choice: appliedChoice,
      closed: row,
      waiting,
      shift: evaluation.shift,
      completedOn: completedOnIso,
      remainingOpen: remaining,
    });
  }
  if (rememberChoice && nextChoice && nextChoice !== entry.late_completion_choice) {
    await updateEntryFields(db, entry.id, { late_completion_choice: nextChoice });
    trace.markEntryChanged();
  }

  return {
    event: {
      type: SCHEDULE_EVENT_COMPLETED,
      occurrenceId: row.id,
      fromDate: row.scheduled_date,
      toDate: completedOnIso,
      extra: {
        next_choice: appliedChoice,
        earlier_choice: appliedEarlier,
        shift: evaluation.required ? evaluation.shift : null,
      },
    },
    result: { occurrence: done, appliedChoice },
  };
}
