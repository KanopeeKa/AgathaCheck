import { v4 as uuidv4 } from 'uuid';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import {
  cancelAdoptionPlacement,
  getActivePlacementForPet,
  loadPlacementDetail,
  placementToMap,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  revokeFosterPetAccess,
} from '../../lib/fosterPlacements.js';
import { isFosterParentMember } from '../../lib/orgRoles.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerPlacementsRoutes(router, pool) {
    router.get('/:orgId/placements', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
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
           WHERE fp.organization_id = $1
           ORDER BY fp.created_at DESC`,
          [orgId],
        );
        res.json(result.rows.map((row) => placementToMap(row)));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/pets/:petId/foster-history', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
        const petResult = await pool.query(
          'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
          [petId, orgId],
        );
        if (petResult.rows.length === 0) {
          return res.status(404).json({ error: 'Pet not found' });
        }
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
           WHERE fp.organization_id = $1 AND fp.pet_id = $2
           ORDER BY fp.created_at DESC`,
          [orgId, petId],
        );
        res.json(result.rows.map((row) => placementToMap(row)));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/pets/:petId/placement', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
        const petResult = await pool.query(
          'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
          [petId, orgId],
        );
        if (petResult.rows.length === 0) {
          return res.status(404).json({ error: 'Pet not found' });
        }
        const active = await getActivePlacementForPet(pool, petId);
        if (!active) {
          return res.json({ status: PLACEMENT_STATUS_NOT_IN_FOSTER, placement: null });
        }
        const detail = await pool.query(
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
          [active.id],
        );
        res.json({
          status: active.status,
          placement: placementToMap(detail.rows[0]),
        });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/pets/:petId/placements', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      const data = req.body || {};
      const fosterUserId = data.foster_user_id || data.fosterUserId;
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const notes = (data.notes || '').trim();

      if (!fosterUserId) {
        return res.status(400).json({ error: 'Foster parent user is required' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const petResult = await pool.query(
          'SELECT id, name FROM pets WHERE id = $1 AND organization_id = $2',
          [petId, orgId],
        );
        if (petResult.rows.length === 0) {
          return res.status(404).json({ error: 'Pet not found' });
        }
        const pet = petResult.rows[0];

        const fosterMember = await pool.query(
          'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
          [orgId, fosterUserId],
        );
        if (
          fosterMember.rows.length === 0
          || !isFosterParentMember(fosterMember.rows[0].role)
        ) {
          return res.status(400).json({ error: 'Selected user is not a foster parent for this organization' });
        }

        const existing = await getActivePlacementForPet(pool, petId);
        if (existing) {
          return res.status(409).json({ error: 'Pet already has an active foster placement' });
        }

        const id = uuidv4();
        const insertResult = await pool.query(
          `INSERT INTO foster_placements (
             id, organization_id, pet_id, foster_user_id, status, start_date, notes, created_by
           ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           RETURNING *`,
          [
            id,
            orgId,
            petId,
            fosterUserId,
            PLACEMENT_STATUS_PENDING,
            startDate,
            notes,
            userId,
          ],
        );
        const placement = insertResult.rows[0];

        const adminResult = await pool.query(
          'SELECT first_name, last_name, email FROM users WHERE id = $1',
          [userId],
        );
        const adminName = userDisplayName(adminResult.rows[0] || {});

        await createNotification(pool, {
          userId: fosterUserId,
          petId,
          petName: pet.name,
          title: 'Foster placement request',
          message: `${adminName} invited you to foster ${pet.name}.`,
          type: 'general',
        });

        const detail = await pool.query(
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
          [placement.id],
        );

        res.status(201).json(placementToMap(detail.rows[0]));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/placements/:id/end', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, id: placementId } = req.params;
      const data = req.body || {};
      const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const placementResult = await pool.query(
          'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
          [placementId, orgId],
        );
        if (placementResult.rows.length === 0) {
          return res.status(404).json({ error: 'Placement not found' });
        }
        const placement = placementResult.rows[0];
        if (![PLACEMENT_STATUS_PENDING, PLACEMENT_STATUS_IN_PROGRESS].includes(placement.status)) {
          return res.status(400).json({ error: 'Placement is not active' });
        }

        const petResult = await pool.query(
          'SELECT name FROM pets WHERE id = $1',
          [placement.pet_id],
        );
        const petName = petResult.rows[0]?.name || 'Pet';

        const updateResult = await pool.query(
          `UPDATE foster_placements
           SET status = $1,
               end_date = COALESCE($2, CURRENT_DATE),
               updated_at = NOW()
           WHERE id = $3
           RETURNING *`,
          [PLACEMENT_STATUS_NOT_IN_FOSTER, endDate, placementId],
        );

        if (placement.status === PLACEMENT_STATUS_IN_PROGRESS) {
          await revokeFosterPetAccess(pool, placement.pet_id, placement.foster_user_id);
        }

        await createNotification(pool, {
          userId: placement.foster_user_id,
          petId: placement.pet_id,
          petName,
          title: 'Foster period ended',
          message: `The foster period for ${petName} has ended.`,
          type: 'general',
        });

        res.json(placementToMap(updateResult.rows[0], { pet_name: petName }));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/placements/:id/start-adoption', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, id: placementId } = req.params;
      const data = req.body || {};
      const adoptionConditions = (data.adoption_conditions || data.adoptionConditions || '').trim();

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const placementResult = await pool.query(
          'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
          [placementId, orgId],
        );
        if (placementResult.rows.length === 0) {
          return res.status(404).json({ error: 'Placement not found' });
        }
        const placement = placementResult.rows[0];
        if (placement.status !== PLACEMENT_STATUS_IN_PROGRESS) {
          return res.status(400).json({ error: 'Placement must be in progress to start adoption' });
        }

        const nextStatus = adoptionConditions
          ? PLACEMENT_STATUS_PENDING_CONDITIONS
          : PLACEMENT_STATUS_WAITING_ADOPTION;

        const updateResult = await pool.query(
          `UPDATE foster_placements
           SET status = $1,
               adoption_conditions = $2,
               updated_at = NOW()
           WHERE id = $3
           RETURNING *`,
          [nextStatus, adoptionConditions, placementId],
        );

        const petResult = await pool.query(
          'SELECT name FROM pets WHERE id = $1',
          [placement.pet_id],
        );
        const petName = petResult.rows[0]?.name || 'Pet';

        await createNotification(pool, {
          userId: placement.foster_user_id,
          petId: placement.pet_id,
          petName,
          title: 'Adoption ready to confirm',
          message: adoptionConditions
            ? `${petName} is ready for adoption once pre-adoption conditions are met.`
            : `Please confirm adoption of ${petName}.`,
          type: 'general',
        });

        const detail = await loadPlacementDetail(pool, placementId);
        res.json(placementToMap(detail || updateResult.rows[0]));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/placements/:id/complete-conditions', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, id: placementId } = req.params;

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const placementResult = await pool.query(
          'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
          [placementId, orgId],
        );
        if (placementResult.rows.length === 0) {
          return res.status(404).json({ error: 'Placement not found' });
        }
        const placement = placementResult.rows[0];
        if (placement.status !== PLACEMENT_STATUS_PENDING_CONDITIONS) {
          return res.status(400).json({ error: 'Placement is not awaiting condition completion' });
        }

        const updateResult = await pool.query(
          `UPDATE foster_placements
           SET status = $1, updated_at = NOW()
           WHERE id = $2
           RETURNING *`,
          [PLACEMENT_STATUS_WAITING_ADOPTION, placementId],
        );

        const petResult = await pool.query(
          'SELECT name FROM pets WHERE id = $1',
          [placement.pet_id],
        );
        const petName = petResult.rows[0]?.name || 'Pet';

        await createNotification(pool, {
          userId: placement.foster_user_id,
          petId: placement.pet_id,
          petName,
          title: 'Adoption ready to confirm',
          message: `Pre-adoption conditions for ${petName} are complete. Please confirm adoption.`,
          type: 'general',
        });

        const detail = await loadPlacementDetail(pool, placementId);
        res.json(placementToMap(detail || updateResult.rows[0]));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/placements/:id/cancel-adoption', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, id: placementId } = req.params;
      const data = req.body || {};
      const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const placementResult = await pool.query(
          'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
          [placementId, orgId],
        );
        if (placementResult.rows.length === 0) {
          return res.status(404).json({ error: 'Placement not found' });
        }
        const placement = placementResult.rows[0];
        if (![PLACEMENT_STATUS_WAITING_ADOPTION, PLACEMENT_STATUS_PENDING_CONDITIONS].includes(placement.status)) {
          return res.status(400).json({ error: 'Placement is not in an adoption step' });
        }

        const petResult = await pool.query(
          'SELECT name FROM pets WHERE id = $1',
          [placement.pet_id],
        );
        const petName = petResult.rows[0]?.name || 'Pet';

        const updated = await cancelAdoptionPlacement(pool, placement, endDate);

        await createNotification(pool, {
          userId: placement.foster_user_id,
          petId: placement.pet_id,
          petName,
          title: 'Adoption cancelled',
          message: `The adoption process for ${petName} was cancelled. The pet returns to organisation custody.`,
          type: 'general',
        });

        const detail = await loadPlacementDetail(pool, placementId);
        res.json(placementToMap(detail || updated, { pet_name: petName }));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/pets/:petId/placements/direct-adopt', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, petId } = req.params;
      const data = req.body || {};
      const fosterUserId = data.foster_user_id || data.fosterUserId;
      const adoptionConditions = (data.adoption_conditions || data.adoptionConditions || '').trim();
      const notes = (data.notes || '').trim();

      if (!fosterUserId) {
        return res.status(400).json({ error: 'Foster parent user is required' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const petResult = await pool.query(
          'SELECT id, name FROM pets WHERE id = $1 AND organization_id = $2',
          [petId, orgId],
        );
        if (petResult.rows.length === 0) {
          return res.status(404).json({ error: 'Pet not found' });
        }
        const pet = petResult.rows[0];

        const fosterMember = await pool.query(
          'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
          [orgId, fosterUserId],
        );
        if (
          fosterMember.rows.length === 0
          || !isFosterParentMember(fosterMember.rows[0].role)
        ) {
          return res.status(400).json({ error: 'Selected user is not a foster parent for this organization' });
        }

        const existing = await getActivePlacementForPet(pool, petId);
        if (existing) {
          return res.status(409).json({ error: 'Pet already has an active foster placement' });
        }

        const placementId = uuidv4();
        const nextStatus = adoptionConditions
          ? PLACEMENT_STATUS_PENDING_CONDITIONS
          : PLACEMENT_STATUS_WAITING_ADOPTION;

        const insertResult = await pool.query(
          `INSERT INTO foster_placements (
             id, organization_id, pet_id, foster_user_id, status, notes,
             adoption_conditions, created_by
           ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           RETURNING *`,
          [
            placementId,
            orgId,
            petId,
            fosterUserId,
            nextStatus,
            notes,
            adoptionConditions,
            userId,
          ],
        );

        const adminResult = await pool.query(
          'SELECT first_name, last_name, email FROM users WHERE id = $1',
          [userId],
        );
        const adminName = userDisplayName(adminResult.rows[0] || {});

        await createNotification(pool, {
          userId: fosterUserId,
          petId,
          petName: pet.name,
          title: 'Adoption ready to confirm',
          message: adoptionConditions
            ? `${adminName} invited you to adopt ${pet.name}. Pre-adoption conditions apply.`
            : `${adminName} invited you to adopt ${pet.name}. Please confirm to complete adoption.`,
          type: 'general',
        });

        const detail = await loadPlacementDetail(pool, insertResult.rows[0].id);
        res.status(201).json(placementToMap(detail || insertResult.rows[0]));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });
}
