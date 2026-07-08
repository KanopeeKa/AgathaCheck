/**
 * Guardianship and care helpers for org custody model.
 */

export const CARE_KIND_ORG = 'org';
export const CARE_KIND_USER = 'user';

export function guardianIsOrg(pet) {
  return pet.organization_id != null && String(pet.organization_id).length > 0;
}

export function guardianOrgId(pet) {
  return guardianIsOrg(pet) ? String(pet.organization_id) : null;
}

export function guardianUserId(pet) {
  return guardianIsOrg(pet) ? null : String(pet.user_id);
}

export async function setOrgGuardianAndCare(db, petId, orgId) {
  await db.query(
    `UPDATE pets SET
       organization_id = $1,
       care_holder_kind = $2,
       care_holder_org_id = $1,
       care_holder_user_id = NULL,
       updated_at = NOW()
     WHERE id = $3`,
    [orgId, CARE_KIND_ORG, petId],
  );
}

export async function setFosterCare(db, petId, fosterUserId, orgId) {
  await db.query(
    `UPDATE pets SET
       organization_id = $1,
       care_holder_kind = $2,
       care_holder_user_id = $3,
       care_holder_org_id = NULL,
       updated_at = NOW()
     WHERE id = $4`,
    [orgId, CARE_KIND_USER, fosterUserId, petId],
  );
}

export async function setIndividualGuardianAndCare(db, petId, userId) {
  await db.query(
    `UPDATE pets SET
       user_id = $1,
       organization_id = NULL,
       care_holder_kind = $2,
       care_holder_user_id = $1,
       care_holder_org_id = NULL,
       updated_at = NOW()
     WHERE id = $3`,
    [userId, CARE_KIND_USER, petId],
  );
}

export async function clearOrgPetHomeHiddenForPet(db, petId) {
  await db.query('DELETE FROM org_pet_home_hidden WHERE pet_id = $1', [petId]);
}

export async function petIsFosteredByOrg(db, petId, orgId) {
  const result = await db.query(
    `SELECT 1 FROM pets p
     WHERE p.id = $1 AND p.organization_id = $2
       AND p.care_holder_kind = $3
       AND p.care_holder_user_id IS NOT NULL
     LIMIT 1`,
    [petId, orgId, CARE_KIND_USER],
  );
  return result.rows.length > 0;
}

export async function userIsOrgAdmin(db, orgId, userId) {
  const result = await db.query(
    `SELECT 1 FROM organization_users
     WHERE organization_id = $1 AND user_id = $2
       AND role IN ('super_admin', 'admin')
     LIMIT 1`,
    [orgId, userId],
  );
  return result.rows.length > 0;
}
