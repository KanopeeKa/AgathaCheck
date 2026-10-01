/**
 * Care tick (D-CSM-031): every 15 minutes, one item per transaction.
 *
 * Fixed-schedule items get the slots that became due plus the next series
 * date; stack slots older than three days close as Not recorded; items whose
 * `paused_until` has arrived resume. Never creates `computed` dates.
 */

import { loadPetHomeTimezone } from '../../petHomeTimezone.js';
import { logger } from '../../logger.js';
import { careAsOfForZone } from './careAsOf.js';
import { syncOpenOccurrences } from './syncOpenOccurrences.js';

export const CARE_TICK_LOCK_KEY = 7_311_015;

/**
 * @param {import('pg').Pool} pool
 * @param {{ now?: Date, clock?: { todayIso: string, nowTimeIso: string }|null }} [options]
 * @returns {Promise<{ skipped: boolean, processed: number, created: number, closed: number }>}
 */
export async function runCareTick(pool, { now = new Date(), clock = null } = {}) {
  const lockClient = await pool.connect();
  let locked = false;
  const stats = { skipped: false, processed: 0, created: 0, closed: 0 };
  try {
    const got = await lockClient.query('SELECT pg_try_advisory_lock($1) AS ok', [CARE_TICK_LOCK_KEY]);
    locked = Boolean(got.rows[0]?.ok);
    if (!locked) return { ...stats, skipped: true };

    const candidates = await lockClient.query(
      `SELECT id FROM health_entries
       WHERE status IN ('active', 'paused')
         AND COALESCE(care_planning, 'planned') <> 'unplanned'
         AND COALESCE(frequency, 'once') <> 'once'
         AND (recurrence_anchor = 'from_due_date' OR paused_until IS NOT NULL)
       ORDER BY id`,
    );

    for (const { id } of candidates.rows) {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const row = await client.query(
          'SELECT * FROM health_entries WHERE id = $1 FOR UPDATE SKIP LOCKED',
          [id],
        );
        const entry = row.rows[0];
        if (!entry) {
          await client.query('ROLLBACK');
          continue;
        }
        const zone = await loadPetHomeTimezone(client, entry.pet_id);
        const asOf = careAsOfForZone(zone, clock, now);
        const synced = await syncOpenOccurrences(client, entry, asOf);
        await client.query('COMMIT');
        stats.processed += 1;
        stats.created += synced.created.length;
        stats.closed += synced.closedNotRecorded.length;
      } catch (err) {
        await client.query('ROLLBACK').catch(() => {});
        logger.error({ err, entryId: id }, 'care tick failed for one item');
      } finally {
        client.release();
      }
    }
    return stats;
  } finally {
    if (locked) {
      await lockClient.query('SELECT pg_advisory_unlock($1)', [CARE_TICK_LOCK_KEY]).catch(() => {});
    }
    lockClient.release();
  }
}
