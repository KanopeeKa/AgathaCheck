/**
 * Away-plan visibility (CARE-CONTEXT-R-032, R-039, R-040, R-041).
 * Full access = record owner, co-parent, or household full_access (userCanManageProfile).
 */

import { enrichAbsencePetCarerContacts } from '../../people/absenceCarer.js';
import { fetchUserSnapshot } from '../../people/userSnapshot.js';
import { CO_PARENT_ROLE, userCanManageProfile } from '../../petAccess.js';
import {
  enrichSharedUserCarerNames,
  PLANNED_ABSENCE_STATUS_CANCELLED,
} from '../plannedAbsence.js';

/** SQL: pet row alias is readable with Full-access profile rights (away plans). */
export function petProfileAccessSql(petAlias, userIdParam) {
  return `(
    ${petAlias}.user_id = ${userIdParam}
    OR EXISTS (
      SELECT 1 FROM pet_access pa
      WHERE pa.pet_id = ${petAlias}.id
        AND pa.user_id = ${userIdParam}
        AND pa.role = '${CO_PARENT_ROLE}'
        AND COALESCE(pa.hidden, false) = false
    )
    OR EXISTS (
      SELECT 1 FROM household_pets hp
      INNER JOIN household_members hm ON hm.household_id = hp.household_id
      WHERE hp.pet_id = ${petAlias}.id
        AND hm.user_id = ${userIdParam}
        AND hm.access_tier = 'full_access'
    )
  )`;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object[]} petRows planned_absence_pets rows
 * @param {string} viewerUserId
 */
export async function filterPetRowsForAwayPlanViewer(pool, petRows, viewerUserId) {
  if (!petRows?.length) return [];
  const kept = [];
  for (const row of petRows) {
    if (await userCanManageProfile(pool, row.pet_id, viewerUserId)) {
      kept.push(row);
    }
  }
  return kept;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 */
export async function loadPlannedAbsenceRow(pool, absenceId) {
  const result = await pool.query(
    'SELECT * FROM planned_absences WHERE id = $1',
    [absenceId],
  );
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 * @param {string} viewerUserId
 * @returns {Promise<{ row: object, petRows: object[], isDeclarer: boolean, canEditTrip: boolean } | null>}
 */
export async function loadAbsenceForViewer(pool, absenceId, viewerUserId) {
  const row = await loadPlannedAbsenceRow(pool, absenceId);
  if (!row) return null;

  const isDeclarer = row.user_id === viewerUserId;
  const allPetRows = await pool.query(
    `SELECT pet_id, carer_kind, carer_user_id, carer_name, carer_note, pet_note, contact_id
     FROM planned_absence_pets
     WHERE planned_absence_id = $1
     ORDER BY pet_id`,
    [absenceId],
  );
  const enrichedNames = await enrichSharedUserCarerNames(pool, allPetRows.rows);
  const enriched = await enrichAbsencePetCarerContacts(pool, enrichedNames);

  const accessiblePetRows = await filterPetRowsForAwayPlanViewer(
    pool,
    enriched,
    viewerUserId,
  );

  if (isDeclarer || accessiblePetRows.length > 0) {
    return {
      row,
      petRows: accessiblePetRows,
      isDeclarer,
      canEditTrip: isDeclarer,
    };
  }
  return null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} viewerUserId
 * @param {string} declarerUserId
 */
export async function loadDeclarerDisplayName(pool, viewerUserId, declarerUserId) {
  if (!declarerUserId || declarerUserId === viewerUserId) return null;
  const snapshot = await fetchUserSnapshot(pool, declarerUserId);
  return snapshot?.display_name ?? null;
}

/**
 * Co-visible absences: declarer != viewer and viewer has Full access to a pet on the trip.
 *
 * @param {'upcoming'|'past'|'all'} scope
 * @param {string} todayIso
 */
export function coVisibleAbsencesListSql(scope, todayIso) {
  const profileSql = petProfileAccessSql('p', '$1');
  // DISTINCT pet joins can duplicate absence rows; select ids first so ORDER BY is valid.
  const visibleIds = `SELECT DISTINCT pa.id
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap ON pap.planned_absence_id = pa.id
     INNER JOIN pets p ON p.id = pap.pet_id
     WHERE pa.user_id != $1
       AND pa.status != $2
       AND ${profileSql}`;
  const base = `SELECT pa.*
     FROM planned_absences pa
     WHERE pa.id IN (${visibleIds})`;
  if (scope === 'upcoming') {
    return {
      sql: `${base}
         AND pa.ends_on >= $3::date
         ORDER BY pa.starts_on ASC`,
      params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
    };
  }
  if (scope === 'past') {
    return {
      sql: `${base}
         AND pa.ends_on < $3::date
         ORDER BY pa.starts_on DESC`,
      params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
    };
  }
  return {
    sql: `${base}
       ORDER BY (pa.ends_on < $3::date)::int,
                CASE WHEN pa.ends_on >= $3::date THEN pa.starts_on END ASC NULLS LAST,
                CASE WHEN pa.ends_on < $3::date THEN pa.starts_on END DESC NULLS LAST`,
    params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
  };
}
