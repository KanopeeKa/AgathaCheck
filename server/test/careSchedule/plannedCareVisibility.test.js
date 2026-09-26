import { describe, expect, it } from '@jest/globals';
import {
  computePreAbsenceOverdueAttention,
  filterPlannedCareItemsForAwayPlan,
  isPlannedCareRowVisibleOnAwayPlan,
} from '../../lib/care/awayPlan/plannedCareVisibility.js';

describe('plannedCareVisibility', () => {
  const window = {
    startsOn: '2026-10-25',
    endsOn: '2026-10-26',
    todayIso: '2026-09-24',
  };

  it('shows in-window rows', () => {
    const row = {
      in_window: { first_date: '2026-10-25', last_date: '2026-10-26', count: 2, date_basis: 'scheduled' },
      open_occurrence: null,
    };
    expect(isPlannedCareRowVisibleOnAwayPlan(row, window)).toBe(true);
  });

  it('hides pre-window overdue before absence starts', () => {
    const row = {
      in_window: null,
      open_occurrence: {
        scheduled_date: '2026-09-18',
        open_status: 'overdue',
      },
    };
    expect(isPlannedCareRowVisibleOnAwayPlan(row, window)).toBe(false);
  });

  it('shows stale open work once absence has started', () => {
    const row = {
      in_window: null,
      open_occurrence: {
        scheduled_date: '2026-09-18',
        open_status: 'overdue',
      },
    };
    expect(
      isPlannedCareRowVisibleOnAwayPlan(row, {
        ...window,
        todayIso: '2026-10-25',
      })
    ).toBe(true);
  });

  it('hides indeterminate rows with no in-window dates', () => {
    const row = {
      kind: 'indeterminate_pending',
      in_window: null,
      open_occurrence: null,
    };
    expect(isPlannedCareRowVisibleOnAwayPlan(row, window)).toBe(false);
  });

  it('computes pre-absence overdue attention', () => {
    const rows = [
      {
        open_occurrence: { open_status: 'overdue' },
      },
      {
        open_occurrence: { open_status: 'due_before_absence' },
      },
      {
        open_occurrence: { open_status: 'overdue' },
      },
    ];
    const attention = computePreAbsenceOverdueAttention(rows, {
      startsOn: window.startsOn,
      todayIso: window.todayIso,
    });
    expect(attention).toEqual({ show: true, overdue_count: 2 });
  });

  it('filters to visible rows only', () => {
    const rows = [
      { in_window: { count: 1 }, open_occurrence: null },
      {
        in_window: null,
        open_occurrence: { scheduled_date: '2026-09-11', open_status: 'overdue' },
      },
    ];
    expect(filterPlannedCareItemsForAwayPlan(rows, window)).toHaveLength(1);
  });
});
