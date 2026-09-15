import { describe, expect, it } from '@jest/globals';

import {
  CERTAINTY_COMPLETE,
  CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION,
  UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
  projectSchedule,
} from '../../lib/care/schedule/projectSchedule.js';
import {
  enrichUncertainties,
  formatProjectionReadContract,
  leastCertain,
  splitRoutineAndDatedItems,
} from '../../lib/care/awayPlan/index.js';

const ENTRY_ID = 'entry-1';

function entry(overrides = {}) {
  return {
    id: ENTRY_ID,
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

function projectOne(entryRow, occurrences, startsOn, endsOn, todayIso = '2026-08-01') {
  const map = new Map([[entryRow.id, occurrences]]);
  return projectSchedule([entryRow], map, startsOn, endsOn, todayIso);
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

  describe('enrichUncertainties', () => {
    it('adds name, type, and care_family from the entry row', () => {
      const entriesById = new Map([[ENTRY_ID, entry({ name: 'Evening meds', type: 'supplement' })]]);
      const enriched = enrichUncertainties(
        [{ health_entry_id: ENTRY_ID, reason: UNCERTAINTY_REASON_FROM_COMPLETION_PENDING }],
        entriesById
      );

      expect(enriched).toEqual([
        {
          health_entry_id: ENTRY_ID,
          reason: UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
          name: 'Evening meds',
          type: 'supplement',
          care_family: 'medication',
        },
      ]);
    });
  });

  describe('splitRoutineAndDatedItems', () => {
    it('collapses daily items into routine rows with least-certain certainty', () => {
      const entryRow = entry({
        frequency: 'daily',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
      });
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-14');
      const entriesById = new Map([[ENTRY_ID, entryRow]]);

      const { routine_items, dated_items } = splitRoutineAndDatedItems(
        projection.items,
        entriesById
      );

      expect(dated_items).toHaveLength(0);
      expect(routine_items).toHaveLength(1);
      expect(routine_items[0]).toMatchObject({
        health_entry_id: ENTRY_ID,
        name: 'Daily pill',
        type: 'medication',
        care_family: 'medication',
        occurrence_count: 3,
        certainty: CERTAINTY_COMPLETE,
        first_scheduled_date: '2026-08-12',
        last_scheduled_date: '2026-08-14',
      });
    });

    it('keeps non-daily items in dated_items', () => {
      const entryRow = entry({
        frequency: 'monthly',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-14',
      });
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-19');
      const entriesById = new Map([[ENTRY_ID, entryRow]]);

      const { routine_items, dated_items } = splitRoutineAndDatedItems(
        projection.items,
        entriesById
      );

      expect(routine_items).toHaveLength(0);
      expect(dated_items).toHaveLength(1);
      expect(dated_items[0].scheduled_date).toBe('2026-08-14');
    });

    it('uses least-certain certainty when daily constituents differ', () => {
      const completeEntry = entry({
        id: 'entry-complete',
        name: 'Morning pill',
        frequency: 'daily',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
      });
      const conditionalEntry = entry({
        id: 'entry-conditional',
        name: 'Evening pill',
        frequency: 'daily',
        recurrence_anchor: 'from_completion',
        next_due_date: '2026-08-12',
      });
      const map = new Map([['entry-complete', []], ['entry-conditional', []]]);
      const projection = projectSchedule(
        [completeEntry, conditionalEntry],
        map,
        '2026-08-12',
        '2026-08-13',
        '2026-08-01'
      );
      const entriesById = new Map([
        ['entry-complete', completeEntry],
        ['entry-conditional', conditionalEntry],
      ]);

      const { routine_items } = splitRoutineAndDatedItems(projection.items, entriesById);
      const conditionalRow = routine_items.find((row) => row.health_entry_id === 'entry-conditional');

      expect(conditionalRow.certainty).toBe(CERTAINTY_CONDITIONAL_ON_FUTURE_COMPLETION);
    });

    it('creates separate routine rows per scheduled time', () => {
      const entryRow = entry({
        frequency: 'daily',
        recurrence_anchor: 'from_due_date',
        next_due_date: '2026-08-12',
        schedule_times: ['08:00', '20:00'],
      });
      const projection = projectOne(entryRow, [], '2026-08-12', '2026-08-13');
      const entriesById = new Map([[ENTRY_ID, entryRow]]);

      const { routine_items } = splitRoutineAndDatedItems(projection.items, entriesById);

      expect(routine_items).toHaveLength(2);
      expect(routine_items.map((row) => row.scheduled_time).sort()).toEqual(['08:00', '20:00']);
      expect(routine_items.every((row) => row.occurrence_count === 2)).toBe(true);
    });
  });

  describe('formatProjectionReadContract', () => {
    it('enriches uncertainties without items and splits presentation rows', () => {
      const entryRow = entry({
        frequency: 'daily',
        recurrence_anchor: 'from_completion',
      });
      const projection = projectOne(
        entryRow,
        [{
          id: 'occ-1',
          health_entry_id: ENTRY_ID,
          scheduled_date: '2026-08-05',
          scheduled_time: null,
          status: 'pending',
        }],
        '2026-08-12',
        '2026-08-19'
      );

      const formatted = formatProjectionReadContract(projection, [entryRow]);

      expect(formatted.items).toHaveLength(0);
      expect(formatted.uncertainties).toEqual([
        {
          health_entry_id: ENTRY_ID,
          reason: UNCERTAINTY_REASON_FROM_COMPLETION_PENDING,
          name: 'Daily pill',
          type: 'medication',
          care_family: 'medication',
        },
      ]);
      expect(formatted.routine_items).toEqual([]);
      expect(formatted.dated_items).toEqual([]);
    });
  });
});
