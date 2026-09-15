import { describe, expect, it } from '@jest/globals';

import {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
  PROJECTION_STATUS_COMPLETE,
  PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
  UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN,
  UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
  isDateInCareWindow,
  projectEntryForPeriod,
  projectSchedule,
} from '../../lib/care/schedule/projectSchedule.js';

const ENTRY_ID = 'entry-1';

function entry(overrides = {}) {
  return {
    id: ENTRY_ID,
    pet_id: 'pet-1',
    type: 'medication',
    name: 'Test med',
    frequency: 'once',
    frequency_interval: 1,
    recurrence_anchor: 'from_completion',
    status: 'active',
    start_date: null,
    next_due_date: null,
    repeat_end_date: null,
    schedule_times: null,
    care_family: 'medication',
    ...overrides,
  };
}

function occurrence(overrides = {}) {
  return {
    id: overrides.id || 'occ-1',
    health_entry_id: ENTRY_ID,
    scheduled_date: overrides.scheduled_date,
    scheduled_time: overrides.scheduled_time ?? null,
    status: overrides.status || 'pending',
  };
}

function projectOne(entryRow, occurrences, startsOn, endsOn, todayIso = '2026-08-01') {
  const map = new Map([[entryRow.id, occurrences]]);
  return projectSchedule([entryRow], map, startsOn, endsOn, todayIso);
}

describe('projectSchedule', () => {
  describe('isDateInCareWindow', () => {
    it('includes boundary dates', () => {
      expect(isDateInCareWindow('2026-08-12', '2026-08-12', '2026-08-19')).toBe(true);
      expect(isDateInCareWindow('2026-08-19', '2026-08-12', '2026-08-19')).toBe(true);
      expect(isDateInCareWindow('2026-08-11', '2026-08-12', '2026-08-19')).toBe(false);
      expect(isDateInCareWindow('2026-08-20', '2026-08-12', '2026-08-19')).toBe(false);
    });
  });

  describe('per-item certainty', () => {
    it('marks from_due_date projected items as complete certainty', () => {
      const result = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-14',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.items).toHaveLength(1);
      expect(result.items[0].certainty).toBe(CERTAINTY_COMPLETE);
      expect(result.items[0].source).toBe('projected');
    });

    it('marks from_completion projected items as conditional_on_future_completion', () => {
      const result = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_completion',
          next_due_date: '2026-08-14',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.items).toHaveLength(1);
      expect(result.items[0].certainty).toBe(CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION);
      expect(result.items[0].source).toBe('projected');
    });

    it('marks materialised items as complete certainty regardless of anchor', () => {
      const result = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_completion' }),
        [occurrence({ scheduled_date: '2026-08-14', status: 'pending' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.items).toHaveLength(1);
      expect(result.items[0].certainty).toBe(CERTAINTY_COMPLETE);
      expect(result.items[0].source).toBe('materialised');
    });
  });

  describe('aggregate projection_status', () => {
    it('returns complete when no uncertainties', () => {
      const result = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-14',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
      expect(result.uncertainties).toHaveLength(0);
    });

    it('returns partially_indeterminate when from_completion has pending occurrence', () => {
      const result = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_completion' }),
        [occurrence({ scheduled_date: '2026-08-14', status: 'pending' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.projection_status).toBe(PROJECTION_STATUS_PARTIALLY_INDETERMINATE);
      expect(result.uncertainties[0].reason).toBe(UNCERTAINTY_REASON_FROM_COMPLETION_PENDING);
    });

    it('returns partially_indeterminate for from_completion chain uncertainty', () => {
      const result = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_completion',
          next_due_date: '2026-08-14',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.projection_status).toBe(PROJECTION_STATUS_PARTIALLY_INDETERMINATE);
      expect(result.uncertainties[0].reason).toBe(UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN);
    });
  });

  describe('projection semantics', () => {
    it('materialised slots win over projected duplicates', () => {
      const result = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-14',
        }),
        [occurrence({ id: 'mat-1', scheduled_date: '2026-08-14', status: 'completed' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.items).toHaveLength(1);
      expect(result.items[0].source).toBe('materialised');
      expect(result.items[0].occurrence_id).toBe('mat-1');
    });

    it('does not project beyond repeat_end_date', () => {
      const result = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
          repeat_end_date: '2026-08-13',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(result.items.map((i) => i.scheduled_date)).toEqual(['2026-08-12', '2026-08-13']);
    });

    it('skips projection for closed series', () => {
      const result = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
          status: 'completed',
          completed_on: '2026-08-01',
        }),
        [],
        '2026-08-12',
        '2026-08-19',
        '2026-08-20'
      );
      expect(result.items).toHaveLength(0);
    });

    it('sorts items by date, time, then entry id', () => {
      const a = entry({
        id: 'a',
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-14',
      });
      const b = entry({
        id: 'b',
        frequency: 'weekly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
      });
      const map = new Map([['a', []], ['b', []]]);
      const result = projectSchedule([a, b], map, '2026-08-12', '2026-08-19', '2026-08-01');
      const dates = result.items.map((i) => i.scheduled_date);
      expect(dates).toEqual([...dates].sort());
    });
  });

  describe('projectEntryForPeriod', () => {
    it('projects a single entry without aggregate envelope', () => {
      const row = entry({
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-14',
      });
      const { items, uncertainties } = projectEntryForPeriod(
        row,
        [],
        '2026-08-12',
        '2026-08-19',
        '2026-08-01'
      );
      expect(items).toHaveLength(1);
      expect(uncertainties).toHaveLength(0);
      expect(items[0].certainty).toBe(CERTAINTY_COMPLETE);
    });
  });
});
