/**
 * Care item row reads/writes used by occurrence commands.
 */

import { dateToIsoDate } from '../../calendarDate.js';

/**
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 */
export async function reloadEntry(db, entryId) {
  const result = await db.query('SELECT * FROM health_entries WHERE id = $1', [entryId]);
  return result.rows[0] || null;
}

const UPDATABLE = new Set([
  'status',
  'paused_since',
  'paused_until',
  'series_resumed_on',
  'schedule_anchor_date',
  'late_completion_choice',
  'schedule_times',
  'completed_on',
  'completed_at',
  'next_due_date',
  'recurrence_anchor',
]);

/**
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {object} fields subset of UPDATABLE
 */
export async function updateEntryFields(db, entryId, fields) {
  const keys = Object.keys(fields).filter((k) => UPDATABLE.has(k));
  if (keys.length === 0) return reloadEntry(db, entryId);
  const sets = keys.map((k, i) => (k === 'schedule_times'
    ? `${k} = $${i + 1}::jsonb`
    : `${k} = $${i + 1}`));
  const values = keys.map((k) => (k === 'schedule_times' && fields[k] != null
    ? JSON.stringify(fields[k])
    : fields[k]));
  const result = await db.query(
    `UPDATE health_entries SET ${sets.join(', ')}, updated_at = NOW()
     WHERE id = $${keys.length + 1} RETURNING *`,
    [...values, entryId],
  );
  return result.rows[0] || null;
}

/**
 * Entry fields restored by undo.
 *
 * @param {object} entry
 */
export function entrySnapshot(entry) {
  return {
    status: entry.status || 'active',
    paused_since: dateToIsoDate(entry.paused_since),
    paused_until: dateToIsoDate(entry.paused_until),
    series_resumed_on: dateToIsoDate(entry.series_resumed_on),
    schedule_anchor_date: dateToIsoDate(entry.schedule_anchor_date),
    late_completion_choice: entry.late_completion_choice ?? null,
    schedule_times: entry.schedule_times ?? null,
    completed_on: dateToIsoDate(entry.completed_on),
    completed_at: entry.completed_at ?? null,
  };
}
