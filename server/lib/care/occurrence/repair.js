/**
 * Invariant report / repair (INV-1, INV-2, INV-4, INV-5) for runbooks.
 */
import { dateToIsoDate } from '../../calendarDate.js';
import { loadPetHomeTimezone } from '../../petHomeTimezone.js';
import { careAsOfForZone } from './careAsOf.js';
import { withCareItemLock } from './careItemLock.js';
import { listOpenRows } from './occurrenceRepository.js';
import { syncOpenOccurrences } from './syncOpenOccurrences.js';

/**
 * @param {object} entry
 * @param {object[]} open normalized open rows
 * @returns {string[]}
 */
export function invariantViolationsFor(entry, open) {
  const out = [];
  const planned = (entry.care_planning || 'planned') !== 'unplanned';
  if (planned && entry.status === 'active' && open.length === 0) out.push('INV-1');
  if (open.filter((o) => o.origin === 'computed').length > 1) out.push('INV-2');
  if (entry.status === 'completed' && open.length > 0) out.push('INV-4');
  const earliest = open[0]?.scheduled_date ?? null;
  if (entry.status !== 'completed' && dateToIsoDate(entry.next_due_date) !== earliest) out.push('INV-5');
  return out;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ apply?: boolean }} [options]
 * @returns {Promise<{ checked: number, violations: { id: string, name: string, codes: string[] }[], repaired: number }>}
 */
export async function repairOccurrences(pool, { apply = false } = {}) {
  const entries = await pool.query(
    `SELECT * FROM health_entries
     WHERE COALESCE(care_planning, 'planned') <> 'unplanned'
     ORDER BY id`,
  );
  const violations = [];
  let repaired = 0;
  for (const entry of entries.rows) {
    const open = await listOpenRows(pool, entry.id);
    const codes = invariantViolationsFor(entry, open);
    if (codes.length === 0) continue;
    violations.push({ id: entry.id, name: entry.name, codes });
    if (!apply) continue;
    await withCareItemLock(pool, entry.id, async (db, locked) => {
      const zone = await loadPetHomeTimezone(db, locked.pet_id);
      await syncOpenOccurrences(db, locked, careAsOfForZone(zone));
    });
    repaired += 1;
  }
  return { checked: entries.rows.length, violations, repaired };
}
