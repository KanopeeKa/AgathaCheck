import { describe, expect, it } from '@jest/globals';

import { planWronglyClosedReopens, pickKeeper } from '../../lib/care/repair/tzShiftRepair.js';

const dailyEntry = {
  care_planning: 'planned',
  frequency: 'daily',
  next_due_date: '2026-06-01',
  schedule_times: ['08:00'],
};

function row(id, overrides = {}) {
  return {
    id,
    status: 'skipped',
    close_reason: 'not_recorded',
    scheduled_date: '2026-06-01',
    scheduled_time: '08:00:00',
    series_date: '2026-06-01',
    marked_by_user_id: null,
    origin: 'schedule',
    ...overrides,
  };
}

describe('planWronglyClosedReopens (D2)', () => {
  it('does not reopen rows slated for D1 deletion', () => {
    const keeper = row('keep');
    const dup = row('dup');
    const reopened = planWronglyClosedReopens({
      entry: dailyEntry,
      rows: [keeper, dup],
      deletedIds: ['dup'],
      todayIso: '2026-06-02',
    });
    expect(reopened).toEqual(['keep']);
    expect(reopened).not.toContain('dup');
  });

  it('reopens at most one row per slot when a duplicate could not be deleted', () => {
    const a = row('aaa');
    const b = row('bbb');
    const reopened = planWronglyClosedReopens({
      entry: dailyEntry,
      rows: [a, b],
      deletedIds: [],
      todayIso: '2026-06-02',
    });
    expect(reopened).toHaveLength(1);
    expect(reopened[0]).toBe(pickKeeper([a, b]).id);
  });

  it('skips slots that already have a pending row', () => {
    const closed = row('closed');
    const pending = row('open', { status: 'pending', close_reason: null });
    const reopened = planWronglyClosedReopens({
      entry: dailyEntry,
      rows: [closed, pending],
      deletedIds: [],
      todayIso: '2026-06-02',
    });
    expect(reopened).toEqual([]);
  });
});
