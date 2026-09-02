/**
 * Health occurrence scheduling — materialisation, missed predicates, wire maps.
 * Calendar dates follow server/lib/calendarDate.js (UTC session day for API).
 */

import { v4 as uuidv4 } from 'uuid';

import {
  addCalendarDaysIso,
  dateToIsoDate,
  normalizeCalendarDateInput,
  todayCalendarIso,
} from './calendarDate.js';
import { advanceByFrequency } from './recurrenceHelper.js';

/**
 * @param {object|null|undefined} row health_entries row or body
 * @returns {(string|null)[]} wall-clock HH:MM or [null] for all-day
 */
export function scheduleTimesFromEntry(row) {
  const raw = row?.schedule_times ?? row?.scheduleTimes;
  if (raw == null) return [null];
  if (Array.isArray(raw)) {
    if (raw.length === 0) return [null];
    return raw.map((t) => (t == null || t === '' ? null : normalizeTime(t)));
  }
  return [null];
}

/**
 * @param {string|null|undefined} value
 * @returns {string|null} HH:MM
 */
export function normalizeTime(value) {
  if (value == null || value === '') return null;
  const s = String(value).trim();
  const m = /^(\d{1,2}):(\d{2})(?::\d{2})?$/.exec(s);
  if (!m) return null;
  const hh = Number(m[1]);
  const mm = Number(m[2]);
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
  return `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`;
}

/**
 * @param {string|null} startDateIso
 * @param {string} todayIso
 * @returns {string}
 */
export function materialisationAnchor(startDateIso, todayIso) {
  const start = startDateIso || todayIso;
  return start > todayIso ? start : todayIso;
}

/**
 * Anchor for first occurrence materialisation at entry create.
 * Preserves an explicit overdue next_due_date so notifications and missed
 * predicates still see the intended calendar day.
 *
 * @param {string|null} startDateIso
 * @param {string|null} nextDueIso
 * @param {string} todayIso
 * @returns {string}
 */
export function initialMaterialisationAnchor(startDateIso, nextDueIso, todayIso) {
  if (nextDueIso && nextDueIso < todayIso) {
    return nextDueIso;
  }
  return materialisationAnchor(startDateIso, todayIso);
}

/**
 * @param {object} row health_entries row
 * @returns {boolean}
 */
export function isOnceEntry(row) {
  return (row.frequency || 'once') === 'once';
}

/**
 * @param {object} row
 * @returns {boolean}
 */
export function isMultiPerDayEntry(row) {
  const times = scheduleTimesFromEntry(row);
  return times.length > 1;
}

/**
 * @param {string} targetDateIso
 * @param {string} todayIso
 * @returns {boolean} calendar T-1 rule
 */
export function isWithinMaterialisationWindow(targetDateIso, todayIso) {
  const trigger = addCalendarDaysIso(targetDateIso, -1);
  return todayIso >= trigger;
}

/**
 * Missed predicate for API (server calendar day; clients may refine with local TZ).
 *
 * @param {string} scheduledDateIso YYYY-MM-DD
 * @param {string|null} scheduledTime HH:MM or null (all-day)
 * @param {string} todayIso
 * @param {string|null} nowTimeIso HH:MM from server clock (for timed today)
 */
export function isOccurrenceMissed(scheduledDateIso, scheduledTime, todayIso, nowTimeIso) {
  if (!scheduledDateIso) return false;
  if (scheduledDateIso < todayIso) return true;
  if (scheduledDateIso > todayIso) return false;
  if (scheduledTime == null) return false;
  const nowT = nowTimeIso || '00:00';
  return nowT > scheduledTime;
}

/**
 * @param {object} row DB row
 * @returns {object}
 */
export function occurrenceToMap(row) {
  const time = row.scheduled_time
    ? String(row.scheduled_time).slice(0, 5)
    : null;
  return {
    id: row.id,
    health_entry_id: row.health_entry_id,
    entry_id: row.health_entry_id,
    scheduled_date: dateToIsoDate(row.scheduled_date),
    scheduled_time: time,
    status: row.status,
    completed_on: row.completed_on ? dateToIsoDate(row.completed_on) : null,
    marked_at: row.marked_at ? row.marked_at.toISOString?.() || String(row.marked_at) : null,
    marked_by_user_id: row.marked_by_user_id || null,
    marked_by_name: row.marked_by_name?.trim() || null,
    notes: row.notes || '',
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} entryId
 */
export async function syncNextDueDateFromOccurrences(pool, entryId) {
  const pending = await pool.query(
    `SELECT scheduled_date, scheduled_time FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending'
     ORDER BY scheduled_date ASC,
       COALESCE(scheduled_time, '00:00:00'::time) ASC
     LIMIT 1`,
    [entryId]
  );
  const nextDate = pending.rows[0]
    ? dateToIsoDate(pending.rows[0].scheduled_date)
    : null;
  await pool.query(
    `UPDATE health_entries SET next_due_date = $1, updated_at = NOW() WHERE id = $2`,
    [nextDate, entryId]
  );
  return nextDate;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 * @param {string} dateIso YYYY-MM-DD
 */
export async function insertOccurrencesForDay(pool, entry, dateIso) {
  const times = scheduleTimesFromEntry(entry);
  const created = [];
  for (const time of times) {
    const dup = await pool.query(
      `SELECT id FROM health_occurrences
       WHERE health_entry_id = $1 AND scheduled_date = $2
         AND (($3::time IS NULL AND scheduled_time IS NULL)
           OR scheduled_time = $3::time)
         AND status = 'pending'`,
      [entry.id, dateIso, time]
    );
    if (dup.rows.length > 0) continue;
    const id = uuidv4();
    await pool.query(
      `INSERT INTO health_occurrences
         (id, health_entry_id, scheduled_date, scheduled_time, status)
       VALUES ($1, $2, $3, $4, 'pending')`,
      [id, entry.id, dateIso, time]
    );
    created.push(id);
  }
  return created;
}

/**
 * Initial materialisation at entry create (and backfill).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row (must include id, frequency, start_date, schedule_times)
 * @param {string} [todayIso]
 */
export async function materialiseInitialOccurrences(pool, entry, todayIso = todayCalendarIso()) {
  const startIso = dateToIsoDate(entry.start_date);
  const nextDueIso = dateToIsoDate(entry.next_due_date);
  if (isOnceEntry(entry)) {
    const dateIso = startIso || nextDueIso || todayIso;
    await insertOccurrencesForDay(pool, entry, dateIso);
    await syncNextDueDateFromOccurrences(pool, entry.id);
    return;
  }

  const anchor = initialMaterialisationAnchor(startIso, nextDueIso, todayIso);
  await insertOccurrencesForDay(pool, entry, anchor);

  if (isMultiPerDayEntry(entry)) {
    const nextDay = addCalendarDaysIso(anchor, 1);
    if (isWithinMaterialisationWindow(nextDay, todayIso)) {
      await insertOccurrencesForDay(pool, entry, nextDay);
    }
  }

  await syncNextDueDateFromOccurrences(pool, entry.id);
}

/**
 * When a once-entry's last pending occurrence closes, mirror legacy mark-taken
 * by completing the parent health_entries row.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 */
async function finalizeOnceEntryIfNoPending(pool, entry) {
  if (!isOnceEntry(entry)) return;
  const pending = await pool.query(
    `SELECT 1 FROM health_occurrences WHERE health_entry_id = $1 AND status = 'pending' LIMIT 1`,
    [entry.id]
  );
  if (pending.rows.length > 0) return;

  const closed = await pool.query(
    `SELECT completed_on FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'completed'
     ORDER BY marked_at DESC NULLS LAST LIMIT 1`,
    [entry.id]
  );
  if (closed.rows.length === 0) return;

  const completedOn = dateToIsoDate(closed.rows[0].completed_on) || todayCalendarIso();
  await pool.query(
    `UPDATE health_entries SET status = 'completed', completed_on = $1,
      completed_at = NOW(), next_due_date = NULL, updated_at = NOW()
     WHERE id = $2 AND status != 'completed'`,
    [completedOn, entry.id]
  );
}

/**
 * After an occurrence closes, roll forward pending materialisation.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry
 * @param {string} [todayIso]
 */
export async function materialiseAfterOccurrenceClose(pool, entry, todayIso = todayCalendarIso()) {
  if (isOnceEntry(entry)) {
    await syncNextDueDateFromOccurrences(pool, entry.id);
    await finalizeOnceEntryIfNoPending(pool, entry);
    return;
  }

  const openDay = await pool.query(
    `SELECT DISTINCT scheduled_date FROM health_occurrences
     WHERE health_entry_id = $1 AND status = 'pending'
     ORDER BY scheduled_date ASC`,
    [entry.id]
  );
  const openDates = openDay.rows.map((r) => dateToIsoDate(r.scheduled_date));

  if (openDates.length === 0) {
    const lastClosed = await pool.query(
      `SELECT scheduled_date FROM health_occurrences
       WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
       ORDER BY scheduled_date DESC,
         COALESCE(scheduled_time, '00:00:00'::time) DESC
       LIMIT 1`,
      [entry.id]
    );
    const base = lastClosed.rows[0]
      ? dateToIsoDate(lastClosed.rows[0].scheduled_date)
      : materialisationAnchor(dateToIsoDate(entry.start_date), todayIso);
    const nextDay = addCalendarDaysIso(base, 1);
    if (isWithinMaterialisationWindow(nextDay, todayIso) || nextDay <= todayIso) {
      await insertOccurrencesForDay(pool, entry, nextDay);
    } else {
      const freqNext = advanceByFrequency(base, entry);
      if (freqNext && isWithinMaterialisationWindow(freqNext, todayIso)) {
        await insertOccurrencesForDay(pool, entry, freqNext);
      }
    }
  } else if (!isMultiPerDayEntry(entry)) {
    const earliest = openDates[0];
    const pendingOnEarliest = await pool.query(
      `SELECT COUNT(*)::int AS c FROM health_occurrences
       WHERE health_entry_id = $1 AND scheduled_date = $2 AND status = 'pending'`,
      [entry.id, earliest]
    );
    if (pendingOnEarliest.rows[0].c === 0) {
      const nextDay = addCalendarDaysIso(earliest, 1);
      if (isWithinMaterialisationWindow(nextDay, todayIso)) {
        await insertOccurrencesForDay(pool, entry, nextDay);
      }
    }
  } else {
    for (const dateIso of [...openDates]) {
      const remaining = await pool.query(
        `SELECT COUNT(*)::int AS c FROM health_occurrences
         WHERE health_entry_id = $1 AND scheduled_date = $2 AND status = 'pending'`,
        [entry.id, dateIso]
      );
      if (remaining.rows[0].c > 0) continue;
      const nextDay = addCalendarDaysIso(dateIso, 1);
      if (isWithinMaterialisationWindow(nextDay, todayIso)) {
        await insertOccurrencesForDay(pool, entry, nextDay);
      }
    }
  }

  await syncNextDueDateFromOccurrences(pool, entry.id);
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} entryId
 * @param {string} [todayIso]
 * @param {string|null} [nowTimeIso]
 */
export async function listOpenOccurrences(pool, entryId, todayIso = todayCalendarIso(), nowTimeIso = null) {
  const result = await pool.query(
    `SELECT ho.*,
      TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
     FROM health_occurrences ho
     LEFT JOIN users u ON u.id = ho.marked_by_user_id
     WHERE ho.health_entry_id = $1 AND ho.status = 'pending'
     ORDER BY ho.scheduled_date DESC,
       COALESCE(ho.scheduled_time, '00:00:00'::time) DESC`,
    [entryId]
  );
  return result.rows.map((row) => {
    const map = occurrenceToMap(row);
    map.missed = isOccurrenceMissed(
      map.scheduled_date,
      map.scheduled_time,
      todayIso,
      nowTimeIso
    );
    return map;
  });
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} entryId
 * @param {string} [todayIso]
 * @param {string|null} [nowTimeIso]
 */
export async function listMissedOccurrenceIds(pool, entryId, todayIso = todayCalendarIso(), nowTimeIso = null) {
  const open = await listOpenOccurrences(pool, entryId, todayIso, nowTimeIso);
  return open.filter((o) => o.missed).map((o) => o.id);
}

/**
 * Parse schedule_times from create/update body.
 * @param {object} data
 * @returns {object|null} JSONB-ready value
 */
export function parseScheduleTimesInput(data) {
  const raw = data.schedule_times ?? data.scheduleTimes;
  if (raw === undefined) return undefined;
  if (raw === null) return null;
  if (!Array.isArray(raw)) return null;
  if (raw.length === 0) return null;
  return raw.map((t) => normalizeTime(t));
}

/**
 * @param {string|null|undefined} completedOnBody
 * @param {string} todayIso
 */
export function resolveCompletedOn(completedOnBody, todayIso = todayCalendarIso()) {
  return normalizeCalendarDateInput(completedOnBody) || todayIso;
}
