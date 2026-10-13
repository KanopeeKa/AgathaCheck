import { describe, expect, it } from '@jest/globals';

import {
  groupAgendaRowsByDueDate,
  showSameDayDateHeader,
} from '../../lib/care/agenda/agendaGrouping.js';

describe('agenda grouping (AC-CO-01)', () => {
  it('groups consecutive rows by calendar due date', () => {
    const rows = [
      { id: 'a', date: '2026-06-12' },
      { id: 'b', date: '2026-06-12' },
      { id: 'c', date: '2026-06-14' },
    ];
    const groups = groupAgendaRowsByDueDate(rows);
    expect(groups).toEqual([
      { dateKey: '2026-06-12', rows: [rows[0], rows[1]] },
      { dateKey: '2026-06-14', rows: [rows[2]] },
    ]);
  });

  it('shows same-day date header only when a group has two or more rows', () => {
    expect(
      showSameDayDateHeader({ dateKey: '2026-06-12', rows: [{ date: '2026-06-12' }] }),
    ).toBe(false);
    expect(
      showSameDayDateHeader({
        dateKey: '2026-06-12',
        rows: [{ date: '2026-06-12' }, { date: '2026-06-12' }],
      }),
    ).toBe(true);
  });
});
