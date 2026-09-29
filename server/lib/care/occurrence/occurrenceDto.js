/**
 * Wire shapes for open occurrences and care item read additions
 * (`open_occurrences`, `as_of`, `estimated_next`) — D-CIE-028.
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { isFixedSchedule } from '../schedule/fixedSlots.js';
import { estimatedNextWhileOverdue } from '../schedule/nextComputed.js';
import {
  OCCURRENCE_STATUS_OVERDUE,
  occurrenceStatus,
} from '../schedule/occurrenceStatus.js';
import { seriesStep } from '../schedule/seriesDates.js';
import { asOfToWire } from './careAsOf.js';
import { defaultResumeDate } from './commands/postpone.js';

/**
 * @param {object} row normalized open row
 * @param {object} entry
 * @param {{ todayIso: string, nowTimeIso: string }} asOf
 */
export function openOccurrenceToWire(row, entry, asOf) {
  return {
    id: row.id,
    scheduled_date: row.scheduled_date,
    scheduled_time: row.scheduled_time,
    status: occurrenceStatus({ occurrence: row, entry, asOf }),
    origin: row.origin || 'computed',
  };
}

/**
 * Read additions for one care item.
 *
 * @param {object} entry health_entries row
 * @param {object[]} openRows normalized open rows (ascending)
 * @param {{ todayIso: string, nowTimeIso: string, timeZone: string }} asOf
 */
export function careItemReadAdditions(entry, openRows, asOf) {
  const visible = (entry.status || 'active') === 'active' || entry.status === 'paused';
  const open = visible ? openRows.map((row) => openOccurrenceToWire(row, entry, asOf)) : [];
  let estimatedNext = null;
  if (
    entry.status === 'active'
    && seriesStep(entry)
    && !isFixedSchedule(entry)
    && open.length === 1
    && open[0].status === OCCURRENCE_STATUS_OVERDUE
  ) {
    estimatedNext = {
      date: estimatedNextWhileOverdue({ entry, todayIso: asOf.todayIso }),
      basis: 'done_today',
    };
  }
  return {
    open_occurrences: open,
    as_of: asOfToWire(asOf),
    estimated_next: estimatedNext,
    schedule_anchor_date: dateToIsoDate(entry.schedule_anchor_date),
    late_completion_choice: entry.late_completion_choice ?? null,
    paused_until: dateToIsoDate(entry.paused_until),
    paused_since: dateToIsoDate(entry.paused_since),
    resume_default_date: entry.status === 'paused' ? defaultResumeDate(entry, openRows, asOf) : null,
  };
}
