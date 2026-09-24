import {
  loadScheduleDataForProjection,
  projectSchedule,
} from '../schedule/projectSchedule.js';
import { formatProjectionReadContract } from './formatProjectionReadContract.js';

/**
 * Load schedule data, project the window, and shape the Away Planning read contract.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} startsOn
 * @param {string} endsOn
 * @param {string} [todayIso]
 */
export async function loadAwayPlanProjection(pool, petId, startsOn, endsOn, todayIso) {
  const { entries, occurrencesByEntryId } = await loadScheduleDataForProjection(
    pool,
    petId,
    startsOn,
    endsOn
  );

  const projection = projectSchedule(
    entries,
    occurrencesByEntryId,
    startsOn,
    endsOn,
    todayIso
  );

  return formatProjectionReadContract(
    {
      pet_id: petId,
      today_iso: todayIso,
      ...projection,
    },
    entries
  );
}
