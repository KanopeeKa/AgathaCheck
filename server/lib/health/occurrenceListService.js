/**
 * Occurrence list read model: open/history occurrence wire for one health entry.
 */

import {
  listOpenRows,
  openOccurrenceToWire,
  resolveCareAsOfForRead,
  syncCareItemForRead,
} from '../care/occurrence/index.js';
import { occurrenceToMap } from '../care/item/index.js';
import { userCanManageHealthEntry } from '../petAccess.js';

const PAST_STATUSES = new Set(['overdue', 'not_recorded']);

export async function loadManagedEntry(pool, entryId, userId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return null;
  }
  const result = await pool.query(
    'SELECT * FROM health_entries WHERE id = $1',
    [entryId],
  );
  return result.rows[0] || null;
}

export async function listOccurrencesForEntry(pool, entry, { status, req }) {
  if (status === 'open') {
    const synced = await syncCareItemForRead(pool, entry.id, req);
    const asOf = synced?.asOf ?? await resolveCareAsOfForRead(pool, entry, req);
    const rows = synced?.openRows ?? await listOpenRows(pool, entry.id);
    const names = await pool.query(
      `SELECT ho.id, TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
       FROM health_occurrences ho LEFT JOIN users u ON u.id = ho.marked_by_user_id
       WHERE ho.health_entry_id = $1 AND ho.status = 'pending'`,
      [entry.id],
    );
    const nameById = new Map(names.rows.map((r) => [r.id, r.marked_by_name]));
    const wire = rows.map((row) => {
      const occStatus = openOccurrenceToWire(row, entry, asOf);
      return {
        ...occurrenceToMap({ ...row, marked_by_name: nameById.get(row.id) }),
        status: 'pending',
        occurrence_status: occStatus.status,
        origin: occStatus.origin,
        missed: PAST_STATUSES.has(occStatus.status),
      };
    });
    wire.sort((a, b) => `${b.scheduled_date}|${b.scheduled_time ?? ''}`
      .localeCompare(`${a.scheduled_date}|${a.scheduled_time ?? ''}`));
    return wire;
  }
  const result = await pool.query(
    `SELECT ho.*,
      TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
     FROM health_occurrences ho
     LEFT JOIN users u ON u.id = ho.marked_by_user_id
     WHERE ho.health_entry_id = $1 AND ho.status IN ('completed', 'skipped')
     ORDER BY ho.scheduled_date DESC,
       COALESCE(ho.scheduled_time, '00:00:00'::time) DESC`,
    [entry.id],
  );
  return result.rows.map(occurrenceToMap);
}
