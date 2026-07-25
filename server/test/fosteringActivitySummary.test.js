import {
  ACTIVITY_ACTIVELY_FOSTERING,
  ACTIVITY_IN_PREPARATION,
  ACTIVITY_INACTIVE,
  ACTIVITY_NOT_YET_PLACED,
  ACTIVITY_RECENTLY_ENDED,
  deriveActivitySummary,
} from '../lib/fosteringActivitySummary.js';

describe('fosteringActivitySummary', () => {
  it('prioritises active sessions over preparation', () => {
    expect(deriveActivitySummary({
      preparationCount: 1,
      activeCount: 1,
      recentlyEndedCount: 0,
      hasAnyHistory: true,
    })).toBe(ACTIVITY_ACTIVELY_FOSTERING);
  });

  it('returns in_preparation when only prep sessions exist', () => {
    expect(deriveActivitySummary({
      preparationCount: 2,
      activeCount: 0,
      recentlyEndedCount: 0,
      hasAnyHistory: true,
    })).toBe(ACTIVITY_IN_PREPARATION);
  });

  it('returns recently_ended when no open sessions but recent terminal session', () => {
    expect(deriveActivitySummary({
      preparationCount: 0,
      activeCount: 0,
      recentlyEndedCount: 1,
      hasAnyHistory: true,
    })).toBe(ACTIVITY_RECENTLY_ENDED);
  });

  it('returns not_yet_placed for approved fosters without history', () => {
    expect(deriveActivitySummary({
      preparationCount: 0,
      activeCount: 0,
      recentlyEndedCount: 0,
      hasAnyHistory: false,
    })).toBe(ACTIVITY_NOT_YET_PLACED);
  });

  it('returns inactive when history exists but no recent activity', () => {
    expect(deriveActivitySummary({
      preparationCount: 0,
      activeCount: 0,
      recentlyEndedCount: 0,
      hasAnyHistory: true,
    })).toBe(ACTIVITY_INACTIVE);
  });
});
