import {
  DERIVED_STATUS_NEARLY_FINISHED,
  deriveSessionStatus,
} from '../lib/deriveSessionStatus.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_PREPARATION,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
} from '../lib/fosterPlacements.js';

describe('deriveSessionStatus', () => {
  const now = new Date('2026-08-02T12:00:00.000Z');

  it.each([
    [
      'active session ending in 5 days',
      { session_status: SESSION_STATUS_ACTIVE, end_date: '2026-08-07' },
      DERIVED_STATUS_NEARLY_FINISHED,
      true,
    ],
    [
      'active session ending in 10 days',
      { session_status: SESSION_STATUS_ACTIVE, end_date: '2026-08-12' },
      DERIVED_STATUS_NEARLY_FINISHED,
      true,
    ],
    [
      'active session ending in 11 days',
      { session_status: SESSION_STATUS_ACTIVE, end_date: '2026-08-13' },
      SESSION_STATUS_ACTIVE,
      false,
    ],
    [
      'active session with no end date',
      { session_status: SESSION_STATUS_ACTIVE, end_date: null },
      SESSION_STATUS_ACTIVE,
      false,
    ],
    [
      'preparation session is not nearly finished',
      { session_status: SESSION_STATUS_PREPARATION, end_date: '2026-08-05' },
      SESSION_STATUS_PREPARATION,
      false,
    ],
    [
      'cancelled session is not nearly finished',
      { session_status: SESSION_STATUS_CANCELLED, end_date: '2026-08-05' },
      SESSION_STATUS_CANCELLED,
      false,
    ],
  ])('%s', (_label, placement, expectedDerived, expectedNearlyFinished) => {
    const result = deriveSessionStatus(placement, now);
    expect(result.derived_status).toBe(expectedDerived);
    expect(result.nearly_finished).toBe(expectedNearlyFinished);
    expect(result.session_status).toBe(placement.session_status);
  });

  it('flags foster in view to adopt sessions', () => {
    const result = deriveSessionStatus({
      session_status: SESSION_STATUS_ACTIVE,
      session_type: SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
    }, now);
    expect(result.in_view_to_adopt).toBe(true);
  });
});
