import { describe, expect, it } from '@jest/globals';

import { invariantViolationsFor } from '../../lib/care/occurrence/repair.js';

describe('invariantViolationsFor', () => {
  it('does not report INV-5 on a closed item with no open dates', () => {
    const entry = {
      status: 'closed',
      care_planning: 'planned',
      next_due_date: '2099-01-01',
    };
    expect(invariantViolationsFor(entry, [])).toEqual([]);
  });

  it('reports INV-4 when a closed item still has open dates', () => {
    const entry = { status: 'closed', care_planning: 'planned', next_due_date: null };
    const open = [{ scheduled_date: '2026-01-01', origin: 'schedule' }];
    expect(invariantViolationsFor(entry, open)).toEqual(['INV-4']);
  });

  it('reports INV-5 only for open items when next_due drifts', () => {
    const entry = { status: 'active', care_planning: 'planned', next_due_date: '2026-06-10' };
    const open = [{ scheduled_date: '2026-06-01', origin: 'schedule' }];
    expect(invariantViolationsFor(entry, open)).toEqual(['INV-5']);
  });
});
