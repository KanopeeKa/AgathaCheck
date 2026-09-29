/**
 * Shared frame for every care command (D-CSM-033):
 * catch-up sync → action → sync → one ledger event whose payload lets undo
 * reverse the whole command (D-CSM-029).
 */

import { insertCareScheduleEvent } from '../schedule/scheduleEventLedger.js';
import { entrySnapshot, reloadEntry } from './entryRepository.js';
import { listOpenRows } from './occurrenceRepository.js';
import { syncOpenOccurrences } from './syncOpenOccurrences.js';

function rowSnapshot(row) {
  return JSON.parse(JSON.stringify(row));
}

/** Records what a command changed, for undo. */
export class CommandTrace {
  /** @param {object} entry */
  constructor(entry) {
    this.entryBefore = entrySnapshot(entry);
    this.entryChanged = false;
    this.closed = [];
    this.created = [];
    this.moved = [];
    this.recorded = [];
  }

  /** @param {object} openRowBefore row before it was closed */
  closedRow(openRowBefore) {
    this.closed.push(rowSnapshot(openRowBefore));
  }

  /** @param {object} closedRowBefore Not recorded row before it was recorded */
  recordedRow(closedRowBefore) {
    this.recorded.push(rowSnapshot(closedRowBefore));
  }

  /**
   * @param {string} id
   * @param {string} origin
   * @param {boolean} [primary] the command's own product (deleted by undo whatever its origin)
   */
  createdRow(id, origin, primary = false) {
    if (id) this.created.push({ id, origin, primary });
  }

  /** @param {object} openRowBefore */
  movedRow(openRowBefore) {
    this.moved.push({
      id: openRowBefore.id,
      scheduled_date: openRowBefore.scheduled_date,
      scheduled_time: openRowBefore.scheduled_time,
      origin: openRowBefore.origin,
    });
  }

  markEntryChanged() {
    this.entryChanged = true;
  }

  toPayload(extra = {}) {
    return {
      closed: this.closed,
      created: this.created,
      moved: this.moved,
      recorded: this.recorded,
      entry_before: this.entryChanged ? this.entryBefore : null,
      ...extra,
    };
  }
}

/**
 * @typedef {object} CommandEvent
 * @property {string} type ledger event type
 * @property {string|null} [occurrenceId]
 * @property {string|null} [fromDate]
 * @property {string|null} [toDate]
 * @property {string|null} [reasonCode]
 * @property {string|null} [reasonNote]
 * @property {object} [extra] payload additions
 */

/**
 * @template T
 * @param {object} params
 * @param {import('pg').PoolClient} params.db
 * @param {object} params.entry locked health_entries row
 * @param {{ todayIso: string, nowTimeIso: string, timeZone?: string }} params.asOf
 * @param {string|null} params.userId
 * @param {(ctx: { db: any, entry: object, asOf: object, userId: string|null, trace: CommandTrace, openRows: object[] }) => Promise<{ event: CommandEvent|null, result?: T }>} fn
 * @returns {Promise<T & { entry: object, openOccurrences: object[], undoToken: string|null }>}
 */
export async function executeCareCommand({ db, entry, asOf, userId }, fn) {
  const caughtUp = await syncOpenOccurrences(db, entry, asOf);
  const fresh = caughtUp.entry || await reloadEntry(db, entry.id);
  const trace = new CommandTrace(fresh);
  const openRows = await listOpenRows(db, fresh.id);
  const { event, result = {} } = await fn({
    db, entry: fresh, asOf, userId, trace, openRows,
  });

  const afterAction = await reloadEntry(db, fresh.id);
  const synced = await syncOpenOccurrences(db, afterAction, asOf);
  const computed = new Set(synced.createdComputed);
  for (const id of synced.created) trace.createdRow(id, computed.has(id) ? 'computed' : 'schedule');

  let undoToken = null;
  if (event) {
    undoToken = await insertCareScheduleEvent(db, {
      healthEntryId: fresh.id,
      healthOccurrenceId: event.occurrenceId ?? null,
      eventType: event.type,
      fromDate: event.fromDate ?? null,
      toDate: event.toDate ?? null,
      reasonCode: event.reasonCode ?? null,
      reasonNote: event.reasonNote ?? null,
      actorUserId: userId,
      payload: trace.toPayload(event.extra),
    });
  }

  return {
    ...result,
    entry: synced.entry,
    openOccurrences: await listOpenRows(db, fresh.id),
    undoToken,
  };
}
