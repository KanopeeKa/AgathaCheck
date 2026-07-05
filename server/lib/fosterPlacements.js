/**
 * Foster placement statuses and pet_access helpers for the fostering workflow.
 */
import { v4 as uuidv4 } from 'uuid';
import { dateToIsoDate } from './calendarDate.js';

export const PLACEMENT_STATUS_PENDING = 'pending';
export const PLACEMENT_STATUS_IN_PROGRESS = 'in_progress';
export const PLACEMENT_STATUS_NOT_IN_FOSTER = 'not_in_foster';
export const PLACEMENT_STATUS_WAITING_ADOPTION = 'waiting_adoption_confirmation';
export const PLACEMENT_STATUS_PENDING_CONDITIONS = 'pending_adoption_conditions';
export const PLACEMENT_STATUS_ADOPTED = 'adopted';

export const ACTIVE_PLACEMENT_STATUSES = [
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_IN_PROGRESS,
];

export const OPEN_PLACEMENT_STATUSES = [
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
];

export const ADOPTION_IN_PROGRESS_STATUSES = [
  PLACEMENT_STATUS_WAITING_ADOPTION,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
];

/** Pets physically with the foster (excludes pending acceptance invites). */
export const FOSTER_ACTIVE_STATUSES = [
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
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
    adoption_conditions: row.adoption_conditions || '',
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
       AND fp.status = ANY($2::text[])
     ORDER BY fp.created_at DESC
     LIMIT 1`,
    [petId, OPEN_PLACEMENT_STATUSES],
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

/**
 * Transfer org pet ownership to the foster parent and close the placement as adopted.
 * Caller must run inside a transaction when atomicity is required.
 */
export async function completeAdoptionTransfer(db, placement, pet) {
  const fosterUserId = placement.foster_user_id;
  const petId = placement.pet_id;

  await db.query(
    `UPDATE pets
     SET user_id = $1, organization_id = NULL, updated_at = NOW()
     WHERE id = $2`,
    [fosterUserId, petId],
  );

  await db.query(
    'DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2',
    [petId, fosterUserId],
  );

  const archiveId = uuidv4();
  await db.query(
    `INSERT INTO archived_pets (
       id, organization_id, user_id, pet_id, pet_name, species,
       transfer_type, transferred_to_user_id, notes
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
    [
      archiveId,
      placement.organization_id,
      pet.user_id,
      petId,
      pet.name,
      pet.species || '',
      'adoption',
      fosterUserId,
      placement.notes || '',
    ],
  );

  const updateResult = await db.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE(end_date, CURRENT_DATE),
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [PLACEMENT_STATUS_ADOPTED, placement.id],
  );

  return updateResult.rows[0];
}

/** Cancel an in-progress adoption and return the pet to org custody. */
export async function cancelAdoptionPlacement(db, placement, endDate = null) {
  const updateResult = await db.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE($2, CURRENT_DATE),
         adoption_conditions = '',
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [PLACEMENT_STATUS_NOT_IN_FOSTER, endDate, placement.id],
  );

  await revokeFosterPetAccess(db, placement.pet_id, placement.foster_user_id);
  return updateResult.rows[0];
}

/** End any open placement for a pet (foster period or adoption step). */
export async function closeActivePlacementForPet(pool, petId, endDate = null) {
  const active = await getActivePlacementForPet(pool, petId);
  if (!active) return null;

  if (active.status === PLACEMENT_STATUS_WAITING_ADOPTION
    || active.status === PLACEMENT_STATUS_PENDING_CONDITIONS) {
    return cancelAdoptionPlacement(pool, active, endDate);
  }

  if (active.status === PLACEMENT_STATUS_IN_PROGRESS) {
    await revokeFosterPetAccess(pool, petId, active.foster_user_id);
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE($2, CURRENT_DATE),
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [PLACEMENT_STATUS_NOT_IN_FOSTER, endDate, active.id],
  );
  return updateResult.rows[0];
}

export async function loadPlacementDetail(pool, placementId) {
  const result = await pool.query(
    `SELECT fp.*,
            p.name AS pet_name,
            p.species AS pet_species,
            o.name AS organization_name,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
            u.email AS foster_email
     FROM foster_placements fp
     JOIN pets p ON p.id = fp.pet_id
     JOIN organizations o ON o.id = fp.organization_id
     JOIN users u ON u.id = fp.foster_user_id
     WHERE fp.id = $1`,
    [placementId],
  );
  return result.rows[0] || null;
}
