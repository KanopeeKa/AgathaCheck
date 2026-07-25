/**
 * J5 Phase 1: adoption journey workflow (G0 §5.6, migration appendix §6).
 */
import { v4 as uuidv4 } from 'uuid';

import { logAuditEventSafe } from './audit.js';
import {
  assertVisitPathSatisfied,
  assertVisitScheduledToday,
  createAdoptionVisit,
  loadAdoptionVisitForOrg,
  recordVisitOutcome,
  VISIT_OUTCOME_POSITIVE,
  VISIT_STATUS_COMPLETED,
} from './adoptionVisits.js';
import {
  normalizePlacementStatus,
  placementToMap,
  revokeFosterPetAccess,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_CONVERTED_TO_ADOPTION,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
} from './fosterPlacements.js';
import {
  clearOrgPetHomeHiddenForPet,
  setOrgGuardianAndCare,
} from './petCustody.js';

export const ADOPTION_JOURNEY_RESOURCE = 'adoption_journey';
export const AUDIT_ADOPTION_JOURNEY_STARTED = 'adoption_journey_started';

export const JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION = 'awaiting_foster_confirmation';
export const JOURNEY_STATUS_PENDING_CONDITIONS = 'pending_conditions';
export const JOURNEY_STATUS_FINALISED = 'finalised';
export const JOURNEY_STATUS_CANCELLED = 'cancelled';

export const OPEN_JOURNEY_STATUSES = [
  JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION,
  JOURNEY_STATUS_PENDING_CONDITIONS,
];

const LEGACY_ADOPTION_STATUSES = new Set([
  'waiting_adoption_confirmation',
  'pending_adoption_conditions',
]);

export function journeyStatusFromConditions(adoptionConditions) {
  const conditions = (adoptionConditions || '').trim();
  return conditions
    ? JOURNEY_STATUS_PENDING_CONDITIONS
    : JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION;
}

export function journeyToMap(row) {
  return {
    id: row.id,
    organization_id: row.organization_id,
    fostering_session_id: row.fostering_session_id,
    pet_id: row.pet_id,
    foster_user_id: row.foster_user_id || null,
    status: row.status,
    adoption_conditions: row.adoption_conditions || '',
    started_at: row.started_at || null,
    finalised_at: row.finalised_at || null,
    cancelled_at: row.cancelled_at || null,
    created_by: row.created_by || null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export function auditAdoptionJourney(pool, event) {
  logAuditEventSafe(pool, {
    resourceType: ADOPTION_JOURNEY_RESOURCE,
    ...event,
  });
}

export async function getOpenJourneyForSession(db, fosteringSessionId) {
  const result = await db.query(
    `SELECT *
     FROM adoption_journeys
     WHERE fostering_session_id = $1
       AND status = ANY($2::text[])
     ORDER BY created_at DESC
     LIMIT 1`,
    [fosteringSessionId, OPEN_JOURNEY_STATUSES],
  );
  return result.rows[0] || null;
}

export async function getJourneyForSession(db, fosteringSessionId) {
  const result = await db.query(
    `SELECT *
     FROM adoption_journeys
     WHERE fostering_session_id = $1
     ORDER BY created_at DESC
     LIMIT 1`,
    [fosteringSessionId],
  );
  return result.rows[0] || null;
}

function deriveMigrationTargets(row) {
  const status = row.status;
  const conditions = (row.adoption_conditions || '').trim();

  if (status === 'waiting_adoption_confirmation') {
    return {
      sessionStatus: SESSION_STATUS_ADOPTION_IN_PROGRESS,
      journeyStatus: JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION,
      adoptionConditions: conditions,
      finalisedAt: null,
    };
  }
  if (status === 'pending_adoption_conditions') {
    return {
      sessionStatus: SESSION_STATUS_ADOPTION_IN_PROGRESS,
      journeyStatus: JOURNEY_STATUS_PENDING_CONDITIONS,
      adoptionConditions: conditions,
      finalisedAt: null,
    };
  }
  if (status === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
    return {
      sessionStatus: SESSION_STATUS_ADOPTION_IN_PROGRESS,
      journeyStatus: journeyStatusFromConditions(conditions),
      adoptionConditions: conditions,
      finalisedAt: null,
    };
  }
  if (status === SESSION_STATUS_CONVERTED_TO_ADOPTION || status === 'adopted') {
    return {
      sessionStatus: SESSION_STATUS_CONVERTED_TO_ADOPTION,
      journeyStatus: JOURNEY_STATUS_FINALISED,
      adoptionConditions: conditions,
      finalisedAt: row.updated_at || row.created_at,
    };
  }
  return null;
}

/**
 * J5 migration: create adoption_journeys table and backfill open adoption rows.
 */
export async function migrateAdoptionJourneys(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS adoption_journeys (
      id UUID PRIMARY KEY,
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      fostering_session_id UUID NOT NULL REFERENCES foster_placements(id) ON DELETE CASCADE,
      pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      foster_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      status VARCHAR(64) NOT NULL,
      adoption_conditions TEXT NOT NULL DEFAULT '',
      started_at TIMESTAMPTZ,
      finalised_at TIMESTAMPTZ,
      cancelled_at TIMESTAMPTZ,
      created_by UUID REFERENCES users(id) ON DELETE SET NULL,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW(),
      CONSTRAINT adoption_journeys_status_check
        CHECK (status IN (
          'awaiting_foster_confirmation',
          'pending_conditions',
          'finalised',
          'cancelled'
        ))
    )
  `);

  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_adoption_journeys_org_id
      ON adoption_journeys(organization_id)
  `);

  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_adoption_journeys_session_id
      ON adoption_journeys(fostering_session_id)
  `);

  await client.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_adoption_journeys_one_open_per_session
      ON adoption_journeys (fostering_session_id)
      WHERE status IN ('awaiting_foster_confirmation', 'pending_conditions')
  `);

  const { rows } = await client.query(
    `SELECT fp.id,
            fp.organization_id,
            fp.pet_id,
            fp.foster_user_id,
            fp.status,
            fp.adoption_conditions,
            fp.created_by,
            fp.created_at,
            fp.updated_at
     FROM foster_placements fp
     WHERE fp.status IN (
       'waiting_adoption_confirmation',
       'pending_adoption_conditions',
       'adoption_in_progress',
       'converted_to_adoption',
       'adopted'
     )
       AND NOT EXISTS (
         SELECT 1
         FROM adoption_journeys aj
         WHERE aj.fostering_session_id = fp.id
       )`,
  );

  for (const row of rows) {
    const targets = deriveMigrationTargets(row);
    if (!targets) continue;

    if (targets.sessionStatus !== row.status) {
      await client.query(
        `UPDATE foster_placements
         SET status = $1,
             adoption_conditions = $2,
             updated_at = NOW()
         WHERE id = $3`,
        [targets.sessionStatus, targets.adoptionConditions, row.id],
      );
    }

    const journeyId = uuidv4();
    await client.query(
      `INSERT INTO adoption_journeys (
         id, organization_id, fostering_session_id, pet_id, foster_user_id,
         status, adoption_conditions, started_at, finalised_at, created_by
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [
        journeyId,
        row.organization_id,
        row.id,
        row.pet_id,
        row.foster_user_id || null,
        targets.journeyStatus,
        targets.adoptionConditions,
        row.created_at,
        targets.finalisedAt,
        row.created_by || null,
      ],
    );
  }
}

export async function startAdoptionJourney(db, {
  placement,
  adoptionConditions = '',
  createdBy,
  auditContext = {},
}) {
  const sessionStatus = normalizePlacementStatus(placement.status);
  if (sessionStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
    return { error: 'Adoption journey already in progress for this session', status: 409 };
  }

  const existing = await getOpenJourneyForSession(db, placement.id);
  if (existing) {
    return { error: 'Adoption journey already in progress for this session', status: 409 };
  }

  const visitPathCheck = await assertVisitPathSatisfied(db, placement);
  if (visitPathCheck.error) {
    return visitPathCheck;
  }

  const conditions = (adoptionConditions || '').trim();
  const journeyStatus = journeyStatusFromConditions(conditions);
  const journeyId = uuidv4();

  const journeyResult = await db.query(
    `INSERT INTO adoption_journeys (
       id, organization_id, fostering_session_id, pet_id, foster_user_id,
       status, adoption_conditions, started_at, created_by
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), $8)
     RETURNING *`,
    [
      journeyId,
      placement.organization_id,
      placement.id,
      placement.pet_id,
      placement.foster_user_id || null,
      journeyStatus,
      conditions,
      createdBy || null,
    ],
  );

  const placementResult = await db.query(
    `UPDATE foster_placements
     SET status = $1,
         adoption_conditions = $2,
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [SESSION_STATUS_ADOPTION_IN_PROGRESS, conditions, placement.id],
  );

  auditAdoptionJourney(db, {
    actorUserId: createdBy,
    action: AUDIT_ADOPTION_JOURNEY_STARTED,
    resourceId: journeyId,
    orgId: placement.organization_id,
    petId: placement.pet_id,
    metadata: {
      fostering_session_id: placement.id,
      journey_status: journeyStatus,
    },
    req: auditContext.req,
  });

  return {
    journey: journeyResult.rows[0],
    placement: placementResult.rows[0],
    status: 200,
  };
}

export async function completeAdoptionJourneyConditions(db, placement) {
  const sessionStatus = normalizePlacementStatus(placement.status);
  const legacyPendingConditions = placement.status === 'pending_adoption_conditions';
  if (sessionStatus !== SESSION_STATUS_ADOPTION_IN_PROGRESS && !legacyPendingConditions) {
    return { error: 'Placement is not awaiting condition completion', status: 400 };
  }

  const journey = await getOpenJourneyForSession(db, placement.id);
  if (!journey || journey.status !== JOURNEY_STATUS_PENDING_CONDITIONS) {
    return { error: 'Adoption journey is not awaiting condition completion', status: 400 };
  }

  const journeyResult = await db.query(
    `UPDATE adoption_journeys
     SET status = $1,
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [JOURNEY_STATUS_AWAITING_FOSTER_CONFIRMATION, journey.id],
  );

  const placementResult = await db.query(
    `UPDATE foster_placements
     SET status = $1,
         adoption_conditions = '',
         updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [SESSION_STATUS_ADOPTION_IN_PROGRESS, placement.id],
  );

  return {
    journey: journeyResult.rows[0],
    placement: placementResult.rows[0],
    status: 200,
  };
}

export async function cancelAdoptionJourney(db, placement, endDate = null) {
  const sessionStatus = normalizePlacementStatus(placement.status);
  const legacyAdoption = LEGACY_ADOPTION_STATUSES.has(placement.status);
  if (sessionStatus !== SESSION_STATUS_ADOPTION_IN_PROGRESS && !legacyAdoption) {
    return { error: 'Placement is not in an adoption step', status: 400 };
  }

  const journey = await getOpenJourneyForSession(db, placement.id);
  if (journey) {
    await db.query(
      `UPDATE adoption_journeys
       SET status = $1,
           cancelled_at = NOW(),
           updated_at = NOW()
       WHERE id = $2`,
      [JOURNEY_STATUS_CANCELLED, journey.id],
    );
  }

  const placementResult = await db.query(
    `UPDATE foster_placements
     SET status = $1,
         end_date = COALESCE($2, CURRENT_DATE),
         adoption_conditions = '',
         updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    ['cancelled', endDate, placement.id],
  );

  if (placement.foster_user_id) {
    await revokeFosterPetAccess(db, placement.pet_id, placement.foster_user_id);
  }
  await setOrgGuardianAndCare(db, placement.pet_id, placement.organization_id);
  await clearOrgPetHomeHiddenForPet(db, placement.pet_id);

  return { placement: placementResult.rows[0], status: 200 };
}

export async function finaliseAdoptionJourney(db, placement) {
  const journey = await getOpenJourneyForSession(db, placement.id);
  if (journey) {
    await db.query(
      `UPDATE adoption_journeys
       SET status = $1,
           finalised_at = NOW(),
           updated_at = NOW()
       WHERE id = $2`,
      [JOURNEY_STATUS_FINALISED, journey.id],
    );
  }
  return journey;
}

export async function completeVisitAndStartAdoptionJourney(db, {
  placement,
  orgId,
  visitId,
  adoptionConditions = '',
  createdBy,
  auditContext = {},
}) {
  if (placement.session_type !== SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT) {
    return {
      error: 'Same-day expedite applies to foster-in-view-to-adopt sessions only',
      status: 400,
    };
  }

  let visitRow;
  if (visitId) {
    const loaded = await loadAdoptionVisitForOrg(db, visitId, orgId);
    if (loaded.error) return loaded;
    visitRow = loaded.row;
    if (visitRow.fostering_session_id !== placement.id) {
      return { error: 'Visit does not belong to this fostering session', status: 400 };
    }
    const dayCheck = assertVisitScheduledToday(visitRow);
    if (dayCheck.error) return dayCheck;
  } else {
    const created = await createAdoptionVisit(db, {
      orgId,
      fosteringSessionId: placement.id,
      petId: placement.pet_id,
      scheduledAt: new Date().toISOString(),
      createdBy,
      auditContext,
    });
    if (created.error) return created;
    visitRow = created.row;
  }

  if (visitRow.status !== VISIT_STATUS_COMPLETED
    || visitRow.visit_outcome !== VISIT_OUTCOME_POSITIVE) {
    const outcomeResult = await recordVisitOutcome(db, {
      orgId,
      visitId: visitRow.id,
      visitOutcome: VISIT_OUTCOME_POSITIVE,
      actorUserId: createdBy,
      auditContext,
    });
    if (outcomeResult.error) return outcomeResult;
  }

  return startAdoptionJourney(db, {
    placement,
    adoptionConditions,
    createdBy,
    auditContext,
  });
}

export function placementWithJourneyResponse(placement, journey, extras = {}) {
  const mapped = placementToMap(placement, extras);
  if (journey) {
    mapped.adoption_journey = journeyToMap(journey);
  }
  return mapped;
}
