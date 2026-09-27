import { describe, expect, it } from '@jest/globals';
import { evaluateCarePeriodCoverageWithResolutions } from '../../../lib/care/absence/absenceCoverage.js';
import {
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
} from '../../../lib/care/carePeriodCoverage.js';
import { PROJECTION_STATUS_COMPLETE } from '../../../lib/care/carePeriodProjection.js';
import { RESOLUTION_DECISION_KEEP_DATE } from '../../../lib/care/absence/constants.js';

describe('evaluateCarePeriodCoverageWithResolutions', () => {
  const window = { startsOn: '2026-10-25', endsOn: '2026-10-30' };

  it('drops pending items for resolved affected entries', () => {
    const projection = {
      projection_status: PROJECTION_STATUS_COMPLETE,
      items: [
        {
          health_entry_id: 'entry-1',
          scheduled_date: '2026-10-26',
          status: 'pending',
        },
      ],
    };
    const plannedCareItems = [
      {
        health_entry_id: 'entry-1',
        in_window: { first_date: '2026-10-26', last_date: '2026-10-26', count: 1 },
        open_occurrence: { open_status: 'in_window' },
      },
    ];
    const resolutions = new Map([
      [
        'entry-1',
        {
          decision: RESOLUTION_DECISION_KEEP_DATE,
          carer_kind: null,
          carer_user_id: null,
          dates_decided_for: ['2026-10-26'],
        },
      ],
    ]);

    const coverage = evaluateCarePeriodCoverageWithResolutions(
      projection,
      plannedCareItems,
      resolutions,
      window
    );
    expect(coverage.coverage_state).toBe(COVERAGE_STATE_NO_UNRESOLVED_ITEMS);
  });

  it('keeps has_items_to_review when unresolved', () => {
    const projection = {
      projection_status: PROJECTION_STATUS_COMPLETE,
      items: [
        {
          health_entry_id: 'entry-1',
          scheduled_date: '2026-10-26',
          status: 'pending',
        },
      ],
    };
    const plannedCareItems = [
      {
        health_entry_id: 'entry-1',
        in_window: { first_date: '2026-10-26', last_date: '2026-10-26', count: 1 },
        open_occurrence: { open_status: 'in_window' },
      },
    ];
    const coverage = evaluateCarePeriodCoverageWithResolutions(
      projection,
      plannedCareItems,
      new Map(),
      window
    );
    expect(coverage.coverage_state).toBe(COVERAGE_STATE_HAS_ITEMS_TO_REVIEW);
  });
});
