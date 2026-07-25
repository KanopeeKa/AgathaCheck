import {
  assertVisitPathSatisfied,
  hasPositiveVisitForSession,
  recordVisitOutcome,
  VISIT_OUTCOME_NEGATIVE,
  VISIT_OUTCOME_POSITIVE,
  VISIT_STATUS_COMPLETED,
} from '../lib/adoptionVisits.js';
import { startAdoptionJourney } from '../lib/adoptionJourneys.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
} from '../lib/fosterPlacements.js';

const orgId = 'org-1';
const placementId = 'placement-1';
const visitId = 'visit-1';

function buildVisitPool({ visits = [] } = {}) {
  const visitRows = [...visits];
  return {
    async query(sql, params) {
      if (sql.includes('FROM adoption_visits') && sql.includes('visit_outcome')) {
        const sessionId = params[0];
        const positive = visitRows.some(
          (row) => row.fostering_session_id === sessionId
            && row.status === VISIT_STATUS_COMPLETED
            && row.visit_outcome === VISIT_OUTCOME_POSITIVE,
        );
        return { rows: positive ? [{ id: visitId }] : [] };
      }
      if (sql.includes('UPDATE adoption_visits') && sql.includes('visit_outcome')) {
        const idx = visitRows.findIndex((row) => row.id === params[3]);
        if (idx === -1) return { rows: [] };
        visitRows[idx] = {
          ...visitRows[idx],
          status: VISIT_STATUS_COMPLETED,
          visit_outcome: params[1],
          outcome_notes: params[2],
        };
        return { rows: [visitRows[idx]] };
      }
      return { rows: [] };
    },
  };
}

describe('adoptionVisits lib (Wave C)', () => {
  it('hasPositiveVisitForSession is true only for completed positive visits', async () => {
    const pool = buildVisitPool({
      visits: [{
        id: visitId,
        fostering_session_id: placementId,
        status: VISIT_STATUS_COMPLETED,
        visit_outcome: VISIT_OUTCOME_POSITIVE,
      }],
    });
    expect(await hasPositiveVisitForSession(pool, placementId)).toBe(true);
  });

  it('negative visit does not satisfy visit path', async () => {
    const pool = buildVisitPool({
      visits: [{
        id: visitId,
        fostering_session_id: placementId,
        status: VISIT_STATUS_COMPLETED,
        visit_outcome: VISIT_OUTCOME_NEGATIVE,
      }],
    });
    const placement = {
      id: placementId,
      session_type: SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
    };
    const check = await assertVisitPathSatisfied(pool, placement);
    expect(check.error).toBeTruthy();
    expect(check.code).toBe('visit_path_incomplete');
  });

  it('records visit outcome on adoption visit row', async () => {
    const pool = buildVisitPool({
      visits: [{
        id: visitId,
        fostering_session_id: placementId,
        organization_id: orgId,
        status: 'scheduled',
        visit_outcome: null,
      }],
    });
    const result = await recordVisitOutcome(pool, {
      orgId,
      visitId,
      visitOutcome: VISIT_OUTCOME_POSITIVE,
      actorUserId: 'admin-1',
    });
    expect(result.status).toBe(200);
    expect(result.row.visit_outcome).toBe(VISIT_OUTCOME_POSITIVE);
  });
});

describe('adoption journey visit path gate', () => {
  it('blocks journey start for view-to-adopt without positive visit', async () => {
    const placement = {
      id: placementId,
      organization_id: orgId,
      pet_id: 'pet-1',
      foster_user_id: 'foster-1',
      status: SESSION_STATUS_ACTIVE,
      session_type: SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
    };
    const pool = {
      async query(sql) {
        if (sql.includes('FROM adoption_journeys') && sql.includes('fostering_session_id')) {
          return { rows: [] };
        }
        if (sql.includes('FROM adoption_visits') && sql.includes('visit_outcome')) {
          return { rows: [] };
        }
        throw new Error(`Unexpected query: ${sql}`);
      },
    };

    const result = await startAdoptionJourney(pool, { placement, createdBy: 'admin-1' });
    expect(result.status).toBe(409);
    expect(result.code).toBe('visit_path_incomplete');
  });
});
