/**
 * J3 Phase 2: fostering session lifecycle transitions and audit events (G0 §5.4, §6).
 */
import { logAuditEventSafe } from './audit.js';
import { recordFosterSessionActivity } from './petActivity.js';
import {
  grantFosterPetAccess,
  normalizePlacementStatus,
  revokeFosterPetAccess,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
  SESSION_STATUS_RETURNED_TO_SHELTER,
  SESSION_TYPE_STANDARD_FOSTER,
} from './fosterPlacements.js';
import {
  clearOrgPetHomeHiddenForPet,
  setFosterCare,
  setOrgGuardianAndCare,
} from './petCustody.js';

export const FOSTERING_SESSION_RESOURCE = 'fostering_session';

export const AUDIT_FOSTERING_SESSION_CREATED = 'fostering_session_created';
export const AUDIT_SESSION_START_CONFIRMED_SHELTER = 'session_start_confirmed_shelter';
export const AUDIT_SESSION_START_CONFIRMED_FOSTER = 'session_start_confirmed_foster';
export const AUDIT_SESSION_RETURN_CONFIRMED = 'session_return_confirmed';

const TRANSITION_RULES = {
  [SESSION_STATUS_PREPARATION]: [SESSION_STATUS_PENDING_ACCEPTANCE],
  [SESSION_STATUS_READY_TO_START]: [SESSION_STATUS_PREPARATION],
};

const END_OUTCOMES = new Set([
  SESSION_STATUS_RETURNED_TO_SHELTER,
  SESSION_STATUS_CANCELLED,
]);

export function sessionStatusFromPlacement(placement) {
  return normalizePlacementStatus(placement?.status);
}

export function validateSessionTransition(currentStatus, targetStatus) {
  const allowedFrom = TRANSITION_RULES[targetStatus];
  if (!allowedFrom) {
    return `Invalid transition target: ${targetStatus}`;
  }
  if (!allowedFrom.includes(currentStatus)) {
    return `Cannot transition from ${currentStatus} to ${targetStatus}`;
  }
  return null;
}

export async function lookupShelterFosterRelationshipId(pool, orgId, fosterUserId) {
  if (!fosterUserId) return null;
  const result = await pool.query(
    `SELECT id
     FROM org_foster_parents
     WHERE organization_id = $1
       AND user_id = $2
     ORDER BY created_at DESC
     LIMIT 1`,
    [orgId, fosterUserId],
  );
  return result.rows[0]?.id || null;
}

export function auditFosteringSession(pool, event) {
  logAuditEventSafe(pool, {
    resourceType: FOSTERING_SESSION_RESOURCE,
    ...event,
  });
}

export async function transitionSessionStatus(pool, placement, targetStatus, auditContext = {}) {
  const currentStatus = sessionStatusFromPlacement(placement);
  const validationError = validateSessionTransition(currentStatus, targetStatus);
  if (validationError) {
    return { error: validationError, status: 400 };
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET status = $1,
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [targetStatus, placement.id],
  );

  recordFosterSessionActivity(pool, updateResult.rows[0], auditContext.actorUserId, {
    mutation: 'transition',
    session_status: targetStatus,
  });

  return { row: updateResult.rows[0], status: 200 };
}

export async function activateSessionIfReady(pool, placement) {
  const currentStatus = sessionStatusFromPlacement(placement);
  if (currentStatus !== SESSION_STATUS_READY_TO_START) {
    return placement;
  }
  if (!placement.shelter_start_confirmed_at || !placement.foster_start_confirmed_at) {
    return placement;
  }
  if (!placement.foster_user_id) {
    return placement;
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET status = $1,
         start_date = COALESCE(start_date, CURRENT_DATE),
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [SESSION_STATUS_ACTIVE, placement.id],
  );
  const activated = updateResult.rows[0];

  await grantFosterPetAccess(
    pool,
    placement.pet_id,
    placement.foster_user_id,
    placement.created_by,
  );
  await setFosterCare(
    pool,
    placement.pet_id,
    placement.foster_user_id,
    placement.organization_id,
  );

  recordFosterSessionActivity(pool, activated, placement.created_by, {
    mutation: 'activated',
    session_status: SESSION_STATUS_ACTIVE,
  });

  return activated;
}

export async function confirmShelterSessionStart(pool, placement, auditContext = {}) {
  const currentStatus = sessionStatusFromPlacement(placement);
  if (currentStatus !== SESSION_STATUS_READY_TO_START) {
    return { error: 'Session must be ready to start before shelter confirmation', status: 400 };
  }
  if (placement.shelter_start_confirmed_at) {
    return { error: 'Shelter start already confirmed', status: 400 };
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET shelter_start_confirmed_at = NOW(),
         updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [placement.id],
  );
  let updated = updateResult.rows[0];

  auditFosteringSession(pool, {
    actorUserId: auditContext.actorUserId,
    action: AUDIT_SESSION_START_CONFIRMED_SHELTER,
    resourceId: placement.id,
    orgId: placement.organization_id,
    petId: placement.pet_id,
    req: auditContext.req,
  });

  updated = await activateSessionIfReady(pool, updated);
  recordFosterSessionActivity(pool, updated, auditContext.actorUserId, {
    mutation: 'shelter_start_confirmed',
    session_status: sessionStatusFromPlacement(updated),
  });
  return { row: updated, status: 200 };
}

export async function confirmFosterSessionStart(pool, placement, fosterUserId, auditContext = {}) {
  const currentStatus = sessionStatusFromPlacement(placement);
  if (currentStatus !== SESSION_STATUS_READY_TO_START) {
    return { error: 'Session must be ready to start before foster confirmation', status: 400 };
  }
  if (placement.foster_user_id !== fosterUserId) {
    return { error: 'Forbidden', status: 403 };
  }
  if (placement.foster_start_confirmed_at) {
    return { error: 'Foster start already confirmed', status: 400 };
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET foster_start_confirmed_at = NOW(),
         updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [placement.id],
  );
  let updated = updateResult.rows[0];

  auditFosteringSession(pool, {
    actorUserId: fosterUserId,
    action: AUDIT_SESSION_START_CONFIRMED_FOSTER,
    resourceId: placement.id,
    orgId: placement.organization_id,
    petId: placement.pet_id,
    req: auditContext.req,
  });

  updated = await activateSessionIfReady(pool, updated);
  recordFosterSessionActivity(pool, updated, fosterUserId, {
    mutation: 'foster_start_confirmed',
    session_status: sessionStatusFromPlacement(updated),
  });
  return { row: updated, status: 200 };
}

export async function requestSessionEnd(pool, placement) {
  const currentStatus = sessionStatusFromPlacement(placement);
  if (currentStatus !== SESSION_STATUS_ACTIVE) {
    return { error: 'Only active sessions can be marked for end confirmation', status: 400 };
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET status = $1,
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [SESSION_STATUS_END_PENDING_CONFIRMATION, placement.id],
  );

  recordFosterSessionActivity(pool, updateResult.rows[0], null, {
    mutation: 'end_requested',
    session_status: SESSION_STATUS_END_PENDING_CONFIRMATION,
  });

  return { row: updateResult.rows[0], status: 200 };
}

export async function completeSessionEnd(pool, placement, outcome, endDate, auditContext = {}) {
  const currentStatus = sessionStatusFromPlacement(placement);
  if (currentStatus !== SESSION_STATUS_END_PENDING_CONFIRMATION) {
    return { error: 'Session is not awaiting end confirmation', status: 400 };
  }
  if (!END_OUTCOMES.has(outcome)) {
    return { error: 'Outcome must be returned_to_shelter or cancelled', status: 400 };
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE($2, CURRENT_DATE),
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [outcome, endDate, placement.id],
  );
  const updated = updateResult.rows[0];

  if (placement.foster_user_id) {
    await revokeFosterPetAccess(pool, placement.pet_id, placement.foster_user_id);
  }
  await setOrgGuardianAndCare(pool, placement.pet_id, placement.organization_id);
  await clearOrgPetHomeHiddenForPet(pool, placement.pet_id);

  if (outcome === SESSION_STATUS_RETURNED_TO_SHELTER) {
    auditFosteringSession(pool, {
      actorUserId: auditContext.actorUserId,
      action: AUDIT_SESSION_RETURN_CONFIRMED,
      resourceId: placement.id,
      orgId: placement.organization_id,
      petId: placement.pet_id,
      metadata: { outcome },
      req: auditContext.req,
    });
  }

  recordFosterSessionActivity(pool, updated, auditContext.actorUserId, {
    mutation: 'end_completed',
    session_status: outcome,
    outcome,
  });

  return { row: updated, status: 200 };
}

export async function insertFosteringSession(pool, {
  id,
  orgId,
  petId,
  fosterUserId,
  status,
  startDate,
  notes,
  createdBy,
  shelterFosterRelationshipId,
  sessionType,
  fosterRequestResponseId,
  adoptionConditions,
}) {
  const insertResult = await pool.query(
    `INSERT INTO foster_placements (
       id, organization_id, pet_id, foster_user_id, status, start_date, notes,
       created_by, shelter_foster_relationship_id, org_foster_parent_id,
       session_type, foster_request_response_id, adoption_conditions
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9, $10, $11, $12)
     RETURNING *`,
    [
      id,
      orgId,
      petId,
      fosterUserId || null,
      status,
      startDate,
      notes,
      createdBy,
      shelterFosterRelationshipId,
      sessionType || SESSION_TYPE_STANDARD_FOSTER,
      fosterRequestResponseId || null,
      adoptionConditions || '',
    ],
  );
  const inserted = insertResult.rows[0];
  recordFosterSessionActivity(pool, inserted, createdBy, {
    mutation: 'created',
    session_status: status,
  });
  return inserted;
}
