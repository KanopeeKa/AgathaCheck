/**
 * Batch read of same-day completions for care item list wires.
 */

import { normalizeOccurrenceRow } from './occurrenceRowNormalize.js';

/**
 * Completions whose `completed_on` is each item's pet-home today (list/card reads).
 *
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {{ id: string, todayIso: string }[]} entryToday
 * @returns {Promise<Map<string, object[]>>} normalized rows per entry, earliest slot first
 */
export async function listCompletionsTodayByEntry(db, entryToday) {
  const map = new Map();
  if (entryToday.length === 0) return map;
  const ids = entryToday.map((e) => e.id);
  const todaySet = [...new Set(entryToday.map((e) => e.todayIso))];
  const todayByEntry = new Map(entryToday.map((e) => [e.id, e.todayIso]));
  for (const id of ids) map.set(id, []);
  const result = await db.query(
    `SELECT * FROM health_occurrences
     WHERE health_entry_id = ANY($1::uuid[])
       AND status = 'completed'
       AND completed_on = ANY($2::date[])
     ORDER BY health_entry_id,
       COALESCE(scheduled_time, '00:00:00'::time) ASC,
       marked_at ASC NULLS LAST`,
    [ids, todaySet],
  );
  for (const row of result.rows) {
    const todayIso = todayByEntry.get(row.health_entry_id);
    const normalized = normalizeOccurrenceRow(row);
    if (normalized.completed_on !== todayIso) continue;
    map.get(row.health_entry_id)?.push(normalized);
  }
  return map;
}
