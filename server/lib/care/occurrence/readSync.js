/**
 * Read-path catch-up (FR-1, FR-8, FR-10): single-item reads commit the same
 * sync as commands; list reads filter stale open rows without writing.
 */

import { resolveCareAsOf } from './careAsOf.js';
import { withCareItemLock } from './careItemLock.js';
import { listOpenRows } from './occurrenceRepository.js';
import { isPlannedCare, syncOpenOccurrences } from './syncOpenOccurrences.js';
import { isFixedSchedule, nextSeriesSlotAfter, stackWindowStart } from '../schedule/fixedSlots.js';

/**
 * True when `closeStackOutsideWindow` would auto-close this open row.
 *
 * @param {object} entry
 * @param {object} row open occurrence row
 * @param {{ todayIso: string }} asOf
 */
export function wouldAutoCloseAsNotRecorded(entry, row, asOf) {
  if (!isPlannedCare(entry) || entry.status === 'completed') return false;
  if (!isFixedSchedule(entry)) return false;
  const windowStart = stackWindowStart(asOf.todayIso);
  if (row.scheduled_date >= windowStart) return false;
  const next = nextSeriesSlotAfter({
    entry,
    date: row.scheduled_date,
    time: row.scheduled_time,
  });
  if (!next || next.date > windowStart) return false;
  return true;
}

/**
 * List reads: hide open rows the next command would close (no writes).
 *
 * @param {object} entry
 * @param {object[]} openRows
 * @param {{ todayIso: string }} asOf
 */
export function filterOpenRowsForListRead(entry, openRows, asOf) {
  return openRows.filter((row) => !wouldAutoCloseAsNotRecorded(entry, row, asOf));
}

/**
 * Single-item read: commit catch-up under the item lock.
 *
 * @param {import('pg').Pool} pool
 * @param {string} entryId
 * @param {import('express').Request|null} req
 * @param {{ todayIso: string, nowTimeIso: string, timeZone?: string }} [asOf]
 * @returns {Promise<{ entry: object, openRows: object[], asOf: object }|null>}
 */
export async function syncCareItemForRead(pool, entryId, req, asOf = null) {
  return withCareItemLock(pool, entryId, async (db, entry) => {
    const clock = asOf || await resolveCareAsOf(db, entry, req);
    const synced = await syncOpenOccurrences(db, entry, clock);
    const openRows = await listOpenRows(db, synced.entry.id);
    return { entry: synced.entry, openRows, asOf: clock };
  });
}
