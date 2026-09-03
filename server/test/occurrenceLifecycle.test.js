import { describe, expect, it, jest } from '@jest/globals';

import { addCalendarDaysIso, todayCalendarIso } from '../lib/calendarDate.js';
import {
  closeHealthEntrySeries,
  isEntrySeriesClosed,
  isOccurrenceDateWithinSeries,
  skipAllPendingOccurrences,
  tryAutoCloseRecurringWithEndDate,
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
        state.entry = {
          ...state.entry,
          status: 'completed',
          repeat_end_date: params[0] ? new Date(params[0]) : state.entry.repeat_end_date,
          completed_on: params[0] && state.entry.frequency === 'once'
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
    expect(isEntrySeriesClosed(makeEntry({ repeat_end_date: new Date(addCalendarDaysIso(today, 7)) }), today)).toBe(false);
  });

  it('isOccurrenceDateWithinSeries blocks dates after repeat end', () => {
    const entry = makeEntry({ repeat_end_date: new Date('2026-06-30') });
    expect(isOccurrenceDateWithinSeries(entry, '2026-06-30')).toBe(true);
    expect(isOccurrenceDateWithinSeries(entry, '2026-07-01')).toBe(false);
  });

  it('closeHealthEntrySeries skips pending occurrences and completes recurring entry', async () => {
    const today = todayCalendarIso();
    const state = {
      queries: [],
      pending: [{ id: 'occ-1' }],
      maxScheduled: null,
      entry: makeEntry({ repeat_end_date: new Date('2026-12-31') }),
      skippedPending: 0,
    };
    const pool = makePool(state);
    const row = await closeHealthEntrySeries(pool, state.entry, 'user-1', today);
    expect(state.skippedPending).toBe(1);
    expect(row.status).toBe('completed');
    expect(addCalendarDaysIso(today, -1)).toBe(
      row.repeat_end_date.toISOString().slice(0, 10),
    );
  });

  it('closeHealthEntrySeries completes once entry and skips pending occurrence', async () => {
    const today = todayCalendarIso();
    const state = {
      queries: [],
      pending: [{ id: 'occ-1' }],
      maxScheduled: null,
      entry: makeEntry({ frequency: 'once' }),
      skippedPending: 0,
    };
    const pool = makePool(state);
    const row = await closeHealthEntrySeries(pool, state.entry, 'user-1', today);
    expect(state.skippedPending).toBe(1);
    expect(row.status).toBe('completed');
    expect(row.completed_on.toISOString().slice(0, 10)).toBe(today);
  });

  it('tryAutoCloseRecurringWithEndDate closes when end date reached', async () => {
    const today = todayCalendarIso();
    const yesterday = addCalendarDaysIso(today, -1);
    const state = {
      queries: [],
      pending: [{ id: 'occ-1' }],
      maxScheduled: new Date(yesterday),
      entry: makeEntry({ repeat_end_date: new Date(yesterday) }),
      skippedPending: 0,
    };
    const pool = makePool(state);
    const row = await tryAutoCloseRecurringWithEndDate(pool, state.entry, today);
    expect(row.status).toBe('completed');
    expect(state.skippedPending).toBe(1);
  });

  it('tryAutoCloseRecurringWithEndDate closes when all occurrences through end are closed', async () => {
    const today = todayCalendarIso();
    const end = addCalendarDaysIso(today, 14);
    const state = {
      queries: [],
      pending: [],
      maxScheduled: new Date(end),
      entry: makeEntry({ repeat_end_date: new Date(end) }),
      skippedPending: 0,
    };
    const pool = makePool(state);
    const row = await tryAutoCloseRecurringWithEndDate(pool, state.entry, today);
    expect(row.status).toBe('completed');
  });

  it('tryAutoCloseRecurringWithEndDate does not close open-ended series when all open occurrences closed', async () => {
    const today = todayCalendarIso();
    const state = {
      queries: [],
      pending: [],
      maxScheduled: new Date(today),
      entry: makeEntry({ repeat_end_date: null }),
      skippedPending: 0,
    };
    const pool = makePool(state);
    const row = await tryAutoCloseRecurringWithEndDate(pool, state.entry, today);
    expect(row.status).toBe('active');
  });

  it('skipAllPendingOccurrences marks pending rows skipped', async () => {
    const state = {
      queries: [],
      pending: [{ id: 'occ-1' }, { id: 'occ-2' }],
      maxScheduled: null,
      entry: makeEntry(),
      skippedPending: 0,
    };
    const pool = makePool(state);
    await skipAllPendingOccurrences(pool, 'entry-1', 'user-1');
    expect(state.skippedPending).toBe(2);
  });
});
