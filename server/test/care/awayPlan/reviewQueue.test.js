import { describe, expect, it } from '@jest/globals';

import { buildCareReviewQueue, impactedDateCountForReviewCard } from '../../../lib/care/awayPlan/reviewQueue.js';

describe('buildCareReviewQueue', () => {
  const window = { startsOn: '2026-10-17', endsOn: '2026-10-31' };

  it('excludes resolved items and uses in_window count', () => {
    const planned = [{
      health_entry_id: 'e1',
      name: 'Pill',
      in_window: { count: 3, first_date: '2026-10-18', last_date: '2026-10-20', date_basis: 'scheduled' },
      open_occurrence: null,
      is_paused: false,
    }];
    const projectionItems = [
      { health_entry_id: 'e1', scheduled_date: '2026-10-13', status: 'pending' },
      { health_entry_id: 'e1', scheduled_date: '2026-10-18', status: 'pending' },
    ];
    const queue = buildCareReviewQueue(
      planned,
      projectionItems,
      new Map(),
      window,
      { petHasCarer: true }
    );
    expect(queue).toHaveLength(1);
    expect(queue[0].impacted_date_count).toBe(3);
    expect(queue[0].bulk_keep_carer_eligible).toBe(true);
  });

  it('counts only in-trip pending dates when in_window missing', () => {
    const count = impactedDateCountForReviewCard(
      { health_entry_id: 'e1', in_window: null },
      [
        { health_entry_id: 'e1', scheduled_date: '2026-10-10', status: 'pending' },
        { health_entry_id: 'e1', scheduled_date: '2026-10-20', status: 'pending' },
      ],
      window.startsOn,
      window.endsOn
    );
    expect(count).toBe(1);
  });
});
