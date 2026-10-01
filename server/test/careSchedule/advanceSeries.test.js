import { describe, expect, it } from '@jest/globals';

import { resolveNextSeriesDate } from '../../lib/care/schedule/advanceSeries.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    frequency_days: null,
    start_date: new Date('2026-09-01'),
    next_due_date: new Date('2026-09-01'),
    recurrence_anchor: 'from_completion',
    status: 'active',
    schedule_times: null,
    repeat_end_date: null,
    ...overrides,
  };
}

describe('resolveNextSeriesDate', () => {
  it('scenario 4: weekly advances by 7 days from closed due date', () => {
    const entry = makeEntry({ frequency: 'weekly', recurrence_anchor: 'from_due_date' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-01')).toBe('2026-09-08');
  });

  it('scenario 5: from_due_date ignores late completion date', () => {
    const entry = makeEntry({ frequency: 'weekly', recurrence_anchor: 'from_due_date' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-05')).toBe('2026-09-08');
  });

  it('scenario 6: from_completion drifts from actual completion', () => {
    const entry = makeEntry({ frequency: 'weekly', recurrence_anchor: 'from_completion' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-05')).toBe('2026-09-12');
  });

  it('scenario 1: daily advances by one day', () => {
    const entry = makeEntry({ frequency: 'daily' });
    expect(resolveNextSeriesDate(entry, '2026-09-01', '2026-09-01')).toBe('2026-09-02');
  });
});
