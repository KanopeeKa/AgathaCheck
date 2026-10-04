/**
 * Care item responses with open occurrences, `as_of` and `estimated_next`
 * (D-CIE-028). List reads use one query for all open occurrences.
 */

import { normalizePetHomeTimezone, wallClockInTimeZone } from '../../lib/petHomeTimezone.js';
import {
  careAsOfForZone,
  careItemReadAdditions,
  listLastDoneByEntry,
  listOpenRows,
  listOpenRowsByEntry,
  resolveCareAsOf,
} from '../../lib/care/occurrence/index.js';
import { careClockFromRequest } from '../../lib/care/occurrence/careAsOf.js';
import { healthEntryToMap } from './shared.js';

/**
 * `last_done { occurrence_id, completed_on, time }` — time is when it was
 * marked, in the pet's home zone (agenda "Done · 08:12", D-CIE-025).
 */
function lastDoneToWire(row, timeZone) {
  if (!row) return null;
  return {
    occurrence_id: row.id,
    completed_on: row.completed_on,
    time: row.marked_at ? wallClockInTimeZone(timeZone, new Date(row.marked_at)).nowTimeIso : null,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {object} entry health_entries row
 * @param {import('express').Request|null} req
 * @param {object} [options]
 * @param {object[]} [options.openRows]
 * @param {object} [options.asOf]
 */
export async function careItemWire(db, entry, req, { openRows = null, asOf = null } = {}) {
  const clock = asOf || await resolveCareAsOf(db, entry, req);
  const rows = openRows || await listOpenRows(db, entry.id);
  const lastDone = (await listLastDoneByEntry(db, [entry.id])).get(entry.id);
  return {
    ...healthEntryToMap(entry),
    ...careItemReadAdditions(entry, rows, clock),
    last_done: lastDoneToWire(lastDone, clock.timeZone),
  };
}

/**
 * @param {import('pg').Pool} db
 * @param {object[]} entries rows joined with `pet_home_timezone`
 * @param {import('express').Request} req
 */
export async function careItemsWire(db, entries, req) {
  const ids = entries.map((e) => e.id);
  const openByEntry = await listOpenRowsByEntry(db, ids);
  const lastDoneByEntry = await listLastDoneByEntry(db, ids);
  const clock = careClockFromRequest(req);
  const now = new Date();
  const byZone = new Map();
  return entries.map((entry) => {
    const zone = normalizePetHomeTimezone(entry.pet_home_timezone);
    if (!byZone.has(zone)) byZone.set(zone, careAsOfForZone(zone, clock, now));
    return {
      ...healthEntryToMap(entry),
      ...careItemReadAdditions(entry, openByEntry.get(entry.id) || [], byZone.get(zone)),
      last_done: lastDoneToWire(lastDoneByEntry.get(entry.id), zone),
    };
  });
}

/**
 * Standard command response body.
 *
 * @param {import('pg').Pool} db
 * @param {object} out runCareCommand result
 * @param {import('express').Request} req
 * @param {object} [extra]
 */
export async function commandResponse(db, out, req, extra = {}) {
  const entry = await careItemWire(db, out.entry, req, { openRows: out.openOccurrences, asOf: out.asOf });
  return {
    ...extra,
    entry,
    next_due_date: entry.next_due_date,
    undo_token: out.undoToken ?? null,
  };
}
