import { describe, expect, it } from '@jest/globals';

import { defaultResumeDate } from '../../lib/care/occurrence/commands/postpone.js';

describe('defaultResumeDate after R-008 pause (no open rows)', () => {
  it('uses series_resumed_on saved at pause time', () => {
    const entry = {
      frequency: 'monthly',
      frequency_interval: 1,
      series_resumed_on: '2026-06-05',
      start_date: '2026-06-01',
      next_due_date: null,
    };
    const asOf = { todayIso: '2026-08-01', nowTimeIso: '09:00' };
    expect(defaultResumeDate(entry, [], asOf)).toBe('2026-08-05');
  });
});
