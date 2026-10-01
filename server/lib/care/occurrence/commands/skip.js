/**
 * Skip one date (D-CSM-022, D-CSM-023) — never moves another date.
 */

import { SCHEDULE_EVENT_SKIPPED } from '../../schedule/scheduleEventLedger.js';
import { notOpen } from '../careCommandError.js';
import { markSkipped } from '../occurrenceRepository.js';

/**
 * @param {object} ctx
 * @param {{ occurrenceId: string, notes?: string, reasonCode?: string|null }} params
 */
export async function skipOccurrenceCommand(ctx, { occurrenceId, notes = '', reasonCode = null }) {
  const { db, entry, openRows, trace, userId } = ctx;
  const row = openRows.find((o) => o.id === occurrenceId);
  if (!row) throw notOpen();
  const skipped = await markSkipped(db, {
    entryId: entry.id,
    occurrenceId,
    closeReason: 'user',
    userId,
    notes,
  });
  if (!skipped) throw notOpen();
  trace.closedRow(row);
  return {
    event: {
      type: SCHEDULE_EVENT_SKIPPED,
      occurrenceId,
      fromDate: row.scheduled_date,
      reasonCode,
      reasonNote: notes || null,
    },
    result: { occurrence: skipped },
  };
}
