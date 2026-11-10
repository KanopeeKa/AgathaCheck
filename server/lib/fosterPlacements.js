/**
 * Foster placement statuses and pet_access helpers for the fostering workflow.
 * J3 Phase 1: dual-write window — DB stores target session statuses; API exposes
 * legacy `status` alongside `session_status` for compatibility (appendix §4).
 */
import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from './audit.js';
import { dateToIsoDate } from './calendarDate.js';
import { applyIndividualGuardianshipTransfer } from './custodyTransfers.js';
import {
  clearOrgPetHomeHiddenForPet,
  setOrgGuardianAndCare,
} from './petCustody.js';

/** Legacy placement statuses (deprecated — use SESSION_STATUS_* for writes). */
export const PLACEMENT_STATUS_PENDING = 'pending';
export const PLACEMENT_STATUS_IN_PROGRESS = 'in_progress';
export const PLACEMENT_STATUS_NOT_IN_FOSTER = 'not_in_foster';
export const PLACEMENT_STATUS_WAITING_ADOPTION = 'waiting_adoption_confirmation';
export const PLACEMENT_STATUS_PENDING_CONDITIONS = 'pending_adoption_conditions';
export const PLACEMENT_STATUS_ADOPTED = 'adopted';

/** Target fostering session statuses (J3 / G0 §6.2). */
export const SESSION_STATUS_PENDING_ACCEPTANCE = 'pending_acceptance';
export const SESSION_STATUS_PREPARATION = 'preparation';
export const SESSION_STATUS_READY_TO_START = 'ready_to_start';
export const SESSION_STATUS_ACTIVE = 'active';
export const SESSION_STATUS_END_PENDING_CONFIRMATION = 'end_pending_confirmation';
export const SESSION_STATUS_ADOPTION_IN_PROGRESS = 'adoption_in_progress';
export const SESSION_STATUS_RETURNED_TO_SHELTER = 'returned_to_shelter';
export const SESSION_STATUS_TRANSFERRED = 'transferred';
export const SESSION_STATUS_CONVERTED_TO_ADOPTION = 'converted_to_adoption';
export const SESSION_STATUS_CANCELLED = 'cancelled';

export const SESSION_TYPE_STANDARD_FOSTER = 'standard_foster';
export const SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT = 'foster_in_view_to_adopt';

const LEGACY_TO_SESSION_STATUS = {
  [PLACEMENT_STATUS_PENDING]: SESSION_STATUS_PENDING_ACCEPTANCE,
  [PLACEMENT_STATUS_IN_PROGRESS]: SESSION_STATUS_ACTIVE,
  [PLACEMENT_STATUS_WAITING_ADOPTION]: SESSION_STATUS_ADOPTION_IN_PROGRESS,
  [PLACEMENT_STATUS_PENDING_CONDITIONS]: SESSION_STATUS_ADOPTION_IN_PROGRESS,
  [PLACEMENT_STATUS_ADOPTED]: SESSION_STATUS_CONVERTED_TO_ADOPTION,
  [PLACEMENT_STATUS_NOT_IN_FOSTER]: SESSION_STATUS_CANCELLED,
};

const SESSION_TO_LEGACY_STATUS = {
  [SESSION_STATUS_PENDING_ACCEPTANCE]: PLACEMENT_STATUS_PENDING,
  [SESSION_STATUS_PREPARATION]: PLACEMENT_STATUS_PENDING,
  [SESSION_STATUS_READY_TO_START]: PLACEMENT_STATUS_PENDING,
  [SESSION_STATUS_ACTIVE]: PLACEMENT_STATUS_IN_PROGRESS,
  [SESSION_STATUS_END_PENDING_CONFIRMATION]: PLACEMENT_STATUS_IN_PROGRESS,
  [SESSION_STATUS_ADOPTION_IN_PROGRESS]: PLACEMENT_STATUS_WAITING_ADOPTION,
  [SESSION_STATUS_RETURNED_TO_SHELTER]: PLACEMENT_STATUS_NOT_IN_FOSTER,
  [SESSION_STATUS_TRANSFERRED]: PLACEMENT_STATUS_NOT_IN_FOSTER,
  [SESSION_STATUS_CONVERTED_TO_ADOPTION]: PLACEMENT_STATUS_ADOPTED,
  [SESSION_STATUS_CANCELLED]: PLACEMENT_STATUS_NOT_IN_FOSTER,
};

const LEGACY_OPEN_STATUSES = [
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
];

const SESSION_OPEN_STATUSES = [
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
];

/** Map legacy or target status input to canonical session status for DB writes. */
export function normalizePlacementStatus(status) {
  if (!status) return status;
  return LEGACY_TO_SESSION_STATUS[status] || status;
}

/** Map session status to legacy API status for dual-write responses. */
export function toLegacyStatus(sessionStatus, row = {}) {
  if (!sessionStatus) return sessionStatus;
  if (sessionStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
    const conditions = row.adoption_conditions;
    if (conditions && String(conditions).trim()) {
      return PLACEMENT_STATUS_PENDING_CONDITIONS;
    }
    return PLACEMENT_STATUS_WAITING_ADOPTION;
  }
  return SESSION_TO_LEGACY_STATUS[sessionStatus] || sessionStatus;
}

export const ACTIVE_PLACEMENT_STATUSES = [
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_IN_PROGRESS,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
  SESSION_STATUS_ACTIVE,
];

export const OPEN_PLACEMENT_STATUSES = [
  ...LEGACY_OPEN_STATUSES,
  ...SESSION_OPEN_STATUSES,
];

export const ADOPTION_IN_PROGRESS_STATUSES = [
  PLACEMENT_STATUS_WAITING_ADOPTION,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
];

/** Pets physically with the foster (excludes pending acceptance invites). */
export const FOSTER_ACTIVE_STATUSES = [
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
];

export const FOSTER_PET_ACCESS_ROLE = 'foster';

/** DB statuses that appear in GET /foster-placements/pending (legacy + J3 pre-active). */
export const PENDING_FOSTER_ACCEPTANCE_STATUSES = [
  PLACEMENT_STATUS_PENDING,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
];

export function isPendingFosterAcceptance(status) {
  if (!status) return false;
  return PENDING_FOSTER_ACCEPTANCE_STATUSES.includes(status)
    || PENDING_FOSTER_ACCEPTANCE_STATUSES.includes(normalizePlacementStatus(status));
}

function sessionStatusFromRow(row) {
  return normalizePlacementStatus(row.status);
}

export function placementToMap(row, extras = {}) {
  const sessionStatus = sessionStatusFromRow(row);
  return {
    id: row.id,
    organization_id: row.organization_id,
    pet_id: row.pet_id,
    foster_user_id: row.foster_user_id,
    org_foster_parent_id: row.org_foster_parent_id || null,
    shelter_foster_relationship_id: row.shelter_foster_relationship_id
      || row.org_foster_parent_id
      || null,
    session_type: row.session_type || SESSION_TYPE_STANDARD_FOSTER,
    foster_request_response_id: row.foster_request_response_id || null,
    shelter_start_confirmed_at: row.shelter_start_confirmed_at || null,
    foster_start_confirmed_at: row.foster_start_confirmed_at || null,
    status: toLegacyStatus(sessionStatus, row),
    session_status: sessionStatus,
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
  await applyIndividualGuardianshipTransfer(db, {
    pet,
    fromOrgId: placement.organization_id,
    toUserId: placement.foster_user_id,
    actorUserId: placement.foster_user_id,
    notes: placement.notes,
  });

  const updateResult = await db.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE(end_date, CURRENT_DATE),
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [SESSION_STATUS_CONVERTED_TO_ADOPTION, placement.id],
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
    [SESSION_STATUS_CANCELLED, endDate, placement.id],
  );

  await revokeFosterPetAccess(db, placement.pet_id, placement.foster_user_id);
  await setOrgGuardianAndCare(db, placement.pet_id, placement.organization_id);
  await clearOrgPetHomeHiddenForPet(db, placement.pet_id);
  return updateResult.rows[0];
}

/** End any open placement for a pet (foster period or adoption step). */
export async function closeActivePlacementForPet(pool, petId, endDate = null) {
  const active = await getActivePlacementForPet(pool, petId);
  if (!active) return null;

  const sessionStatus = normalizePlacementStatus(active.status);

  if (sessionStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
    return cancelAdoptionPlacement(pool, active, endDate);
  }

  if (sessionStatus === SESSION_STATUS_ACTIVE) {
    await revokeFosterPetAccess(pool, petId, active.foster_user_id);
    await setOrgGuardianAndCare(pool, petId, active.organization_id);
    await clearOrgPetHomeHiddenForPet(pool, petId);
  }

  const updateResult = await pool.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE($2, CURRENT_DATE),
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [SESSION_STATUS_CANCELLED, endDate, active.id],
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
     LEFT JOIN users u ON u.id = fp.foster_user_id
     WHERE fp.id = $1`,
    [placementId],
  );
  return result.rows[0] || null;
}

export const ADOPTION_VISIT_RESOURCE = 'adoption_visit';
export const VISIT_STATUS_SCHEDULED = 'scheduled';
export const VISIT_STATUS_COMPLETED = 'completed';
export const VISIT_STATUS_CANCELLED = 'cancelled';
export const VISIT_OUTCOME_POSITIVE = 'positive';
export const VISIT_OUTCOME_NEGATIVE = 'negative';
export const VISIT_OUTCOME_NO_SHOW = 'no_show';

const VALID_VISIT_OUTCOMES = new Set([
  VISIT_OUTCOME_POSITIVE,
  VISIT_OUTCOME_NEGATIVE,
  VISIT_OUTCOME_NO_SHOW,
]);

export async function assertVisitSessionEligible(pool, fosteringSessionId, orgId) {
  if (!fosteringSessionId) return { ok: true };
  const result = await pool.query(
    `SELECT fp.id, fp.organization_id, fp.session_type, fp.status, fp.pet_id
     FROM foster_placements fp
     WHERE fp.id = $1 AND fp.organization_id = $2`,
    [fosteringSessionId, orgId],
  );
  if (result.rows.length === 0) {
    return { error: 'Fostering session not found', status: 404 };
  }
  const session = result.rows[0];
  const sessionStatus = normalizePlacementStatus(session.status);
  const eligibleType = session.session_type === SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT;
  const eligibleStatus = sessionStatus === SESSION_STATUS_ACTIVE;
  if (!eligibleType && !eligibleStatus) {
    return {
      error: 'Visits require an active foster-in-view-to-adopt session or active fostering session',
      status: 400,
    };
  }
  return { ok: true, session };
}

export async function createAdoptionVisit(pool, {
  orgId,
  prospectId,
  fosteringSessionId,
  petId,
  scheduledAt,
  assignedFosterParentId,
  createdBy,
  auditContext = {},
}) {
  const sessionCheck = await assertVisitSessionEligible(pool, fosteringSessionId, orgId);
  if (sessionCheck.error) return sessionCheck;
  const petResult = await pool.query(
    'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
    [petId, orgId],
  );
  if (petResult.rows.length === 0) {
    return { error: 'Pet not found', status: 404 };
  }
  if (prospectId) {
    const prospectResult = await pool.query(
      'SELECT id FROM prospects WHERE id = $1 AND organization_id = $2',
      [prospectId, orgId],
    );
    if (prospectResult.rows.length === 0) {
      return { error: 'Prospect not found', status: 404 };
    }
  }
  const id = uuidv4();
  const result = await pool.query(
    `INSERT INTO adoption_visits (
       id, organization_id, prospect_id, fostering_session_id, pet_id,
       scheduled_at, assigned_foster_parent_id, created_by
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [id, orgId, prospectId, fosteringSessionId, petId, scheduledAt, assignedFosterParentId, createdBy || null],
  );
  logAuditEventSafe(pool, {
    actorUserId: createdBy,
    action: 'adoption_visit_scheduled',
    resourceType: ADOPTION_VISIT_RESOURCE,
    resourceId: id,
    orgId,
    petId,
    metadata: { prospect_id: prospectId, fostering_session_id: fosteringSessionId },
    req: auditContext.req,
  });
  return { row: result.rows[0], status: 201 };
}

export async function recordVisitOutcome(pool, {
  orgId, visitId, visitOutcome, outcomeNotes = '', actorUserId, auditContext = {},
}) {
  if (!VALID_VISIT_OUTCOMES.has(visitOutcome)) {
    return { error: 'Invalid visit outcome', status: 400 };
  }
  const result = await pool.query(
    `UPDATE adoption_visits
     SET status = $1, visit_outcome = $2, outcome_notes = $3, updated_at = NOW()
     WHERE id = $4 AND organization_id = $5
     RETURNING *`,
    [VISIT_STATUS_COMPLETED, visitOutcome, outcomeNotes, visitId, orgId],
  );
  if (result.rows.length === 0) {
    return { error: 'Visit not found', status: 404 };
  }
  logAuditEventSafe(pool, {
    actorUserId,
    action: 'adoption_visit_outcome_recorded',
    resourceType: ADOPTION_VISIT_RESOURCE,
    resourceId: visitId,
    orgId,
    metadata: { visit_outcome: visitOutcome },
    req: auditContext.req,
  });
  return { row: result.rows[0], status: 200 };
}

export async function hasPositiveVisitForSession(pool, fosteringSessionId) {
  const result = await pool.query(
    `SELECT id FROM adoption_visits
     WHERE fostering_session_id = $1 AND status = $2 AND visit_outcome = $3
     LIMIT 1`,
    [fosteringSessionId, VISIT_STATUS_COMPLETED, VISIT_OUTCOME_POSITIVE],
  );
  return result.rows.length > 0;
}

export async function assertVisitPathSatisfied(db, placement) {
  if (placement.session_type !== SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT) {
    return { ok: true };
  }
  const satisfied = await hasPositiveVisitForSession(db, placement.id);
  if (!satisfied) {
    return {
      error: 'A completed adoption visit with positive outcome is required',
      code: 'visit_path_incomplete',
      status: 409,
    };
  }
  return { ok: true };
}

export async function loadAdoptionVisitForOrg(pool, visitId, orgId) {
  const result = await pool.query(
    `SELECT * FROM adoption_visits WHERE id = $1 AND organization_id = $2`,
    [visitId, orgId],
  );
  if (result.rows.length === 0) {
    return { error: 'Visit not found', status: 404 };
  }
  return { row: result.rows[0] };
}

export function assertVisitScheduledToday(visitRow) {
  const today = dateToIsoDate(new Date());
  const scheduledDay = dateToIsoDate(visitRow.scheduled_at);
  if (scheduledDay !== today) {
    return {
      error: 'Same-day expedite requires the visit to be scheduled for today',
      code: 'visit_not_same_day',
      status: 400,
    };
  }
  return { ok: true };
}
