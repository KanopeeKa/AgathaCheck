/**
 * CC-2 projection fixture corpus — 30 deterministic cases for projectEntryForPeriod / projectCareForPeriod.
 */

import {
  PROJECTION_STATUS_COMPLETE,
  PROJECTION_STATUS_PARTIALLY_INDETERMINATE,
  UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN,
  UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
  projectCareForPeriod,
  projectEntryForPeriod,
} from '../../lib/care/carePeriodProjection.js';

const ENTRY_ID = 'entry-1';
const PET_ID = 'pet-1';

function entry(overrides = {}) {
  return {
    id: ENTRY_ID,
    pet_id: PET_ID,
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
    id: overrides.id || `occ-${Math.random().toString(36).slice(2, 8)}`,
    health_entry_id: ENTRY_ID,
    scheduled_date: overrides.scheduled_date,
    scheduled_time: overrides.scheduled_time ?? null,
    status: overrides.status || 'pending',
  };
}

function projectOne(entryRow, occurrences, startsOn, endsOn, todayIso = '2026-08-01') {
  const map = new Map([[entryRow.id, occurrences]]);
  return projectCareForPeriod([entryRow], map, startsOn, endsOn, todayIso);
}

export const corpusCases = [
  {
    id: 'monthly-from-due-single',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-05',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
      expect(r.items).toHaveLength(0);
    },
  },
  {
    id: 'monthly-from-due-in-window',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-14',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
      expect(r.items).toEqual([
        expect.objectContaining({
          scheduled_date: '2026-08-14',
          source: 'projected',
          status: 'pending',
        }),
      ]);
    },
  },
  {
    id: 'daily-from-due-multiple',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
        }),
        [],
        '2026-08-12',
        '2026-08-15'
      );
      expect(r.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
      expect(r.items.map((i) => i.scheduled_date)).toEqual([
        '2026-08-12',
        '2026-08-13',
        '2026-08-14',
        '2026-08-15',
      ]);
    },
  },
  {
    id: 'yearly-from-due-boundary',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'yearly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-19',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(1);
      expect(r.items[0].scheduled_date).toBe('2026-08-19');
    },
  },
  {
    id: 'from-completion-pending-in-window',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_completion' }),
        [occurrence({ scheduled_date: '2026-08-14', status: 'pending' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.projection_status).toBe(PROJECTION_STATUS_PARTIALLY_INDETERMINATE);
      expect(r.items).toHaveLength(1);
      expect(r.uncertainties[0].reason).toBe(UNCERTAINTY_REASON_FROM_COMPLETION_PENDING);
    },
  },
  {
    id: 'from-completion-pending-before-window',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_completion' }),
        [occurrence({ scheduled_date: '2026-08-05', status: 'pending' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(0);
      expect(r.projection_status).toBe(PROJECTION_STATUS_PARTIALLY_INDETERMINATE);
    },
  },
  {
    id: 'from-completion-next-due-only-hop',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_completion',
          next_due_date: '2026-08-14',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(1);
      expect(r.items[0].scheduled_date).toBe('2026-08-14');
      expect(r.uncertainties[0].reason).toBe(UNCERTAINTY_REASON_FROM_COMPLETION_CHAIN);
    },
  },
  {
    id: 'materialised-wins-over-projected',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-14',
        }),
        [occurrence({ id: 'mat-1', scheduled_date: '2026-08-14', status: 'completed' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(1);
      expect(r.items[0].source).toBe('materialised');
      expect(r.items[0].occurrence_id).toBe('mat-1');
    },
  },
  {
    id: 'once-start-in-window',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'once', start_date: '2026-08-15' }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(1);
      expect(r.items[0].source).toBe('projected');
    },
  },
  {
    id: 'once-outside-window',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'once', start_date: '2026-09-01' }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(0);
      expect(r.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
    },
  },
  {
    id: 'skipped-occurrence-included',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_due_date', next_due_date: '2026-08-12' }),
        [occurrence({ scheduled_date: '2026-08-13', status: 'skipped' })],
        '2026-08-12',
        '2026-08-15'
      );
      expect(r.items.some((i) => i.status === 'skipped')).toBe(true);
    },
  },
  {
    id: 'completed-occurrence-included',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_due_date', next_due_date: '2026-08-12' }),
        [occurrence({ scheduled_date: '2026-08-13', status: 'completed' })],
        '2026-08-12',
        '2026-08-15'
      );
      expect(r.items.some((i) => i.status === 'completed')).toBe(true);
    },
  },
  {
    id: 'repeat-end-date-stops-projection',
    run: () => {
      const r = projectOne(
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
      expect(r.items.map((i) => i.scheduled_date)).toEqual(['2026-08-12', '2026-08-13']);
    },
  },
  {
    id: 'closed-series-excluded',
    run: () => {
      const r = projectOne(
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
      expect(r.items).toHaveLength(0);
    },
  },
  {
    id: 'multi-schedule-times',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
          schedule_times: ['08:00', '20:00'],
        }),
        [],
        '2026-08-12',
        '2026-08-12'
      );
      expect(r.items).toHaveLength(2);
      expect(r.items.map((i) => i.scheduled_time).sort()).toEqual(['08:00', '20:00']);
    },
  },
  {
    id: 'zero-items-complete-from-due',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-07-01',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(0);
      expect(r.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
    },
  },
  {
    id: 'window-start-boundary',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items[0].scheduled_date).toBe('2026-08-12');
    },
  },
  {
    id: 'window-end-boundary',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-19',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items[0].scheduled_date).toBe('2026-08-19');
    },
  },
  {
    id: 'weekly-from-due',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'weekly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
        }),
        [],
        '2026-08-12',
        '2026-08-26'
      );
      expect(r.items.map((i) => i.scheduled_date)).toEqual([
        '2026-08-12',
        '2026-08-19',
        '2026-08-26',
      ]);
    },
  },
  {
    id: 'custom-frequency',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'custom',
          frequency_days: 3,
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
        }),
        [],
        '2026-08-12',
        '2026-08-20'
      );
      expect(r.items.map((i) => i.scheduled_date)).toEqual([
        '2026-08-12',
        '2026-08-15',
        '2026-08-18',
      ]);
    },
  },
  {
    id: 'from-completion-pending-last-day',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_completion' }),
        [occurrence({ scheduled_date: '2026-08-19', status: 'pending' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(1);
      expect(r.projection_status).toBe(PROJECTION_STATUS_PARTIALLY_INDETERMINATE);
    },
  },
  {
    id: 'two-months-from-due',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'monthly',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-05',
        }),
        [],
        '2026-08-01',
        '2026-09-30'
      );
      expect(r.items.map((i) => i.scheduled_date)).toEqual(['2026-08-05', '2026-09-05']);
    },
  },
  {
    id: 'only-completed-in-window',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'daily', recurrence_anchor: 'from_due_date', next_due_date: '2026-08-12' }),
        [
          occurrence({ scheduled_date: '2026-08-13', status: 'completed' }),
          occurrence({ scheduled_date: '2026-08-14', status: 'completed' }),
        ],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items.filter((i) => i.status === 'completed').length).toBeGreaterThanOrEqual(2);
    },
  },
  {
    id: 'mixed-entries-aggregate-uncertain',
    run: () => {
      const certain = entry({
        id: 'certain',
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-14',
      });
      const uncertain = entry({
        id: 'uncertain',
        frequency: 'daily',
        recurrence_anchor: 'from_completion',
      });
      const map = new Map([
        ['certain', []],
        ['uncertain', [occurrence({ health_entry_id: 'uncertain', scheduled_date: '2026-08-14' })]],
      ]);
      const r = projectCareForPeriod(
        [certain, uncertain],
        map,
        '2026-08-12',
        '2026-08-19',
        '2026-08-01'
      );
      expect(r.projection_status).toBe(PROJECTION_STATUS_PARTIALLY_INDETERMINATE);
      expect(r.items.length).toBeGreaterThanOrEqual(2);
    },
  },
  {
    id: 'aggregate-complete',
    run: () => {
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
      const r = projectCareForPeriod([a, b], map, '2026-08-12', '2026-08-19', '2026-08-01');
      expect(r.projection_status).toBe(PROJECTION_STATUS_COMPLETE);
    },
  },
  {
    id: 'project-entry-direct',
    run: () => {
      const row = entry({
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-14',
      });
      const { items, uncertainties } = projectEntryForPeriod(row, [], '2026-08-12', '2026-08-19', '2026-08-01');
      expect(items).toHaveLength(1);
      expect(uncertainties).toHaveLength(0);
    },
  },
  {
    id: 'from-completion-overdue-before-window',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_completion',
          next_due_date: '2026-08-05',
        }),
        [],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items).toHaveLength(0);
      expect(r.uncertainties[0].reason).toBe(UNCERTAINTY_REASON_FROM_COMPLETION_PENDING);
    },
  },
  {
    id: 'all-day-materialised',
    run: () => {
      const r = projectOne(
        entry({ frequency: 'once', start_date: '2026-08-15' }),
        [occurrence({ scheduled_date: '2026-08-15', status: 'pending' })],
        '2026-08-12',
        '2026-08-19'
      );
      expect(r.items[0].scheduled_time).toBeNull();
      expect(r.items[0].source).toBe('materialised');
    },
  },
  {
    id: 'sorted-items',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'daily',
          recurrence_anchor: 'from_due_date',
          next_due_date: '2026-08-12',
        }),
        [occurrence({ scheduled_date: '2026-08-14', status: 'completed' })],
        '2026-08-12',
        '2026-08-15'
      );
      const dates = r.items.map((i) => i.scheduled_date);
      expect(dates).toEqual([...dates].sort());
    },
  },
  {
    id: 'once-completed-series-closed',
    run: () => {
      const r = projectOne(
        entry({
          frequency: 'once',
          start_date: '2026-08-01',
          status: 'completed',
          completed_on: '2026-08-01',
        }),
        [occurrence({ scheduled_date: '2026-08-01', status: 'completed' })],
        '2026-08-12',
        '2026-08-19',
        '2026-08-10'
      );
      expect(r.items).toHaveLength(0);
    },
  },
];
