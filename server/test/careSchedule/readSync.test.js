import { describe, expect, it } from '@jest/globals';

import { wouldAutoCloseAsNotRecorded, filterOpenRowsForListRead } from '../../lib/care/occurrence/readSync.js';

const entry = {
  care_planning: 'planned',
  status: 'active',
  frequency: 'daily',
  schedule_times: ['08:00', '18:00'],
  schedule_anchor_date: '2026-09-30',
  recurrence_anchor: 'from_due_date',
};

describe('readSync', () => {
  it('flags Sep 30 open rows for auto-close on 2026-10-04', () => {
    const asOf = { todayIso: '2026-10-04' };
    const row = { scheduled_date: '2026-09-30', scheduled_time: '08:00:00' };
    expect(wouldAutoCloseAsNotRecorded(entry, row, asOf)).toBe(true);
    expect(filterOpenRowsForListRead(entry, [row], asOf)).toEqual([]);
  });

  it('keeps in-window open rows', () => {
    const asOf = { todayIso: '2026-10-04' };
    const row = { scheduled_date: '2026-10-02', scheduled_time: '08:00:00' };
    expect(wouldAutoCloseAsNotRecorded(entry, row, asOf)).toBe(false);
    expect(filterOpenRowsForListRead(entry, [row], asOf)).toEqual([row]);
  });
});
