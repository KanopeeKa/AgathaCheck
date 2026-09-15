/**
 * Care-period projection — server-authoritative scheduling preview for a date window.
 *
 * Thin wrapper over schedule/projectSchedule.js for Care Context backward compatibility.
 */

export {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
  PROJECTION_STATUS_COMPLETE,
  PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
  UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN,
  UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
  isDateInCareWindow,
  projectCareForPeriod,
  projectEntryForPeriod,
} from './schedule/projectSchedule.js';

import { projectCareForPeriod } from './schedule/projectSchedule.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} [todayIso]
 */
export async function loadAndProjectCareForPeriod(pool, petId, startsOn, endsOn, todayIso) {
  const entriesResult = await pool.query(
    'SELECT * FROM health_entries WHERE pet_id = $1 ORDER BY created_at ASC',
    [petId]
  );

  const occurrencesResult = await pool.query(
    `SELECT ho.*
     FROM health_occurrences ho
     INNER JOIN health_entries he ON he.id = ho.health_entry_id
     WHERE he.pet_id = $1
       AND (
         (ho.scheduled_date >= $2::date AND ho.scheduled_date <= $3::date)
         OR ho.status = 'pending'
       )`,
    [petId, startsOn, endsOn]
  );

  const occurrencesByEntryId = new Map();
  for (const row of occurrencesResult.rows) {
    const list = occurrencesByEntryId.get(row.health_entry_id) || [];
    list.push(row);
    occurrencesByEntryId.set(row.health_entry_id, list);
  }

  const projection = projectCareForPeriod(
    entriesResult.rows,
    occurrencesByEntryId,
    startsOn,
    endsOn,
    todayIso
  );

  return {
    pet_id: petId,
    ...projection,
  };
}
