import { describe, expect, it } from '@jest/globals';
import { isCareItemAffectedByAbsence } from '../../../lib/care/absence/affectedCareItem.js';

describe('isCareItemAffectedByAbsence', () => {
  it('is true for in-window rows', () => {
    expect(
      isCareItemAffectedByAbsence({
        in_window: { count: 1 },
        open_occurrence: null,
      })
    ).toBe(true);
  });

  it('is true for overdue and due-before-absence open work', () => {
    expect(
      isCareItemAffectedByAbsence({
        in_window: null,
        open_occurrence: { open_status: 'overdue' },
      })
    ).toBe(true);
    expect(
      isCareItemAffectedByAbsence({
        in_window: null,
        open_occurrence: { open_status: 'due_before_absence' },
      })
    ).toBe(true);
  });

  it('is false for paused items without in-window dates', () => {
    expect(
      isCareItemAffectedByAbsence({
        is_paused: true,
        in_window: null,
        open_occurrence: { open_status: 'overdue' },
      })
    ).toBe(false);
  });
});
