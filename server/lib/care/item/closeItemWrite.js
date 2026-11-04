/**
 * Persist care item Closed status (CARE-STATUS-R-009, R-010).
 */

import { dateToIsoDate } from '../../calendarDate.js';
import { reloadEntry } from '../occurrence/entryRepository.js';
import {
  CARE_CLOSED_REASON_ENDED,
  CARE_ITEM_STATUS_CLOSED,
} from './itemStatus.js';

/**
 * Close a care item because the series ended naturally (once done or past end date).
 *
 * @param {import('pg').PoolClient} db
 * @param {string} entryId
 * @param {{ completedOn?: string|null, completedAt?: Date|null, repeatEndDate?: string|null }} [fields]
 */
export async function closeItemAsEnded(db, entryId, fields = {}) {
  const completedOn = fields.completedOn ?? null;
  const completedAt = fields.completedAt ?? null;
  const repeatEndDate = fields.repeatEndDate;
  const result = await db.query(
    `UPDATE health_entries SET
       status = $2,
       care_closed_reason = $3,
       completed_on = COALESCE($4::date, completed_on),
       completed_at = COALESCE($5, completed_at),
       repeat_end_date = COALESCE($6::date, repeat_end_date),
       updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [
      entryId,
      CARE_ITEM_STATUS_CLOSED,
      CARE_CLOSED_REASON_ENDED,
      completedOn,
      completedAt,
      repeatEndDate,
    ],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').PoolClient} db
 * @param {object} entry health_entries row
 * @param {{ todayIso: string }} asOf
 */
export async function closeItemIfSeriesFinished(db, entry, asOf) {
  if ((entry.status || 'active') !== 'active') return entry;
  const completedOn = dateToIsoDate(entry.completed_on);
  const endIso = dateToIsoDate(entry.repeat_end_date);
  if ((entry.frequency || 'once') === 'once' || entry.frequency == null) {
    if (!completedOn) return entry;
    return closeItemAsEnded(db, entry.id, {
      completedOn,
      completedAt: entry.completed_at ?? new Date(),
    });
  }
  if (!endIso) return entry;
  return closeItemAsEnded(db, entry.id, { repeatEndDate: endIso });
}
