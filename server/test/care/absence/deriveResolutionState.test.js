import { describe, expect, it } from '@jest/globals';
import { deriveResolutionUiState } from '../../../lib/care/absence/deriveResolutionState.js';
import {
  RESOLUTION_DECISION_KEEP_DATE,
  UI_STATE_NEEDS_REVIEW,
  UI_STATE_NOTHING_DUE,
  UI_STATE_NOT_REVIEWED,
  UI_STATE_RESOLVED,
} from '../../../lib/care/absence/constants.js';

const window = { startsOn: '2026-10-25', endsOn: '2026-10-30' };

describe('deriveResolutionUiState', () => {
  const affectedRow = {
    health_entry_id: 'entry-1',
    in_window: { first_date: '2026-10-26', last_date: '2026-10-26', count: 1 },
    open_occurrence: { open_status: 'in_window', scheduled_date: '2026-10-26' },
  };

  it('returns nothing_due when not affected', () => {
    expect(
      deriveResolutionUiState(null, { in_window: null, open_occurrence: null }, window)
    ).toBe(UI_STATE_NOTHING_DUE);
  });

  it('returns not_reviewed without a resolution', () => {
    expect(deriveResolutionUiState(null, affectedRow, window)).toBe(UI_STATE_NOT_REVIEWED);
  });

  it('returns resolved when dates still match', () => {
    const resolution = {
      decision: RESOLUTION_DECISION_KEEP_DATE,
      carer_kind: null,
      carer_user_id: null,
      dates_decided_for: ['2026-10-26'],
    };
    const items = [
      {
        health_entry_id: 'entry-1',
        scheduled_date: '2026-10-26',
        status: 'pending',
      },
    ];
    expect(
      deriveResolutionUiState(resolution, affectedRow, {
        ...window,
        projectionItems: items,
      })
    ).toBe(UI_STATE_RESOLVED);
  });

  it('returns needs_review when dates changed', () => {
    const resolution = {
      decision: RESOLUTION_DECISION_KEEP_DATE,
      carer_kind: null,
      carer_user_id: null,
      dates_decided_for: ['2026-10-25'],
    };
    const items = [
      {
        health_entry_id: 'entry-1',
        scheduled_date: '2026-10-26',
        status: 'pending',
      },
    ];
    expect(
      deriveResolutionUiState(resolution, affectedRow, {
        ...window,
        projectionItems: items,
      })
    ).toBe(UI_STATE_NEEDS_REVIEW);
  });
});
