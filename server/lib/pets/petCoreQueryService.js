/**
 * Read models for pet core HTTP routes: owned pets, aggregated home list, and single pet detail.
 */

import {
  userCanAccessPet,
  PET_ACCESS_ROLES,
  FOSTER_PET_ACCESS_ROLE,
} from '../../lib/petAccess.js';
import { orgPetViewerRolesSql } from '../../lib/orgRoles.js';
import { OPEN_PLACEMENT_STATUSES } from '../../lib/fosterPlacements.js';
import {
  autoAssignColors,
  FOSTER_PLACEMENT_SELECT_SQL,
  petRowToMap,
  PET_PARENT_NAME_SELECT_SQL,
} from './petPresentation.js';

export async function listAllAccessiblePets(pool, userId) {
  const result = await pool.query(
    `SELECT p.*, false AS is_shared, false AS is_foster, o.name AS organization_name,
            ${FOSTER_PLACEMENT_SELECT_SQL},
            ${PET_PARENT_NAME_SELECT_SQL},
            NULL::varchar AS access_role
     FROM pets p
     LEFT JOIN organizations o ON o.id = p.organization_id
     WHERE p.user_id = $1
       AND NOT EXISTS (
         SELECT 1 FROM org_pet_home_hidden oh
         WHERE oh.pet_id = p.id AND oh.user_id = $1
       )
     UNION ALL
     SELECT p.*, true AS is_shared, false AS is_foster, o.name AS organization_name,
            ${FOSTER_PLACEMENT_SELECT_SQL},
            ${PET_PARENT_NAME_SELECT_SQL},
            pa.role AS access_role
     FROM pets p
     JOIN pet_access pa ON pa.pet_id = p.id
     LEFT JOIN organizations o ON o.id = p.organization_id
     WHERE pa.user_id = $1 AND pa.role = ANY($2::text[]) AND COALESCE(pa.hidden, false) = false
     UNION ALL
     SELECT p.*, false AS is_shared, true AS is_foster, o.name AS organization_name,
            ${FOSTER_PLACEMENT_SELECT_SQL},
            ${PET_PARENT_NAME_SELECT_SQL},
            pa.role AS access_role
     FROM pets p
     JOIN pet_access pa ON pa.pet_id = p.id
     LEFT JOIN organizations o ON o.id = p.organization_id
     WHERE pa.user_id = $1 AND pa.role = $3 AND COALESCE(pa.hidden, false) = false
     UNION ALL
     SELECT p.*, false AS is_shared, false AS is_foster, o.name AS organization_name,
            ${FOSTER_PLACEMENT_SELECT_SQL},
            ${PET_PARENT_NAME_SELECT_SQL},
            NULL::varchar AS access_role
     FROM pets p
     JOIN organization_users ou ON ou.organization_id = p.organization_id
     LEFT JOIN organizations o ON o.id = p.organization_id
     WHERE ou.user_id = $1
       AND p.organization_id IS NOT NULL
       AND p.user_id <> $1
       AND ou.role IN (${orgPetViewerRolesSql()})
       AND NOT EXISTS (
         SELECT 1 FROM pet_access pa
         WHERE pa.pet_id = p.id AND pa.user_id = $1
           AND pa.role = ANY($2::text[]) AND COALESCE(pa.hidden, false) = false
       )
       AND NOT EXISTS (
         SELECT 1 FROM pet_access pa
         WHERE pa.pet_id = p.id AND pa.user_id = $1
           AND pa.role = $3 AND COALESCE(pa.hidden, false) = false
       )
       AND NOT EXISTS (
         SELECT 1 FROM org_pet_home_hidden oh
         WHERE oh.pet_id = p.id AND oh.user_id = $1
       )
     ORDER BY created_at`,
    [userId, PET_ACCESS_ROLES, FOSTER_PET_ACCESS_ROLE, OPEN_PLACEMENT_STATUSES],
  );
  const pets = result.rows.map(petRowToMap);
  await autoAssignColors(pool, pets);
  return pets;
}

export async function listOwnedPets(pool, userId) {
  const result = await pool.query(
    'SELECT * FROM pets WHERE user_id = $1 ORDER BY created_at',
    [userId],
  );
  const pets = result.rows.map(petRowToMap);
  await autoAssignColors(pool, pets);
  return pets;
}

export async function getPetDetailForUser(pool, userId, petId) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(petId)) {
    return { error: 'Invalid pet ID', status: 400 };
  }
  if (!(await userCanAccessPet(pool, petId, userId))) {
    return { error: 'Pet not found', status: 404 };
  }
  const result = await pool.query(
    `SELECT p.*, o.name AS organization_name,
            EXISTS (
              SELECT 1 FROM pet_access pa
              WHERE pa.pet_id = p.id AND pa.user_id = $2
                AND pa.role = ANY($4::text[])
                AND COALESCE(pa.hidden, false) = false
            ) AS is_shared,
            EXISTS (
              SELECT 1 FROM pet_access pa
              WHERE pa.pet_id = p.id AND pa.user_id = $2
                AND pa.role = $3
                AND COALESCE(pa.hidden, false) = false
            ) AS is_foster,
            (
              SELECT pa.role FROM pet_access pa
              WHERE pa.pet_id = p.id AND pa.user_id = $2
                AND COALESCE(pa.hidden, false) = false
              LIMIT 1
            ) AS access_role,
            ${PET_PARENT_NAME_SELECT_SQL}
     FROM pets p
     LEFT JOIN organizations o ON o.id = p.organization_id
     WHERE p.id = $1`,
    [petId, userId, FOSTER_PET_ACCESS_ROLE, PET_ACCESS_ROLES],
  );
  if (result.rows.length === 0) {
    return { error: 'Pet not found', status: 404 };
  }
  return { pet: petRowToMap(result.rows[0]) };
}
