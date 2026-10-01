import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate, todayCalendarIso } from '../../lib/calendarDate.js';

/**
 * Backfill one open occurrence for active health entries created before 047
 * (dev / non-prod cleanup). Migration 083 then rebuilds them with the
 * occurrence engine (D-CSM-019).
 *
 * @param {import('pg').PoolClient} client
 */
export async function backfillHealthOccurrences(client) {
  const today = todayCalendarIso();
  const { rows } = await client.query(
    `SELECT * FROM health_entries
     WHERE status = 'active'
       AND (frequency IS NULL OR frequency != 'once' OR completed_on IS NULL)`
  );

  for (const entry of rows) {
    const existing = await client.query(
      'SELECT id FROM health_occurrences WHERE health_entry_id = $1 LIMIT 1',
      [entry.id]
    );
    if (existing.rows.length > 0) continue;
    const due = dateToIsoDate(entry.next_due_date);
    const start = dateToIsoDate(entry.start_date);
    const dateIso = (entry.frequency || 'once') === 'once'
      ? (due || start || today)
      : (due && due >= today ? due : (start && start > today ? start : today));
    await client.query(
      `INSERT INTO health_occurrences (id, health_entry_id, scheduled_date, scheduled_time, status)
       VALUES ($1, $2, $3, NULL, 'pending')`,
      [uuidv4(), entry.id, dateIso]
    );
    await client.query(
      'UPDATE health_entries SET next_due_date = $1 WHERE id = $2',
      [dateIso, entry.id]
    );
  }
}
