import { describe, expect, it } from '@jest/globals';

import {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
  projectSchedule,
} from '../../lib/care/schedule/projectSchedule.js';
import {
  PLANNED_CARE_KIND_INDETERMINATE_PENDING,
  PLANNED_CARE_KIND_RECURRING_CALENDAR,
  PLANNED_CARE_KIND_RECURRING_CHAIN,
  PLANNED_CARE_KIND_SINGLE_ONCE,
  buildPlannedCareItems,
  formatProjectionReadContract,
  leastCertain,
} from '../../lib/care/awayPlan/index.js';

function entry(overrides = {}) {
  return {
    id: 'entry-1',
    pet_id: 'pet-1',
    type: 'medication',
    name: 'Daily pill',
    frequency: 'daily',
    frequency_interval: 1,
    recurrence_anchor: 'from_due_date',
    status: 'active',
    start_date: null,
    next_due_date: '2026-08-12',
    repeat_end_date: null,
    schedule_times: null,
    care_family: 'medication',
    ...overrides,
  };
}

function projectAll(entries, occurrencesByEntryId, startsOn, endsOn, todayIso = '2026-08-01') {
  return projectSchedule(entries, occurrencesByEntryId, startsOn, endsOn, todayIso);
}

function projectOne(entryRow, occurrences, startsOn, endsOn, todayIso = '2026-08-01') {
  const map = new Map([[entryRow.id, occurrences]]);
  return projectAll([entryRow], map, startsOn, endsOn, todayIso);
}

function occurrence(overrides = {}) {
  return {
    id: 'occ-1',
    health_entry_id: 'entry-1',
    scheduled_date: '2026-08-12',
    scheduled_time: null,
    status: 'pending',
    ...overrides,
  };
}

describe('awayPlan presentation', () => {
  describe('leastCertain', () => {
    it('returns complete when all constituents are complete', () => {
      expect(leastCertain([CERTAINTY_COMPLETE, CERTAINTY_COMPLETE])).toBe(CERTAINTY_COMPLETE);
    });

    it('returns conditional when any constituent is conditional', () => {
      expect(
        leastCertain([
          CERTAINTY_COMPLETE,
          CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
          CERTAINTY_COMPLETE,
        ])
      ).toBe(CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION);
    });
  });

  describe('buildPlannedCareItems', () => {
    // Test case 1 (AWD-2 delivery plan): twice-daily medication -> one row.
    it('collapses a twice-daily medication into one recurring_calendar row with both times', () => {
      const entryRow = entry({
        frequency: 'daily',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
        schedule_times: ['08:00', '20:00'],
      });
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-12');
      const entriesById = new Map([[entryRow.id, entryRow]]);

      const rows = buildPlannedCareItems(projection.items, projection.uncertainties, entriesById);

      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        kind: PLANNED_CARE_KIND_RECURRING_CALENDAR,
        health_entry_id: entryRow.id,
        name: 'Daily pill',
        type: 'medication',
        care_family: 'medication',
        frequency: 'daily',
        frequency_interval: 1,
        occurrence_count: 2,
        next_due_date: null,
      });
      expect(rows[0].times_of_day).toEqual(['08:00', '20:00']);
    });

    // Test case 2: weekly entry spanning 2 occurrences in-window -> one row, not two.
    it('collapses a weekly entry with 2 in-window occurrences into one recurring_calendar row', () => {
      const entryRow = entry({
        frequency: 'weekly',
        frequency_interval: 1,
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
        schedule_times: null,
      });
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-19');
      const entriesById = new Map([[entryRow.id, entryRow]]);

      const rows = buildPlannedCareItems(projection.items, projection.uncertainties, entriesById);

      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        kind: PLANNED_CARE_KIND_RECURRING_CALENDAR,
        occurrence_count: 2,
        first_scheduled_date: '2026-08-12',
        last_scheduled_date: '2026-08-19',
        next_due_date: '2026-08-12',
      });
      expect(rows[0].times_of_day).toEqual([]);
    });

    // Test case 3: three distinct frequency: 'once' entries -> 3 rows, never grouped.
    it('never groups frequency: once entries, one row per occurrence', () => {
      const entries = ['a', 'b', 'c'].map((suffix, index) => entry({
        id: `entry-once-${suffix}`,
        name: `Once event ${suffix}`,
        frequency: 'once',
        recurrence_anchor: 'from_due_date',
        next_due_date: `2026-08-1${2 + index}`,
        schedule_times: null,
      }));
      const occurrencesByEntryId = new Map(entries.map((e) => [e.id, []]));
      const projection = projectAll(entries, occurrencesByEntryId, '2026-08-12', '2026-08-19');
      const entriesById = new Map(entries.map((e) => [e.id, e]));

      const rows = buildPlannedCareItems(projection.items, projection.uncertainties, entriesById);

      expect(rows).toHaveLength(3);
      expect(rows.every((row) => row.kind === PLANNED_CARE_KIND_SINGLE_ONCE)).toBe(true);
      expect(new Set(rows.map((row) => row.health_entry_id)).size).toBe(3);
    });

    // Test case 4: from_completion entry with 1 materialised + 1 pending occurrence
    // in-window -> exactly one recurring_chain row, never split.
    it('merges a from_completion entry with a materialised and a pending occurrence into one recurring_chain row', () => {
      const entryRow = entry({
        frequency: 'weekly',
        frequency_interval: 1,
        recurrence_anchor: 'from_completion',
        next_due_date: '2026-08-19',
        schedule_times: null,
      });
      const occurrences = [
        occurrence({ id: 'occ-done', scheduled_date: '2026-08-12', status: 'completed' }),
        occurrence({ id: 'occ-pending', scheduled_date: '2026-08-14', status: 'pending' }),
      ];
      const projection = projectOne(entryRow, occurrences, '2026-08-12', '2026-08-19');
      const entriesById = new Map([[entryRow.id, entryRow]]);

      const rows = buildPlannedCareItems(projection.items, projection.uncertainties, entriesById);

      const chainRows = rows.filter((row) => row.health_entry_id === entryRow.id);
      expect(chainRows).toHaveLength(1);
      expect(chainRows[0]).toMatchObject({
        kind: PLANNED_CARE_KIND_RECURRING_CHAIN,
        occurrence_count: 2,
        next_due_date: null,
      });
    });

    it('surfaces a from_completion entry with no materialised occurrence as indeterminate_pending', () => {
      const entryRow = entry({
        frequency: 'weekly',
        frequency_interval: 1,
        recurrence_anchor: 'from_completion',
        next_due_date: '2026-08-05',
        schedule_times: null,
      });
      // next_due_date is before the window and there is no pending occurrence to anchor
      // on -> projectEntryForPeriod emits only an uncertainty, no item.
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-19');
      const entriesById = new Map([[entryRow.id, entryRow]]);

      expect(projection.items).toHaveLength(0);
      expect(projection.uncertainties).toHaveLength(1);

      const rows = buildPlannedCareItems(projection.items, projection.uncertainties, entriesById);

      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        kind: PLANNED_CARE_KIND_INDETERMINATE_PENDING,
        health_entry_id: entryRow.id,
        next_due_date: null,
      });
      expect(rows[0].reason).toBeTruthy();
      expect(rows[0].certainty).toBe(CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION);
    });

    // Test case 5: sort order asserted across a mixed-kind fixture.
    it('sorts rows by kind bucket order then locale-aware name', () => {
      const calendarEntry = entry({
        id: 'entry-calendar',
        name: 'Zebra vaccine',
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
      });
      const chainEntry = entry({
        id: 'entry-chain',
        name: 'Amoxicillin',
        frequency: 'weekly',
        recurrence_anchor: 'from_completion',
        next_due_date: '2026-08-12',
      });
      const onceEntryA = entry({
        id: 'entry-once-b',
        name: 'Bath',
        frequency: 'once',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-13',
      });
      const indeterminateEntry = entry({
        id: 'entry-indeterminate',
        name: 'Anti-nausea',
        frequency: 'weekly',
        recurrence_anchor: 'from_completion',
        next_due_date: '2026-08-05',
      });

      const entries = [calendarEntry, chainEntry, onceEntryA, indeterminateEntry];
      const occurrencesByEntryId = new Map(entries.map((e) => [e.id, []]));
      const projection = projectAll(entries, occurrencesByEntryId, '2026-08-12', '2026-08-19');
      const entriesById = new Map(entries.map((e) => [e.id, e]));

      const rows = buildPlannedCareItems(projection.items, projection.uncertainties, entriesById);

      expect(rows.map((row) => [row.kind, row.name])).toEqual([
        [PLANNED_CARE_KIND_RECURRING_CALENDAR, 'Zebra vaccine'],
        [PLANNED_CARE_KIND_RECURRING_CHAIN, 'Amoxicillin'],
        [PLANNED_CARE_KIND_SINGLE_ONCE, 'Bath'],
        [PLANNED_CARE_KIND_INDETERMINATE_PENDING, 'Anti-nausea'],
      ]);
    });
  });

  describe('formatProjectionReadContract', () => {
    // Test case 6: raw items[] stays on the wire, unchanged, alongside planned_care_items.
    it('keeps the raw items[] array unchanged and adds planned_care_items, removing the old fields', () => {
      const entryRow = entry({
        frequency: 'daily',
        recurrence_anchor: 'from_completion',
      });
      const projection = projectOne(
        entryRow,
        [{
          id: 'occ-1',
          health_entry_id: entryRow.id,
          scheduled_date: '2026-08-05',
          scheduled_time: null,
          status: 'pending',
        }],
        '2026-08-12',
        '2026-08-19'
      );

      const formatted = formatProjectionReadContract(projection, [entryRow]);

      expect(formatted.items).toEqual(projection.items);
      expect(formatted.items).toHaveLength(0);
      expect(formatted.planned_care_items).toHaveLength(1);
      expect(formatted.planned_care_items[0]).toMatchObject({
        kind: PLANNED_CARE_KIND_INDETERMINATE_PENDING,
        health_entry_id: entryRow.id,
        name: 'Daily pill',
        type: 'medication',
        care_family: 'medication',
      });
      expect(formatted.uncertainties).toBeUndefined();
      expect(formatted.routine_items).toBeUndefined();
      expect(formatted.dated_items).toBeUndefined();
    });

    it('preserves projection_status and other top-level fields untouched', () => {
      const entryRow = entry({
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
      });
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-19');

      const formatted = formatProjectionReadContract(projection, [entryRow]);

      expect(formatted.starts_on).toBe('2026-08-12');
      expect(formatted.ends_on).toBe('2026-08-19');
      expect(formatted.projection_status).toBe(projection.projection_status);
    });
  });
});
