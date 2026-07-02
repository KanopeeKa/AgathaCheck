/**
 * Foster placement statuses and pet_access helpers for the fostering workflow.
 */
import { v4 as uuidv4 } from 'uuid';
import { dateToIsoDate } from './calendarDate.js';

export const PLACEMENT_STATUS_PENDING = 'pending';
export const PLACEMENT_STATUS_IN_PROGRESS = 'in_progress';
export const PLACEMENT_STATUS_NOT_IN_FOSTER = 'not_in_foster';

export const ACTIVE_PLACEMENT_STATUSES = [
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_IN_PROGRESS,
];

export const FOSTER_PET_ACCESS_ROLE = 'foster';

export function placementToMap(row, extras = {}) {
  return {
    id: row.id,
    organization_id: row.organization_id,
    pet_id: row.pet_id,
    foster_user_id: row.foster_user_id,
    org_foster_parent_id: row.org_foster_parent_id || null,
    status: row.status,
    start_date: row.start_date ? dateToIsoDate(row.start_date) : null,
    end_date: row.end_date ? dateToIsoDate(row.end_date) : null,
    notes: row.notes || '',
    created_by: row.created_by || null,
    created_at: row.created_at,
    updated_at: row.updated_at,
    responded_at: row.responded_at || null,
    pet_name: extras.pet_name || row.pet_name || null,
    pet_species: extras.pet_species || row.pet_species || null,
    organization_name: extras.organization_name || row.organization_name || null,
    foster_name: extras.foster_name || row.foster_name || null,
    foster_email: extras.foster_email || row.foster_email || null,
  };
}

export async function getActivePlacementForPet(pool, petId) {
  const result = await pool.query(
    `SELECT fp.*
     FROM foster_placements fp
     WHERE fp.pet_id = $1
       AND fp.status IN ('pending', 'in_progress')
     ORDER BY fp.created_at DESC
     LIMIT 1`,
    [petId],
  );
  return result.rows[0] || null;
}

export async function grantFosterPetAccess(pool, petId, userId, invitedBy) {
  const accessId = uuidv4();
  await pool.query(
    `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by, hidden)
     VALUES ($1, $2, $3, $4, $5, false)
     ON CONFLICT (pet_id, user_id)
     DO UPDATE SET role = $4, hidden = false, invited_by = $5, updated_at = NOW()`,
    [accessId, petId, userId, FOSTER_PET_ACCESS_ROLE, invitedBy || null],
  );
}

export async function revokeFosterPetAccess(pool, petId, userId) {
  await pool.query(
    `DELETE FROM pet_access
     WHERE pet_id = $1 AND user_id = $2 AND role = $3`,
    [petId, userId, FOSTER_PET_ACCESS_ROLE],
  );
}
