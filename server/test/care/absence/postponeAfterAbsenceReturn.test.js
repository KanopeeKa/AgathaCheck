import { describe, expect, it } from '@jest/globals';
import { postponeUntilAfterReturn } from '../../../lib/care/absence/postponeAfterAbsenceReturn.js';

describe('postponeUntilAfterReturn', () => {
  it('returns the calendar day after absence ends', () => {
    expect(postponeUntilAfterReturn('2026-06-15')).toBe('2026-06-16');
  });
});
