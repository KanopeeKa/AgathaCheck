import {
  COVERAGE_STATE_ALL_COMPLETED,
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_INDETERMINATE,
  COVERAGE_STATE_NOTHING_SCHEDULED,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
  COVERAGE_POLICY_VERSION,
  REASON_ALL_ITEMS_COMPLETED,
  REASON_COMPLETE_ZERO_ITEMS,
  REASON_NO_PENDING_ITEMS,
  REASON_PENDING_ITEMS_IN_WINDOW,
  REASON_PROJECTION_PARTIALLY_INDETERMINATE,
  evaluateCarePeriodCoverage,
} from '../../lib/care/carePeriodCoverage.js';
import {
  PROJECTION_STATUS_COMPLETE,
  PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
} from '../../lib/care/carePeriodProjection.js';

function projection(overrides = {}) {
  return {
    projection_status: PROJECTION_STATUS_COMPLETE,
    items: [],
    uncertainties: [],
    ...overrides,
  };
}

function item(status, date = '2026-08-14') {
  return {
    health_entry_id: 'entry-1',
    scheduled_date: date,
    scheduled_time: null,
    status,
    source: 'materialised',
  };
}

describe('CarePeriodCoveragePolicy', () => {
  it('returns indeterminate when projection is partially indeterminate', () => {
    const result = evaluateCarePeriodCoverage(
      projection({
        projection_status: PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
        items: [],
        uncertainties: [{ health_entry_id: 'e1', reason: 'from_completion_pending' }],
      })
    );
    expect(result.policy_version).toBe(COVERAGE_POLICY_VERSION);
    expect(result.coverage_state).toBe(COVERAGE_STATE_INDETERMINATE);
    expect(result.reason_codes).toEqual([REASON_PROJECTION_PARTIALLY_INDETERMINATE]);
    expect(result.reassurance_available).toBe(false);
  });

  it('does not return nothing_scheduled when projection is uncertain even with zero items', () => {
    const result = evaluateCarePeriodCoverage(
      projection({
        projection_status: PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
        items: [],
      })
    );
    expect(result.coverage_state).not.toBe(COVERAGE_STATE_NOTHING_SCHEDULED);
  });

  it('returns nothing_scheduled for complete projection with zero items', () => {
    const result = evaluateCarePeriodCoverage(projection());
    expect(result.coverage_state).toBe(COVERAGE_STATE_NOTHING_SCHEDULED);
    expect(result.reason_codes).toEqual([REASON_COMPLETE_ZERO_ITEMS]);
    expect(result.reassurance_available).toBe(true);
  });

  it('returns has_items_to_review when pending items exist', () => {
    const result = evaluateCarePeriodCoverage(
      projection({ items: [item('pending'), item('completed', '2026-08-13')] })
    );
    expect(result.coverage_state).toBe(COVERAGE_STATE_HAS_ITEMS_TO_REVIEW);
    expect(result.reason_codes).toEqual([REASON_PENDING_ITEMS_IN_WINDOW]);
  });

  it('returns all_completed when every item is completed', () => {
    const result = evaluateCarePeriodCoverage(
      projection({
        items: [item('completed', '2026-08-13'), item('completed', '2026-08-14')],
      })
    );
    expect(result.coverage_state).toBe(COVERAGE_STATE_ALL_COMPLETED);
    expect(result.reason_codes).toEqual([REASON_ALL_ITEMS_COMPLETED]);
  });

  it('returns no_unresolved_items when only completed and skipped items remain', () => {
    const result = evaluateCarePeriodCoverage(
      projection({
        items: [item('completed', '2026-08-13'), item('skipped', '2026-08-14')],
      })
    );
    expect(result.coverage_state).toBe(COVERAGE_STATE_NO_UNRESOLVED_ITEMS);
    expect(result.reason_codes).toEqual([REASON_NO_PENDING_ITEMS]);
  });
});
