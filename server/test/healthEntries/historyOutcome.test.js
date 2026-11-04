import { describe, expect, it } from '@jest/globals';

import { historyToMap } from '../../routes/healthEntries/shared.js';

describe('historyToMap outcome wire', () => {
  it('exposes not_recorded for system-closed rows', () => {
    const mapped = historyToMap({
      id: 'o1',
      health_entry_id: 'e1',
      status: 'not_recorded',
      notes: '',
      due_date: '2026-06-01',
      completed_on: null,
      changed_at: new Date('2026-06-02T10:00:00Z'),
      marked_by_user_id: null,
      marked_by_name: null,
    });
    expect(mapped.outcome).toBe('not_recorded');
    expect(mapped.status).toBe('not_recorded');
  });

  it('exposes done for completed rows', () => {
    const mapped = historyToMap({
      id: 'o2',
      health_entry_id: 'e1',
      status: 'completed',
      notes: '',
      due_date: '2026-06-01',
      completed_on: '2026-06-01',
      changed_at: new Date('2026-06-01T10:00:00Z'),
      marked_by_user_id: null,
      marked_by_name: null,
    });
    expect(mapped.outcome).toBe('done');
  });
});
