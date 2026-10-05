/**
 * §9 data repair after host TZ DATE shift (D1, D2, D6, sync).
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { loadPetHomeTimezone } from '../../petHomeTimezone.js';
import { isFixedSchedule, nextSeriesSlotAfter, stackWindowStart } from '../schedule/fixedSlots.js';
import { insertCareScheduleEvent } from '../schedule/scheduleEventLedger.js';
import { withCareItemLock } from '../occurrence/careItemLock.js';
import {
  deleteNotRecordedScheduleOccurrence,
  reopenClosedOccurrence,
} from '../occurrence/occurrenceRepository.js';
import { syncOpenOccurrences } from '../occurrence/syncOpenOccurrences.js';
import { careAsOfForZone } from '../occurrence/careAsOf.js';

function slotKey(row) {
  const date = dateToIsoDate(row.series_date) || dateToIsoDate(row.scheduled_date);
  const time = row.scheduled_time ? String(row.scheduled_time).slice(0, 8) : '';
  return `${date}|${time}`;
}

function personActedOn(row) {
  if (row.status === 'completed') return true;
  if (row.marked_by_user_id) return true;
  return row.status === 'skipped' && row.close_reason === 'user';
}

function wouldCloseAsNotRecorded(entry, row, todayIso) {
  if (!isFixedSchedule(entry)) return false;
  const windowStart = stackWindowStart(todayIso);
  const date = dateToIsoDate(row.scheduled_date);
  if (!date || date >= windowStart) return false;
  const next = nextSeriesSlotAfter({
    entry,
    date,
    time: row.scheduled_time,
  });
  if (!next || next.date > windowStart) return false;
  return true;
}

export function pickKeeper(rows) {
  const acted = rows.find(personActedOn);
  if (acted) return acted;
  const pending = rows.find((r) => r.status === 'pending');
  if (pending) return pending;
  return rows.slice().sort((a, b) => String(a.id).localeCompare(String(b.id)))[0];
}

/**
 * D2: at most one reopen per slot; never ids slated for deletion (DC-4 §3).
 *
 * @param {object} params
 * @param {object} params.entry
 * @param {object[]} params.rows all schedule rows for the item (pre-repair snapshot)
 * @param {string[]} params.deletedIds D1 deletions (dry-run or applied)
 * @param {string} params.todayIso
 * @returns {string[]}
 */
export function planWronglyClosedReopens({ entry, rows, deletedIds, todayIso }) {
  const deleted = new Set(deletedIds);
  const bySlot = new Map();
  for (const row of rows) {
    if (deleted.has(row.id)) continue;
    const key = slotKey(row);
    if (!bySlot.has(key)) bySlot.set(key, []);
    bySlot.get(key).push(row);
  }
  const reopened = [];
  for (const [, surviving] of bySlot) {
    if (surviving.some((r) => r.status === 'pending')) continue;
    const candidate = pickKeeper(surviving);
    if (personActedOn(candidate)) continue;
    if (candidate.close_reason !== 'not_recorded') continue;
    if (wouldCloseAsNotRecorded(entry, candidate, todayIso)) continue;
    reopened.push(candidate.id);
  }
  return reopened;
}

async function hasDependentRows(db, occurrenceId) {
  const weight = await db.query(
    'SELECT 1 FROM weight_entries WHERE health_occurrence_id = $1 LIMIT 1',
    [occurrenceId],
  );
  if (weight.rows.length) return true;
  const photos = await db.query(
    'SELECT 1 FROM health_event_photos WHERE health_occurrence_id = $1 LIMIT 1',
    [occurrenceId],
  );
  return photos.rows.length > 0;
}

/**
 * Calendar "today" for repair decisions (pet home zone, not UTC).
 *
 * @param {string} timeZone IANA zone
 * @param {{ overrideTodayIso?: string|null, instant?: Date }} [options]
 * @returns {string}
 */
export function repairTodayIsoForZone(timeZone, { overrideTodayIso = null, instant = new Date() } = {}) {
  if (overrideTodayIso) return overrideTodayIso;
  return careAsOfForZone(timeZone, null, instant).todayIso;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ apply?: boolean, todayIso?: string|null, asOfInstant?: Date }} [options]
 */
export async function repairTzShift(pool, {
  apply = false,
  todayIso: todayIsoOverride = null,
  asOfInstant = new Date(),
} = {}) {
  const entries = await pool.query(
    `SELECT * FROM health_entries
     WHERE COALESCE(care_planning, 'planned') <> 'unplanned'
     ORDER BY id`,
  );
  const reports = [];
  for (const entry of entries.rows) {
    const report = {
      entryId: entry.id,
      name: entry.name,
      deleted: [],
      reopened: [],
      flagged: [],
      ledgerTrimmed: 0,
    };
    const run = async (db) => {
      const zone = await loadPetHomeTimezone(db, entry.pet_id);
      const today = repairTodayIsoForZone(zone, {
        overrideTodayIso: todayIsoOverride,
        instant: asOfInstant,
      });
      report.todayIso = today;
      report.timeZone = zone;
      const rows = (await db.query(
        `SELECT * FROM health_occurrences WHERE health_entry_id = $1 AND origin = 'schedule'`,
        [entry.id],
      )).rows;
      const bySlot = new Map();
      for (const row of rows) {
        const key = slotKey(row);
        if (!bySlot.has(key)) bySlot.set(key, []);
        bySlot.get(key).push(row);
      }
      for (const [, group] of bySlot) {
        if (group.length <= 1) continue;
        const keeper = pickKeeper(group);
        for (const row of group) {
          if (row.id === keeper.id) continue;
          if (personActedOn(row)) {
            report.flagged.push({ id: row.id, reason: 'person_acted_duplicate' });
            continue;
          }
          if (row.close_reason !== 'not_recorded' || row.marked_by_user_id) {
            report.flagged.push({ id: row.id, reason: 'not_safe_to_delete' });
            continue;
          }
          if (await hasDependentRows(db, row.id)) {
            report.flagged.push({ id: row.id, reason: 'has_dependent_rows' });
            continue;
          }
          report.deleted.push(row.id);
          if (apply) {
            await deleteNotRecordedScheduleOccurrence(db, entry.id, row.id);
          }
        }
      }
      const reopenIds = planWronglyClosedReopens({
        entry,
        rows,
        deletedIds: report.deleted,
        todayIso: today,
      });
      report.reopened.push(...reopenIds);
      if (apply) {
        for (const id of reopenIds) {
          await reopenClosedOccurrence(db, id);
        }
      }
      if (apply && (report.deleted.length || report.reopened.length)) {
        const events = await db.query(
          `SELECT id, payload FROM care_schedule_events
           WHERE health_entry_id = $1 AND event_type = 'not_recorded_closed' AND actor_user_id IS NULL`,
          [entry.id],
        );
        for (const ev of events.rows) {
          const ids = Array.isArray(ev.payload?.occurrence_ids) ? ev.payload.occurrence_ids : [];
          const next = ids.filter((id) => !report.deleted.includes(id));
          if (next.length === ids.length) continue;
          report.ledgerTrimmed += 1;
          if (next.length === 0) {
            await db.query('DELETE FROM care_schedule_events WHERE id = $1', [ev.id]);
          } else {
            await db.query(
              'UPDATE care_schedule_events SET payload = $2 WHERE id = $1',
              [ev.id, JSON.stringify({ ...ev.payload, occurrence_ids: next })],
            );
          }
        }
        const asOf = careAsOfForZone(zone, null, asOfInstant);
        asOf.todayIso = today;
        await syncOpenOccurrences(db, entry, asOf);
        await insertCareScheduleEvent(db, {
          healthEntryId: entry.id,
          eventType: 'data_repair',
          reasonCode: 'tz_shift_2026_10',
          payload: {
            deleted: report.deleted,
            reopened: report.reopened,
            flagged: report.flagged,
          },
        });
      }
    };
    if (apply) {
      await withCareItemLock(pool, entry.id, run);
    } else {
      const client = await pool.connect();
      try {
        await run(client);
      } finally {
        client.release();
      }
    }
    if (report.deleted.length || report.reopened.length || report.flagged.length) {
      reports.push(report);
    }
  }
  return reports;
}
