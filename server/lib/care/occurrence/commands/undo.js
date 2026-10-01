/**
 * Undo reverses a whole command (D-CSM-029).
 *
 * Reversal is defensive: it only touches rows still in the state the command
 * left them in. A created next date is deleted only while it is still an open
 * `computed` date; `planned` and `schedule` dates are never deleted (unless
 * the command itself created them as its product, e.g. Plan another date).
 */

import {
  SCHEDULE_EVENT_UNDONE,
  UNDOABLE_EVENT_TYPES,
} from '../../schedule/scheduleEventLedger.js';
import { CareCommandError, badRequest } from '../careCommandError.js';
import { updateEntryFields } from '../entryRepository.js';
import {
  deleteOpenOccurrences,
  findOccurrence,
  moveOpenOccurrence,
  reopenClosedOccurrence,
  restoreOccurrence,
} from '../occurrenceRepository.js';

async function loadUndoableEvents(db, entryId) {
  const result = await db.query(
    `SELECT * FROM care_schedule_events
     WHERE health_entry_id = $1 AND event_type = ANY($2::text[])
       AND undone_at IS NULL AND payload IS NOT NULL
     ORDER BY occurred_at DESC, created_at DESC`,
    [entryId, UNDOABLE_EVENT_TYPES],
  );
  return result.rows;
}

async function reverse(ctx, event, { restoreEntry }) {
  const { db, entry } = ctx;
  const payload = event.payload || {};
  const created = payload.created || [];
  const primary = created.filter((c) => c.primary).map((c) => c.id);
  const computed = created.filter((c) => !c.primary && c.origin === 'computed').map((c) => c.id);
  const rebuilt = created.filter((c) => !c.primary && c.origin === 'schedule').map((c) => c.id);
  await deleteOpenOccurrences(db, entry.id, primary);
  await deleteOpenOccurrences(db, entry.id, computed, 'computed');
  if (payload.entry_before && restoreEntry) {
    await deleteOpenOccurrences(db, entry.id, rebuilt, 'schedule');
  }

  for (const moved of payload.moved || []) {
    await moveOpenOccurrence(db, {
      entryId: entry.id,
      occurrenceId: moved.id,
      date: moved.scheduled_date,
      origin: moved.origin,
    });
  }

  const restored = [];
  for (const before of [...(payload.closed || []), ...(payload.recorded || [])]) {
    const current = await findOccurrence(db, entry.id, before.id);
    if (!current || current.status === 'pending') continue;
    const row = await restoreOccurrence(db, entry.id, before);
    if (row) restored.push(row);
  }

  if (payload.entry_before && restoreEntry) {
    await updateEntryFields(db, entry.id, payload.entry_before);
  }
  return restored;
}

/**
 * @param {object} ctx command context
 * @param {{ undoToken?: string|null, occurrenceId?: string|null }} params
 */
export async function undoCommand(ctx, { undoToken = null, occurrenceId = null } = {}) {
  const { db } = ctx;
  const events = await loadUndoableEvents(db, ctx.entry.id);
  let event = events[0] || null;
  if (undoToken) {
    event = events.find((e) => e.id === undoToken) || null;
    if (!event) throw new CareCommandError(409, 'undo_stale', 'This action can no longer be undone');
  } else if (occurrenceId) {
    event = events.find((e) => e.health_occurrence_id === occurrenceId
      && e.event_type === 'completed') || null;
  }
  if (!event) throw badRequest('nothing_to_undo', 'No schedule action to undo');

  const isLatest = events[0]?.id === event.id;
  const restored = await reverse(ctx, event, { restoreEntry: isLatest });
  await db.query('UPDATE care_schedule_events SET undone_at = NOW() WHERE id = $1', [event.id]);
  const stillThere = event.health_occurrence_id
    ? await findOccurrence(db, ctx.entry.id, event.health_occurrence_id)
    : null;

  return {
    event: {
      type: SCHEDULE_EVENT_UNDONE,
      occurrenceId: stillThere ? event.health_occurrence_id : null,
      extra: { undone_event_id: event.id, undone_type: event.event_type },
    },
    result: {
      undoneType: event.event_type,
      occurrence: restored[0] || null,
    },
  };
}

/**
 * Deleting a weigh-in's weight entry undoes that completion (UN-5).
 *
 * @param {object} ctx
 * @param {{ occurrenceId: string }} params
 */
export async function undoCompletionOfOccurrence(ctx, { occurrenceId }) {
  const events = await loadUndoableEvents(ctx.db, ctx.entry.id);
  const event = events.find((e) => e.health_occurrence_id === occurrenceId
    && e.event_type === 'completed');
  if (event) return undoCommand(ctx, { undoToken: event.id });
  const reopened = await reopenClosedOccurrence(ctx.db, occurrenceId);
  return { event: null, result: { undoneType: null, occurrence: reopened } };
}
