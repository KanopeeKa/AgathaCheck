import { describe, expect, it } from '@jest/globals';
import { inferResolutionDecisionAfterSchedule } from '../../../lib/care/absence/inferResolutionDecision.js';

describe('inferResolutionDecisionAfterSchedule', () => {
  const starts = '2026-06-10';
  const ends = '2026-06-15';

  it('returns move_before when date is before departure', () => {
    expect(inferResolutionDecisionAfterSchedule('2026-06-09', starts, ends)).toBe('move_before');
  });

  it('returns move_after when date is after return', () => {
    expect(inferResolutionDecisionAfterSchedule('2026-06-16', starts, ends)).toBe('move_after');
  });

  it('returns null when date stays in the window', () => {
    expect(inferResolutionDecisionAfterSchedule('2026-06-12', starts, ends)).toBeNull();
  });
});
