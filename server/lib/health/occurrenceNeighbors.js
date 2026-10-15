/**
 * Chronological previous/next occurrence summaries for the Care date leaf (CARE-ITEM-R-020).
 */

import {
  normalizeOccurrenceRow,
  openOccurrenceToWire,
} from '../care/occurrence/index.js';
import { occurrenceToMap } from '../care/item/index.js';

function occurrenceStatusFor(row, entry, asOf) {
  if (row.status === 'completed') return 'done';
  if (row.status === 'skipped') {
    return row.close_reason === 'not_recorded' ? 'not_recorded' : 'skipped';
  }
  return openOccurrenceToWire(normalizeOccurrenceRow(row), entry, asOf).status;
}

function performerDisplayName(row) {
  const snap = row.performed_by_snapshot;
  if (snap && typeof snap === 'object') {
    const first = snap.first_name ?? snap.firstName ?? '';
    const last = snap.last_name ?? snap.lastName ?? '';
    const name = `${first} ${last}`.trim();
    if (name) return name;
  }
  return row.marked_by_name?.trim() || null;
}

/**
 * @param {import('pg').Pool} pool
 * @param {object} entry health_entries row
 * @param {string} currentOccId
 * @param {object} asOf
 * @returns {Promise<{ previous_occurrence: object|null, next_occurrence: object|null }>}
 */
export async function occurrenceNeighborsForRead(pool, entry, currentOccId, asOf) {
  const result = await pool.query(
    `SELECT ho.*,
      TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
     FROM health_occurrences ho
     LEFT JOIN users u ON u.id = ho.marked_by_user_id
     WHERE ho.health_entry_id = $1
     ORDER BY ho.scheduled_date ASC,
       ho.scheduled_time ASC NULLS FIRST,
       ho.id ASC`,
    [entry.id],
  );
  const rows = result.rows;
  const idx = rows.findIndex((r) => r.id === currentOccId);
  if (idx < 0) {
    return { previous_occurrence: null, next_occurrence: null };
  }

  const toSummary = (row) => {
    const base = occurrenceToMap(row);
    return {
      id: base.id,
      scheduled_date: base.scheduled_date,
      scheduled_time: base.scheduled_time,
      occurrence_status: occurrenceStatusFor(row, entry, asOf),
      completed_on: base.completed_on,
      performed_by_name: performerDisplayName(row),
    };
  };

  const previous = idx > 0 ? toSummary(rows[idx - 1]) : null;
  const next = idx < rows.length - 1 ? toSummary(rows[idx + 1]) : null;
  return { previous_occurrence: previous, next_occurrence: next };
}
