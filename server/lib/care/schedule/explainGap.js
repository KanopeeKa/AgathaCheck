/**
 * Read-only schedule event facts from care_schedule_events (CSM-13).
 * Returns raw ledger rows for CIM — no explained/unexplained vocabulary.
 */

import { dateToIsoDate, normalizeCalendarDateInput } from '../../calendarDate.js';

/**
 * @param {object} row care_schedule_events row
 * @returns {object}
 */
export function scheduleEventToFact(row) {
  return {
    id: row.id,
    event_type: row.event_type,
    occurrence_id: row.health_occurrence_id || null,
    from_date: dateToIsoDate(row.from_date),
    to_date: dateToIsoDate(row.to_date),
    from_anchor: row.from_anchor || null,
    to_anchor: row.to_anchor || null,
    reason_code: row.reason_code || null,
    reason_note: row.reason_note || null,
    occurred_at: row.occurred_at?.toISOString?.() || String(row.occurred_at),
    effective_from: dateToIsoDate(row.effective_from),
    policy_version: row.policy_version,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} params
 * @param {object} params.entry health_entries row
 * @param {string|Date} [params.fromDate] optional window start (YYYY-MM-DD)
 * @param {string|Date} [params.toDate] optional window end (YYYY-MM-DD)
 * @returns {Promise<{ events: object[] }>}
 */
export async function explainGap(pool, { entry, fromDate, toDate }) {
  const fromDateIso = normalizeCalendarDateInput(fromDate);
  const toDateIso = normalizeCalendarDateInput(toDate);

  const result = await pool.query(
    `SELECT *
     FROM care_schedule_events
     WHERE health_entry_id = $1
       AND (
         ($2::date IS NULL AND $3::date IS NULL)
         OR (
           (from_date IS NOT NULL
             AND ($3::date IS NULL OR from_date <= $3::date)
             AND ($2::date IS NULL OR from_date >= $2::date))
           OR (to_date IS NOT NULL
             AND ($3::date IS NULL OR to_date <= $3::date)
             AND ($2::date IS NULL OR to_date >= $2::date))
           OR (effective_from IS NOT NULL
             AND ($3::date IS NULL OR effective_from <= $3::date)
             AND ($2::date IS NULL OR effective_from >= $2::date))
           OR (
             from_date IS NOT NULL AND to_date IS NOT NULL
             AND ($2::date IS NULL OR to_date >= $2::date)
             AND ($3::date IS NULL OR from_date <= $3::date)
           )
         )
       )
     ORDER BY occurred_at ASC, created_at ASC`,
    [entry.id, fromDateIso, toDateIso],
  );

  return {
    events: result.rows.map(scheduleEventToFact),
  };
}
