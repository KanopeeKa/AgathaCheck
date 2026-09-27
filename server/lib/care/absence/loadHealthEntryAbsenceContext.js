import { dateToIsoDate, todayCalendarIso } from '../../calendarDate.js';
import { loadAwayPlanProjection } from '../awayPlan/loadAwayPlanProjection.js';
import {
  PLANNED_ABSENCE_STATUS_CANCELLED,
  carerRowToMap,
} from '../plannedAbsence.js';
import { isCareItemAffectedByAbsence } from './affectedCareItem.js';
import { deriveResolutionUiState } from './deriveResolutionState.js';
import {
  defaultSuggestedDecision,
  loadResolutionsByEntryIds,
  resolutionRowToMap,
  suggestedLookedAfterFromPetCarer,
} from './resolutionRepository.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} entry health_entries row
 * @param {string} userId
 */
export async function loadHealthEntryAbsenceContext(pool, entry, userId) {
  const todayIso = todayCalendarIso();
  const result = await pool.query(
    `SELECT pa.*
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap ON pap.planned_absence_id = pa.id
     WHERE pa.user_id = $1
       AND pap.pet_id = $2
       AND pa.status != $3
       AND pa.ends_on >= $4::date
     ORDER BY pa.starts_on ASC`,
    [userId, entry.pet_id, PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
  );

  const absences = [];
  for (const absenceRow of result.rows) {
    const startsOn = dateToIsoDate(absenceRow.starts_on);
    const endsOn = dateToIsoDate(absenceRow.ends_on);
    if (!startsOn || !endsOn) continue;

    const projection = await loadAwayPlanProjection(
      pool,
      entry.pet_id,
      startsOn,
      endsOn,
      todayIso
    );
    const plannedRow = (projection.planned_care_items || []).find(
      (row) => row.health_entry_id === entry.id
    );
    const affected = plannedRow ? isCareItemAffectedByAbsence(plannedRow) : false;
    const resolutionRows = await loadResolutionsByEntryIds(pool, absenceRow.id, [entry.id]);
    const resolutionDbRow = resolutionRows.get(entry.id) || null;
    const uiState = plannedRow
      ? deriveResolutionUiState(resolutionDbRow, plannedRow, {
          startsOn,
          endsOn,
          projectionItems: projection.items,
        })
      : 'nothing_due';

    const petCarerResult = await pool.query(
      `SELECT carer_kind, carer_user_id, carer_name, carer_note, pet_id
       FROM planned_absence_pets
       WHERE planned_absence_id = $1 AND pet_id = $2`,
      [absenceRow.id, entry.pet_id]
    );
    const petCarerRow = petCarerResult.rows[0] || null;
    const suggestedLookedAfterBy = suggestedLookedAfterFromPetCarer(petCarerRow);

    absences.push({
      planned_absence_id: absenceRow.id,
      starts_on: startsOn,
      ends_on: endsOn,
      affected,
      ui_state: uiState,
      planned_care: plannedRow || null,
      resolution: resolutionDbRow ? resolutionRowToMap(resolutionDbRow) : null,
      suggested_looked_after_by: suggestedLookedAfterBy,
      suggested_decision: affected && uiState === 'not_reviewed'
        ? defaultSuggestedDecision()
        : null,
      pet_carer: petCarerRow ? carerRowToMap(petCarerRow) : null,
    });
  }

  return {
    health_entry_id: entry.id,
    pet_id: entry.pet_id,
    absences,
  };
}
