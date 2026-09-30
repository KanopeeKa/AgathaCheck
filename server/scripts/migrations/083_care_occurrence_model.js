import { dateToIsoDate } from '../../lib/calendarDate.js';
import {
  careAsOfForZone,
  syncOpenOccurrences,
} from '../../lib/care/occurrence/index.js';
import { loadPetHomeTimezone } from '../../lib/petHomeTimezone.js';

/**
 * Light hook for migration 083 (pre-launch; UAT data is wiped and reseeded):
 * mark existing open rows with their origin, anchor Fixed-schedule items and
 * run the occurrence sync once per item so INV-1 … INV-5 hold.
 *
 * @param {import('pg').PoolClient} client
 */
export async function migrateCareOccurrenceModel(client) {
  await client.query(
    `UPDATE health_occurrences ho SET origin = 'schedule', series_date = ho.scheduled_date
     FROM health_entries he
     WHERE he.id = ho.health_entry_id AND ho.status = 'pending'
       AND he.recurrence_anchor = 'from_due_date' AND COALESCE(he.frequency, 'once') <> 'once'`,
  );
  await client.query(
    `UPDATE health_occurrences ho SET origin = 'planned'
     FROM health_entries he
     WHERE he.id = ho.health_entry_id AND ho.status = 'pending'
       AND COALESCE(he.frequency, 'once') = 'once'`,
  );
  await client.query(
    `UPDATE health_occurrences SET close_reason = 'user'
     WHERE status IN ('completed', 'skipped') AND close_reason IS NULL`,
  );

  const { rows } = await client.query(
    `SELECT * FROM health_entries
     WHERE status IN ('active', 'paused')
       AND COALESCE(care_planning, 'planned') <> 'unplanned'
     ORDER BY id`,
  );
  for (const entry of rows) {
    if (entry.recurrence_anchor === 'from_due_date' && !entry.schedule_anchor_date) {
      const first = await client.query(
        `SELECT MIN(scheduled_date) AS d FROM health_occurrences WHERE health_entry_id = $1`,
        [entry.id],
      );
      const anchor = dateToIsoDate(first.rows[0]?.d)
        || dateToIsoDate(entry.next_due_date)
        || dateToIsoDate(entry.start_date);
      if (anchor) {
        await client.query(
          'UPDATE health_entries SET schedule_anchor_date = $1 WHERE id = $2',
          [anchor, entry.id],
        );
        entry.schedule_anchor_date = anchor;
      }
    }
    const zone = await loadPetHomeTimezone(client, entry.pet_id);
    // The migration runner owns the transaction for DDL, every item, and
    // the ledger row. Propagate failures so it can roll back the whole batch.
    await syncOpenOccurrences(client, entry, careAsOfForZone(zone));
  }
}
