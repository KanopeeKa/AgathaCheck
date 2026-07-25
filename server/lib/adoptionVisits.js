import { v4 as uuidv4 } from 'uuid';

import { logAuditEventSafe } from './audit.js';
import { dateToIsoDate } from './calendarDate.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
  normalizePlacementStatus,
} from './fosterPlacements.js';

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

export function visitToMap(row) {
  const visitOutcome = row.visit_outcome ?? row.outcome ?? null;
  return {
    id: row.id,
    organization_id: row.organization_id,
    prospect_id: row.prospect_id || null,
    fostering_session_id: row.fostering_session_id || null,
    pet_id: row.pet_id,
    scheduled_at: row.scheduled_at || null,
    status: row.status,
    visit_outcome: visitOutcome,
    outcome_notes: row.outcome_notes || '',
    assigned_foster_parent_id: row.assigned_foster_parent_id || null,
    created_by: row.created_by || null,
    created_at: row.created_at || null,
    updated_at: row.updated_at || null,
  };
}

export function normalizeVisitOutcomeInput(data) {
  return (data.visit_outcome || data.visitOutcome || data.outcome || '').trim();
}

export function validateCreateVisitPayload(data) {
  const prospectId = (data.prospect_id || data.prospectId || '').trim() || null;
  const fosteringSessionId = (data.fostering_session_id || data.fosteringSessionId || '').trim() || null;
  const petId = (data.pet_id || data.petId || '').trim();
  const scheduledAt = data.scheduled_at || data.scheduledAt;
  const assignedFosterParentId = (data.assigned_foster_parent_id || data.assignedFosterParentId || '').trim() || null;

  if (!petId) return { error: 'pet_id is required' };
  if (!scheduledAt) return { error: 'scheduled_at is required' };
  if (!prospectId && !fosteringSessionId) {
    return { error: 'prospect_id or fostering_session_id is required' };
  }

  return {
    prospectId,
    fosteringSessionId,
    petId,
    scheduledAt,
    assignedFosterParentId,
  };
}

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
    [
      id,
      orgId,
      prospectId,
      fosteringSessionId,
      petId,
      scheduledAt,
      assignedFosterParentId,
      createdBy || null,
    ],
  );

  logAuditEventSafe(pool, {
    actorUserId: createdBy,
    action: 'adoption_visit_scheduled',
    resourceType: ADOPTION_VISIT_RESOURCE,
    resourceId: id,
    orgId,
    petId,
    metadata: {
      prospect_id: prospectId,
      fostering_session_id: fosteringSessionId,
    },
    req: auditContext.req,
  });

  return { row: result.rows[0], status: 201 };
}

export async function recordVisitOutcome(pool, {
  orgId,
  visitId,
  visitOutcome,
  outcomeNotes = '',
  actorUserId,
  auditContext = {},
}) {
  if (!VALID_VISIT_OUTCOMES.has(visitOutcome)) {
    return { error: 'Invalid visit outcome', status: 400 };
  }

  const result = await pool.query(
    `UPDATE adoption_visits
     SET status = $1,
         visit_outcome = $2,
         outcome_notes = $3,
         updated_at = NOW()
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
    `SELECT id
     FROM adoption_visits
     WHERE fostering_session_id = $1
       AND status = $2
       AND visit_outcome = $3
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
    `SELECT *
     FROM adoption_visits
     WHERE id = $1 AND organization_id = $2`,
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
