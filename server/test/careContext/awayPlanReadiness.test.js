import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import {
  COVERAGE_POLICY_VERSION,
  COVERAGE_STATE_ALL_COMPLETED,
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_INDETERMINATE,
  COVERAGE_STATE_NOTHING_SCHEDULED,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
  REASON_COMPLETE_ZERO_ITEMS,
} from '../../lib/care/carePeriodCoverage.js';
import {
  CARER_COVERAGE_ALL_HAVE_CARERS,
  CARER_COVERAGE_COPY_KEYS,
  CARER_COVERAGE_NONE_HAVE_CARERS,
  CARER_COVERAGE_SOME_HAVE_CARERS,
  CARE_COVERAGE_COPY_KEYS,
  TILE_COPY_CARER_NONE,
  TILE_COPY_CARER_SOME,
  TILE_COPY_SOURCE_CARER,
  TILE_COPY_SOURCE_CARE,
  deriveAwayPlanReadiness,
  deriveCarerCoverage,
} from '../../lib/care/awayPlan/readiness.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

function carerCoverageState(state, petsWithCarer, petsTotal) {
  return {
    state,
    pets_with_carer: petsWithCarer,
    pets_total: petsTotal,
    copy_key: CARER_COVERAGE_COPY_KEYS[state],
  };
}

function careCoverageState(state, overrides = {}) {
  const defaults = {
    policy_version: COVERAGE_POLICY_VERSION,
    coverage_state: state,
    reason_codes: [],
    reassurance_available: state !== COVERAGE_STATE_INDETERMINATE,
  };
  return { ...defaults, ...overrides };
}

describe('deriveAwayPlanReadiness matrix (D-AWAY-002)', () => {
  const coverageStates = [
    COVERAGE_STATE_NOTHING_SCHEDULED,
    COVERAGE_STATE_ALL_COMPLETED,
    COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
    COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
    COVERAGE_STATE_INDETERMINATE,
  ];

  const carerStates = [
    {
      state: CARER_COVERAGE_ALL_HAVE_CARERS,
      petsWithCarer: 2,
      petsTotal: 2,
    },
    {
      state: CARER_COVERAGE_SOME_HAVE_CARERS,
      petsWithCarer: 1,
      petsTotal: 2,
    },
    {
      state: CARER_COVERAGE_NONE_HAVE_CARERS,
      petsWithCarer: 0,
      petsTotal: 2,
    },
  ];

  for (const carer of carerStates) {
    for (const coverageState of coverageStates) {
      it(`carer=${carer.state} × coverage=${coverageState}`, () => {
        const careCoverage = careCoverageState(coverageState, coverageState === COVERAGE_STATE_HAS_ITEMS_TO_REVIEW
          ? { pending_item_count: 2 }
          : {});
        const result = deriveAwayPlanReadiness(
          carerCoverageState(carer.state, carer.petsWithCarer, carer.petsTotal),
          careCoverage
        );

        expect(result.carer_coverage).toEqual({
          state: carer.state,
          pets_with_carer: carer.petsWithCarer,
          pets_total: carer.petsTotal,
          copy_key: CARER_COVERAGE_COPY_KEYS[carer.state],
        });

        expect(result.care_coverage.coverage_state).toBe(coverageState);
        expect(result.care_coverage.copy_key).toBe(CARE_COVERAGE_COPY_KEYS[coverageState]);
        if (coverageState === COVERAGE_STATE_HAS_ITEMS_TO_REVIEW) {
          expect(result.care_coverage.copy_params).toEqual({ count: 2 });
        } else {
          expect(result.care_coverage.copy_params).toBeUndefined();
        }

        if (carer.state === CARER_COVERAGE_ALL_HAVE_CARERS) {
          expect(result.tile_copy.source).toBe(TILE_COPY_SOURCE_CARE);
          expect(result.tile_copy.copy_key).toBe(CARE_COVERAGE_COPY_KEYS[coverageState]);
          if (coverageState === COVERAGE_STATE_HAS_ITEMS_TO_REVIEW) {
            expect(result.tile_copy.copy_params).toEqual({ count: 2 });
          }
        } else if (carer.state === CARER_COVERAGE_SOME_HAVE_CARERS) {
          expect(result.tile_copy).toEqual({
            source: TILE_COPY_SOURCE_CARER,
            copy_key: TILE_COPY_CARER_SOME,
          });
        } else {
          expect(result.tile_copy).toEqual({
            source: TILE_COPY_SOURCE_CARER,
            copy_key: TILE_COPY_CARER_NONE,
          });
        }
      });
    }
  }

  it('never maps nothing_scheduled to an all-clear reassurance copy key', () => {
    const result = deriveAwayPlanReadiness(
      carerCoverageState(CARER_COVERAGE_ALL_HAVE_CARERS, 1, 1),
      careCoverageState(COVERAGE_STATE_NOTHING_SCHEDULED, {
        reason_codes: [REASON_COMPLETE_ZERO_ITEMS],
      })
    );
    expect(result.care_coverage.copy_key).toBe('careContextCoverageNothingScheduled');
    expect(result.care_coverage.copy_key).not.toBe('careContextCoverageAllCompleted');
    expect(result.tile_copy.copy_key).toBe('careContextCoverageNothingScheduled');
  });
});

describe('deriveCarerCoverage', () => {
  it('treats shared_user without carer_user_id as unset', () => {
    const result = deriveCarerCoverage([
      { pet_id: petId, carer_kind: 'shared_user', carer_user_id: null },
    ]);
    expect(result.state).toBe(CARER_COVERAGE_NONE_HAVE_CARERS);
  });

  it('counts note_only with name as assigned', () => {
    const result = deriveCarerCoverage([
      { pet_id: petId, carer_kind: 'note_only', carer_name: 'Tom' },
    ]);
    expect(result.state).toBe(CARER_COVERAGE_ALL_HAVE_CARERS);
  });
});

describe('GET /api/planned-absences/:id/readiness', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);
  const absenceId = 'abs-readiness-1';

  function createTestApp(handler) {
    return createApp(createMockPool(handler));
  }

  it('returns readiness triple for a manageable absence', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return {
          rows: [{
            id: absenceId,
            user_id: userId,
            starts_on: startsOn,
            ends_on: endsOn,
            provenance: 'user_declared',
            source_ref: null,
            status: 'active',
            created_at: new Date(),
            updated_at: new Date(),
            cancelled_at: null,
          }],
        };
      }
      if (sql.includes('FROM planned_absence_pets')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: null,
            carer_user_id: null,
            carer_name: null,
            carer_note: null,
          }],
        };
      }
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: petId, user_id: userId }] };
      }
      if (sql.includes('FROM health_entries WHERE pet_id = $1')) {
        return { rows: [] };
      }
      if (sql.includes('FROM health_occurrences ho')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/readiness`)
      .set(authHeader());

    expect(res.statusCode).toBe(200);
    expect(res.body.carer_coverage.state).toBe(CARER_COVERAGE_NONE_HAVE_CARERS);
    expect(res.body.care_coverage.coverage_state).toBe(COVERAGE_STATE_NOTHING_SCHEDULED);
    expect(res.body.care_coverage.reason_codes).toEqual([REASON_COMPLETE_ZERO_ITEMS]);
    expect(res.body.tile_copy).toEqual({
      source: TILE_COPY_SOURCE_CARER,
      copy_key: TILE_COPY_CARER_NONE,
    });
  });

  it('returns 404 when absence is not owned by caller', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/readiness`)
      .set(authHeader());

    expect(res.statusCode).toBe(404);
  });
});
