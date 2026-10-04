import { describe, expect, it } from '@jest/globals';

import { buildAbsenceCareView } from '../../../lib/care/absence/buildAbsenceCareView.js';
import { UI_STATE_NOT_REVIEWED } from '../../../lib/care/absence/constants.js';

describe('buildAbsenceCareView', () => {
  const startsOn = '2026-06-10';
  const endsOn = '2026-06-15';
  const entryId = 'entry-1';

  const baseProjection = {
    items: [{
      health_entry_id: entryId,
      scheduled_date: '2026-06-12',
      status: 'pending',
      occurrence_id: 'occ-1',
      source: 'materialised',
    }],
    planned_care_items: [{
      health_entry_id: entryId,
      name: 'Meds',
      open_occurrence: {
        occurrence_id: 'occ-head',
        scheduled_date: '2026-06-08',
        open_status: 'overdue',
      },
    }],
  };

  it('returns nothing_due when the entry has no planned row', () => {
    const view = buildAbsenceCareView({
      projection: { items: [], planned_care_items: [] },
      healthEntryId: entryId,
      startsOn,
      endsOn,
    });
    expect(view.affected).toBe(false);
    expect(view.ui_state).toBe('nothing_due');
    expect(view.planned_care).toBeNull();
    expect(view.review_occurrence).toBeNull();
  });

  it('marks affected entries and suggests keep_date when not reviewed', () => {
    const view = buildAbsenceCareView({
      projection: baseProjection,
      healthEntryId: entryId,
      startsOn,
      endsOn,
    });
    expect(view.affected).toBe(true);
    expect(view.ui_state).toBe(UI_STATE_NOT_REVIEWED);
    expect(view.suggested_decision).toBe('keep_date');
    expect(view.planned_care?.planned_dates).toHaveLength(1);
    expect(view.review_occurrence).toEqual({
      occurrence_id: 'occ-head',
      scheduled_date: '2026-06-08',
      scheduled_time: null,
    });
  });

  it('includes resolution and pet carer when provided', () => {
    const view = buildAbsenceCareView({
      projection: baseProjection,
      healthEntryId: entryId,
      startsOn,
      endsOn,
      resolutionDbRow: {
        id: 'res-1',
        health_entry_id: entryId,
        planned_absence_id: 'abs-1',
        decision: 'keep_date',
        carer_kind: 'note_only',
        carer_user_id: null,
        carer_name: 'Jamie',
        absence_note: 'Bags ready',
        dates_decided_for: ['2026-06-12'],
        created_at: new Date(),
        updated_at: new Date(),
      },
      petCarerRow: {
        carer_kind: 'note_only',
        carer_user_id: null,
        carer_name: 'Jamie',
        pet_id: 'pet-1',
      },
    });
    expect(view.resolution?.decision).toBe('keep_date');
    expect(view.pet_carer?.carer_name).toBe('Jamie');
    expect(view.planned_care?.looked_after_by?.carer_name).toBe('Jamie');
  });
});
