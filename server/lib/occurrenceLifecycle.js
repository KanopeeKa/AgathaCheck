/**
 * Care event ↔ occurrence lifecycle (close, auto-close, cascade).
 */

import {
  addCalendarDaysIso,
  dateToIsoDate,
  todayCalendarIso,
} from './calendarDate.js';

function isOnceEntry(row) {
  return (row.frequency || 'once') === 'once';
}

/**
 * @param {object} row health_entries row
 * @returns {string|null}
 */
export function repeatEndDateIso(row) {
  return dateToIsoDate(row.repeat_end_date);
}

/**
 * Whether the care event series is closed (manual close, once completed, or past end date).
 *
 * @param {object} row health_entries row
 * @param {string} [todayIso]
 * @returns {boolean}
 */
export function isEntrySeriesClosed(row, todayIso = todayCalendarIso()) {
  if ((row.status || 'active') === 'completed') return true;
  if (isOnceEntry(row)) {
    return Boolean(dateToIsoDate(row.completed_on));
  }
  const endIso = repeatEndDateIso(row);
  if (!endIso) return false;
  return endIso < todayIso;
}

/**
 * @param {object} row
 * @param {string} dateIso
 * @returns {boolean}
 */
export function isOccurrenceDateWithinSeries(row, dateIso) {
  const endIso = repeatEndDateIso(row);
  if (!endIso) return true;
  return dateIso <= endIso;
}

/**
 * When a once-entry's last pending occurrence closes, complete the parent series.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 */
export async function finalizeOnceEntryIfNoPending(pool, entry) {
  if (!isOnceEntry(entry)) return;
  const pending = await pool.query(
    `SELECT 1 FROM health_occurrences WHERE health_entry_id = $1 AND status = 'pending' LIMIT 1`,
    [entry.id]
  );
  if (pending.rows.length > 0) return;

  const closed = await pool.query(
    `SELECT completed_on, scheduled_date, status FROM health_occurrences
     WHERE health_entry_id = $1 AND status IN ('completed', 'skipped')
     ORDER BY marked_at DESC NULLS LAST LIMIT 1`,
    [entry.id]
  );
  if (closed.rows.length === 0) return;

  const row = closed.rows[0];
  const completedOn = dateToIsoDate(row.completed_on)
    || dateToIsoDate(row.scheduled_date)
    || todayCalendarIso();
  await pool.query(
    `UPDATE health_entries SET status = 'completed', completed_on = $1,
      completed_at = NOW(), next_due_date = NULL, updated_at = NOW()
     WHERE id = $2 AND status != 'completed'`,
    [completedOn, entry.id]
  );
}

/**
 * Skip every pending occurrence for a series (manual close or end-date auto-close).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} entryId
 * @param {string|null} userId
 * @param {Date} [markedAt]
 */
export async function skipAllPendingOccurrences(pool, entryId, userId, markedAt = new Date()) {
  const result = await pool.query(
    `UPDATE health_occurrences SET status = 'skipped', marked_at = $1,
      marked_by_user_id = $2, updated_at = NOW()
     WHERE health_entry_id = $3 AND status = 'pending'
     RETURNING id`,
    [markedAt, userId, entryId]
  );
  return result.rows.map((row) => row.id);
}

/**
 * Close a care event and cascade to all pending occurrences.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 * @param {string|null} userId actor for occurrence skips (null for system auto-close)
 * @param {string} [todayIso]
 * @returns {Promise<object>} updated health_entries row
 */
export async function closeHealthEntrySeries(pool, entry, userId, todayIso = todayCalendarIso()) {
  const markedAt = new Date();
  await skipAllPendingOccurrences(pool, entry.id, userId, markedAt);

  if (isOnceEntry(entry)) {
    const result = await pool.query(
      `UPDATE health_entries SET status = 'completed',
        completed_on = COALESCE(completed_on, $1),
        completed_at = COALESCE(completed_at, NOW()),
        next_due_date = NULL, repeat_end_date = NULL, updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [todayIso, entry.id]
    );
    return result.rows[0];
  }

  const repeatEnd = addCalendarDaysIso(todayIso, -1);
  const result = await pool.query(
    `UPDATE health_entries SET status = 'completed', repeat_end_date = $1,
      next_due_date = NULL, updated_at = NOW()
     WHERE id = $2 RETURNING *`,
    [repeatEnd, entry.id]
  );
  return result.rows[0];
}

/**
 * Auto-close recurring series with a repeat end date when the end is reached
 * or every occurrence through the end date has been closed.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 * @param {string} [todayIso]
 * @returns {Promise<object>} latest health_entries row (refreshed when closed)
 */
export async function tryAutoCloseRecurringWithEndDate(pool, entry, todayIso = todayCalendarIso()) {
  if (isOnceEntry(entry) || (entry.status || 'active') === 'completed') {
    return entry;
  }
  const endIso = repeatEndDateIso(entry);
  if (!endIso) return entry;

  const pending = await pool.query(
    `SELECT 1 FROM health_occurrences WHERE health_entry_id = $1 AND status = 'pending' LIMIT 1`,
    [entry.id]
  );

  if (endIso < todayIso) {
    return closeHealthEntrySeries(pool, entry, null, todayIso);
  }

  if (pending.rows.length > 0) return entry;

  const maxRow = await pool.query(
    `SELECT MAX(scheduled_date) AS max_date FROM health_occurrences WHERE health_entry_id = $1`,
    [entry.id]
  );
  const maxIso = dateToIsoDate(maxRow.rows[0]?.max_date);
  if (maxIso && maxIso >= endIso) {
    return closeHealthEntrySeries(pool, entry, null, todayIso);
  }

  return entry;
}
