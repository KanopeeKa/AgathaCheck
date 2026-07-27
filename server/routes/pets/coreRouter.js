import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import {
  userCanAccessPet,
  userCanManagePet,
  userOwnsPet,
  COLLABORATOR_ROLES,
  FOSTER_PET_ACCESS_ROLE,
} from '../../lib/petAccess.js';
import { orgPetViewerRolesSql } from '../../lib/orgRoles.js';
import { OPEN_PLACEMENT_STATUSES } from '../../lib/fosterPlacements.js';
import {
  autoAssignColors,
  extractUserId,
  FOSTER_PLACEMENT_SELECT_SQL,
  petRowToMap,
  userInOrg,
  GUARDIAN_NAME_SELECT_SQL,
} from './shared.js';

export function registerCoreRoutes(router, pool) {
  router.get('/all', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT p.*, false AS is_shared, false AS is_foster, o.name AS organization_name,
                ${FOSTER_PLACEMENT_SELECT_SQL},
                ${GUARDIAN_NAME_SELECT_SQL}
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
                ${GUARDIAN_NAME_SELECT_SQL}
         FROM pets p
         JOIN pet_access pa ON pa.pet_id = p.id
         LEFT JOIN organizations o ON o.id = p.organization_id
         WHERE pa.user_id = $1 AND pa.role = ANY($2::text[]) AND COALESCE(pa.hidden, false) = false
         UNION ALL
         SELECT p.*, false AS is_shared, true AS is_foster, o.name AS organization_name,
                ${FOSTER_PLACEMENT_SELECT_SQL},
                ${GUARDIAN_NAME_SELECT_SQL}
         FROM pets p
         JOIN pet_access pa ON pa.pet_id = p.id
         LEFT JOIN organizations o ON o.id = p.organization_id
         WHERE pa.user_id = $1 AND pa.role = $3 AND COALESCE(pa.hidden, false) = false
         UNION ALL
         SELECT p.*, false AS is_shared, false AS is_foster, o.name AS organization_name,
                ${FOSTER_PLACEMENT_SELECT_SQL},
                ${GUARDIAN_NAME_SELECT_SQL}
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
        [userId, COLLABORATOR_ROLES, FOSTER_PET_ACCESS_ROLE, OPEN_PLACEMENT_STATUSES]
      );
      const pets = result.rows.map(petRowToMap);
      await autoAssignColors(pool, pets);
      res.json(pets);
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pets', `Error fetching pets: ${err.message}`) });
    }
  });

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT * FROM pets WHERE user_id = $1 ORDER BY created_at',
        [userId]
      );
      const pets = result.rows.map(petRowToMap);
      await autoAssignColors(pool, pets);
      res.json(pets);
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pets', `Error fetching pets: ${err.message}`) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({ error: 'Invalid pet ID' });
    }
    try {
      if (!(await userCanAccessPet(pool, id, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const result = await pool.query(
        `SELECT p.*, o.name AS organization_name,
                EXISTS (
                  SELECT 1 FROM pet_access pa
                  WHERE pa.pet_id = p.id AND pa.user_id = $2
                    AND pa.role IN ('shared', 'guardian')
                    AND COALESCE(pa.hidden, false) = false
                ) AS is_shared,
                EXISTS (
                  SELECT 1 FROM pet_access pa
                  WHERE pa.pet_id = p.id AND pa.user_id = $2
                    AND pa.role = $3
                    AND COALESCE(pa.hidden, false) = false
                ) AS is_foster
         FROM pets p
         LEFT JOIN organizations o ON o.id = p.organization_id
         WHERE p.id = $1`,
        [id, userId, FOSTER_PET_ACCESS_ROLE]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      res.json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pet', `Error fetching pet: ${err.message}`) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const id = req.body.id || uuidv4();
      const {
        name, species, breed = '', age, weight, gender,
        bio = '', insurance = '',
        neuterDismissed = false, chipId = '', chipDismissed = false,
        photoPath, vetId, colorValue, passedAway = false,
        organization_id
      } = req.body;
      const dateOfBirth = normalizeCalendarDateInput(req.body.dateOfBirth || req.body.date_of_birth);
      const neuteredDate = normalizeCalendarDateInput(req.body.neuteredDate);
      if (organization_id && !(await userInOrg(pool, organization_id, userId))) {
        return res.status(403).json({ error: 'Not a member of this organization' });
      }
      const result = await pool.query(
        `INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender,
          bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed,
          photo_path, vet_id, color_index, passed_away, organization_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
         ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, species = EXCLUDED.species, breed = EXCLUDED.breed,
          age = EXCLUDED.age, date_of_birth = EXCLUDED.date_of_birth, weight = EXCLUDED.weight, gender = EXCLUDED.gender,
          bio = EXCLUDED.bio, insurance = EXCLUDED.insurance, neutered_date = EXCLUDED.neutered_date,
          neuter_dismissed = EXCLUDED.neuter_dismissed, chip_id = EXCLUDED.chip_id, chip_dismissed = EXCLUDED.chip_dismissed,
          photo_path = EXCLUDED.photo_path, vet_id = EXCLUDED.vet_id, color_index = EXCLUDED.color_index,
          passed_away = EXCLUDED.passed_away, organization_id = EXCLUDED.organization_id, updated_at = NOW()
         WHERE pets.user_id = $2 RETURNING *`,
        [id, userId, name, species, breed, age, dateOfBirth, weight, gender,
         bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
         photoPath || null, vetId || null, colorValue != null ? colorValue : null,
         passedAway, organization_id || null]
      );
      const pet = result.rows[0];
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'pet.created',
        resourceType: 'pet',
        resourceId: pet.id,
        petId: pet.id,
        orgId: pet.organization_id || null,
        metadata: { species: pet.species },
        req,
      });
      res.status(201).json(petRowToMap(pet));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error creating pet', `Error creating pet: ${err.message}`) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { id } = req.params;
      if (!(await userCanManagePet(pool, id, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const {
        name, species, breed = '', age, weight, gender,
        bio = '', insurance = '',
        neuterDismissed = false, chipId = '', chipDismissed = false,
        photoPath, vetId, colorValue, passedAway = false,
        organization_id
      } = req.body;
      const dateOfBirth = normalizeCalendarDateInput(req.body.dateOfBirth || req.body.date_of_birth);
      const neuteredDate = normalizeCalendarDateInput(req.body.neuteredDate);
      const existingPet = await pool.query(
        'SELECT organization_id FROM pets WHERE id = $1',
        [id]
      );
      const previousOrgId = existingPet.rows[0]?.organization_id || null;
      const nextOrgId = organization_id || null;
      if (nextOrgId && String(nextOrgId) !== String(previousOrgId || '')
          && !(await userInOrg(pool, nextOrgId, userId))) {
        return res.status(403).json({ error: 'Not a member of this organization' });
      }
      const result = await pool.query(
        `UPDATE pets SET name=$1, species=$2, breed=$3, age=$4, date_of_birth=$5, weight=$6, gender=$7,
          bio=$8, insurance=$9, neutered_date=$10, neuter_dismissed=$11, chip_id=$12, chip_dismissed=$13,
          photo_path=$14, vet_id=$15, color_index=$16, passed_away=$17, organization_id=$18,
          updated_at=NOW()
         WHERE id=$19 RETURNING *`,
        [name, species, breed, age, dateOfBirth, weight, gender,
         bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
         photoPath || null, vetId || null, colorValue != null ? colorValue : null,
         passedAway, organization_id || null, id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = result.rows[0];
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'pet.updated',
        resourceType: 'pet',
        resourceId: id,
        petId: id,
        orgId: pet.organization_id || null,
        req,
      });
      res.json(petRowToMap(pet));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error updating pet', `Error updating pet: ${err.message}`) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { id } = req.params;
      if (!(await userOwnsPet(pool, id, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'pet.deleted',
        resourceType: 'pet',
        resourceId: id,
        petId: id,
        req,
      });
      await pool.query('DELETE FROM pets WHERE id = $1 AND user_id = $2', [id, userId]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error deleting pet', `Error deleting pet: ${err.message}`) });
    }
  });
}
