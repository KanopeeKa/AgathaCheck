import { dateToIsoDate, todayCalendarIso } from '../../lib/calendarDate.js';
import {
  insertOccurrencesForDay,
  materialisationAnchor,
  syncNextDueDateFromOccurrences,
} from '../../lib/occurrenceScheduling.js';

/**
 * Backfill pending occurrences for active health entries (dev / non-prod cleanup).
 * Clamps recurring schedules to today; one all-day pending row per entry.
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
      `SELECT id FROM health_occurrences WHERE health_entry_id = $1 LIMIT 1`,
      [entry.id]
    );
    if (existing.rows.length > 0) continue;

    const freq = entry.frequency || 'once';
    if (freq === 'once') {
      const dateIso = dateToIsoDate(entry.next_due_date)
        || dateToIsoDate(entry.start_date)
        || today;
      await insertOccurrencesForDay(client, entry, dateIso);
    } else {
      const anchor = materialisationAnchor(dateToIsoDate(entry.start_date), today);
      const dateIso = dateToIsoDate(entry.next_due_date);
      const useDate = dateIso && dateIso >= today ? dateIso : anchor;
      await insertOccurrencesForDay(client, { ...entry, schedule_times: entry.schedule_times }, useDate);
    }
    await syncNextDueDateFromOccurrences(client, entry.id);
  }
}
