import { describe, expect, it } from '@jest/globals';

import { addCalendarDaysIso, todayCalendarIso } from '../lib/calendarDate.js';
import {
  isEntrySeriesClosed,
  isOccurrenceDateWithinSeries,
} from '../lib/occurrenceLifecycle.js';

function makeEntry(overrides = {}) {
  return {
    id: 'entry-1',
    frequency: 'daily',
    status: 'active',
    start_date: new Date('2026-01-01'),
    repeat_end_date: null,
    completed_on: null,
    schedule_times: null,
    ...overrides,
  };
}

function makePool(state) {
  return {
    query: jest.fn(async (sql, params) => {
      state.queries.push({ sql, params });
      if (sql.includes('UPDATE health_occurrences SET status = \'skipped\'')) {
        state.skippedPending += state.pending.length;
        state.pending = [];
        return { rows: [] };
      }
      if (sql.includes("status = 'pending' LIMIT 1")) {
        return { rows: state.pending.length > 0 ? [{ id: 'p1' }] : [] };
      }
      if (sql.includes('MAX(scheduled_date)')) {
        return { rows: [{ max_date: state.maxScheduled }] };
      }
      if (sql.includes("UPDATE health_entries SET status = 'completed'")) {
        const isOnceClose = sql.includes('repeat_end_date = NULL');
        state.entry = {
          ...state.entry,
          status: 'completed',
          repeat_end_date: isOnceClose ? null : new Date(params[0]),
          completed_on: isOnceClose
            ? new Date(params[0])
            : state.entry.completed_on,
          next_due_date: null,
        };
        return { rows: [state.entry] };
      }
      return { rows: [] };
    }),
  };
}

describe('occurrence lifecycle', () => {
  it('isEntrySeriesClosed respects status, once completed_on, and repeat end', () => {
    const today = todayCalendarIso();
    const yesterday = addCalendarDaysIso(today, -1);
    expect(isEntrySeriesClosed(makeEntry({ status: 'completed' }), today)).toBe(true);
    expect(isEntrySeriesClosed(makeEntry({ frequency: 'once', completed_on: new Date(today) }), today)).toBe(true);
    expect(isEntrySeriesClosed(makeEntry({ repeat_end_date: new Date(yesterday) }), today)).toBe(true);
    expect(isEntrySeriesClosed(makeEntry({ repeat_end_date: new Date(today) }), today)).toBe(false);
    expect(isEntrySeriesClosed(makeEntry({ repeat_end_date: new Date(addCalendarDaysIso(today, 7)) }), today)).toBe(false);
  });

  it('isOccurrenceDateWithinSeries blocks dates after repeat end', () => {
    const entry = makeEntry({ repeat_end_date: new Date('2026-06-30') });
    expect(isOccurrenceDateWithinSeries(entry, '2026-06-30')).toBe(true);
    expect(isOccurrenceDateWithinSeries(entry, '2026-07-01')).toBe(false);
  });
});
