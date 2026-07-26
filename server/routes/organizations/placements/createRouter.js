import { v4 as uuidv4 } from 'uuid';
import { normalizeCalendarDateInput } from '../../../lib/calendarDate.js';
import { createNotification, resolveAdministrativeNotifications, userDisplayName } from '../../../lib/notificationHelper.js';
import {
  NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
} from '../../../lib/notificationKind.js';
import {
  placementWithJourneyResponse,
  startAdoptionJourney,
} from '../../../lib/adoptionJourneys.js';
import {
  auditFosteringSession,
  AUDIT_FOSTERING_SESSION_CREATED,
  insertFosteringSession,
  lookupShelterFosterRelationshipId,
} from '../../../lib/fosterSessions.js';
import {
  getActivePlacementForPet,
  loadPlacementDetail,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_PENDING_ACCEPTANCE,
} from '../../../lib/fosterPlacements.js';
import { isFosterParentMember } from '../../../lib/orgRoles.js';
import { extractUserId, requireOrgAdmin } from '../shared.js';
import { publicError } from '../../../config/security.js';
import { queryPlacementDetailById } from './shared.js';

async function assertFosterParent(pool, orgId, fosterUserId, res) {
  const fosterMember = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, fosterUserId],
  );
  if (
    fosterMember.rows.length === 0
    || !isFosterParentMember(fosterMember.rows[0].role)
  ) {
    res.status(400).json({ error: 'Selected user is not a foster parent for this organization' });
    return false;
  }
  return true;
}

export function registerPlacementCreateRoutes(router, pool) {
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

      if (!(await assertFosterParent(pool, orgId, fosterUserId, res))) return;

      const existing = await getActivePlacementForPet(pool, petId);
      if (existing) {
        return res.status(409).json({ error: 'Pet already has an active foster placement' });
      }

      const id = uuidv4();
      const relationshipId = data.shelter_foster_relationship_id
        || data.shelterFosterRelationshipId
        || await lookupShelterFosterRelationshipId(pool, orgId, fosterUserId);

      const placement = await insertFosteringSession(pool, {
        id,
        orgId,
        petId,
        fosterUserId,
        status: SESSION_STATUS_PENDING_ACCEPTANCE,
        startDate,
        notes,
        createdBy: userId,
        shelterFosterRelationshipId: relationshipId,
        sessionType: data.session_type || data.sessionType,
        fosterRequestResponseId: data.foster_request_response_id || data.fosterRequestResponseId,
      });

      auditFosteringSession(pool, {
        actorUserId: userId,
        action: AUDIT_FOSTERING_SESSION_CREATED,
        resourceId: placement.id,
        orgId,
        petId,
        metadata: {
          session_status: SESSION_STATUS_PENDING_ACCEPTANCE,
          shelter_foster_relationship_id: relationshipId,
        },
        req,
      });

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
        type: NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
      });

      const detail = await queryPlacementDetailById(pool, placement.id);
      res.status(201).json(detail);
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

      if (!(await assertFosterParent(pool, orgId, fosterUserId, res))) return;

      const existing = await getActivePlacementForPet(pool, petId);
      if (existing) {
        return res.status(409).json({ error: 'Pet already has an active foster placement' });
      }

      const placementId = uuidv4();
      const relationshipId = data.shelter_foster_relationship_id
        || data.shelterFosterRelationshipId
        || await lookupShelterFosterRelationshipId(pool, orgId, fosterUserId);

      const placement = await insertFosteringSession(pool, {
        id: placementId,
        orgId,
        petId,
        fosterUserId,
        status: SESSION_STATUS_ACTIVE,
        notes,
        createdBy: userId,
        shelterFosterRelationshipId: relationshipId,
        sessionType: data.session_type || data.sessionType,
        adoptionConditions,
      });

      const journeyResult = await startAdoptionJourney(pool, {
        placement,
        adoptionConditions,
        createdBy: userId,
        auditContext: { req },
      });
      if (journeyResult.error) {
        return res.status(journeyResult.status).json({ error: journeyResult.error });
      }

      auditFosteringSession(pool, {
        actorUserId: userId,
        action: AUDIT_FOSTERING_SESSION_CREATED,
        resourceId: placement.id,
        orgId,
        petId,
        metadata: {
          session_status: SESSION_STATUS_ADOPTION_IN_PROGRESS,
          direct_adopt: true,
        },
        req,
      });

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
        type: NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
      });

      const detail = await loadPlacementDetail(pool, journeyResult.placement.id);
      res.status(201).json(placementWithJourneyResponse(
        detail || journeyResult.placement,
        journeyResult.journey,
      ));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
