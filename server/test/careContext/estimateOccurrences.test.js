import { describe, expect, it } from '@jest/globals';

import { estimateOccurrences, computeOpenStatus } from '../../lib/care/schedule/estimateOccurrences.js';

function entry(overrides = {}) {
  return {
    id: 'entry-1',
    frequency: 'weekly',
    frequency_interval: 1,
    recurrence_anchor: 'from_completion',
    repeat_end_date: null,
    ...overrides,
  };
}

describe('estimateOccurrences', () => {
  it('product example: due Mon 1st, 7-day weekly, absence 6–10 → 8th', () => {
    const result = estimateOccurrences({
      entry: entry({ frequency: 'custom', frequency_interval: 7 }),
      openOccurrence: { scheduled_date: '2026-09-01' },
      lastCompletedOn: null,
      startsOn: '2026-09-06',
      endsOn: '2026-09-10',
      todayIso: '2026-09-01',
    });
    expect(result.dates).toEqual(['2026-09-08']);
    expect(result.basis).toBe('estimated');
  });

  it('product example: absence 20–23 → 22nd', () => {
    const result = estimateOccurrences({
      entry: entry({ frequency: 'custom', frequency_interval: 7 }),
      openOccurrence: { scheduled_date: '2026-09-01' },
      lastCompletedOn: null,
      startsOn: '2026-09-20',
      endsOn: '2026-09-23',
      todayIso: '2026-09-01',
    });
    expect(result.dates).toEqual(['2026-09-22']);
  });

  it('uses today as base when open occurrence is overdue', () => {
    const result = estimateOccurrences({
      entry: entry({ frequency: 'weekly' }),
      openOccurrence: { scheduled_date: '2026-08-01' },
      lastCompletedOn: null,
      startsOn: '2026-08-12',
      endsOn: '2026-08-19',
      todayIso: '2026-08-10',
    });
    expect(result.dates[0]).toBe('2026-08-17');
  });
});

describe('computeOpenStatus', () => {
  it('classifies overdue, due before absence, and in window', () => {
    expect(computeOpenStatus('2026-08-01', '2026-08-10', '2026-08-12', '2026-08-19'))
      .toBe('overdue');
    expect(computeOpenStatus('2026-08-11', '2026-08-10', '2026-08-12', '2026-08-19'))
      .toBe('due_before_absence');
    expect(computeOpenStatus('2026-08-14', '2026-08-10', '2026-08-12', '2026-08-19'))
      .toBe('in_window');
  });
});
