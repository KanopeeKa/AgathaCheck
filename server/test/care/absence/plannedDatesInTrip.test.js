import { describe, expect, it } from '@jest/globals';
import {
  buildReviewOccurrence,
  enrichPlannedCareForTrip,
  listPlannedDatesInTrip,
} from '../../../lib/care/absence/plannedDatesInTrip.js';

describe('plannedDatesInTrip', () => {
  const starts = '2026-06-10';
  const ends = '2026-06-15';

  it('lists pending in-window dates with occurrence ids', () => {
    const items = [
      {
        health_entry_id: 'e1',
        scheduled_date: '2026-06-12',
        status: 'pending',
        occurrence_id: 'occ-1',
        source: 'materialised',
      },
      {
        health_entry_id: 'e1',
        scheduled_date: '2026-06-20',
        status: 'pending',
        occurrence_id: 'occ-2',
      },
    ];
    expect(listPlannedDatesInTrip(items, 'e1', starts, ends)).toEqual([
      {
        scheduled_date: '2026-06-12',
        occurrence_id: 'occ-1',
        scheduled_time: null,
        source: 'materialised',
      },
    ]);
  });

  it('builds review_occurrence from open_occurrence', () => {
    const row = {
      open_occurrence: {
        occurrence_id: 'occ-head',
        scheduled_date: '2026-06-12',
        scheduled_time: '08:00',
      },
    };
    expect(buildReviewOccurrence(row)).toEqual({
      occurrence_id: 'occ-head',
      scheduled_date: '2026-06-12',
      scheduled_time: '08:00',
    });
  });

  it('enriches planned care with planned_dates and looked_after_by', () => {
    const plannedRow = { health_entry_id: 'e1', name: 'Meds' };
    const items = [{
      health_entry_id: 'e1',
      scheduled_date: '2026-06-12',
      status: 'pending',
      occurrence_id: 'occ-1',
    }];
    const resolution = {
      decision: 'keep_date',
      carer_kind: 'note_only',
      carer_user_id: null,
      carer_name: 'Jamie',
      dates_decided_for: ['2026-06-12'],
    };
    const enriched = enrichPlannedCareForTrip(
      plannedRow,
      items,
      'e1',
      starts,
      ends,
      resolution,
    );
    expect(enriched.planned_dates).toHaveLength(1);
    expect(enriched.looked_after_by).toMatchObject({
      carer_kind: 'note_only',
      carer_name: 'Jamie',
    });
  });
});
