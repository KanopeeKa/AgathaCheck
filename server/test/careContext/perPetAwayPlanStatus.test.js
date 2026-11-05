import {
  derivePerPetAwayPlanStatus,
  PET_STATUS_COPY_NO_CARER,
  PET_STATUS_COPY_REVIEW_COUNT,
  PET_STATUS_PRIORITY_CARER_GAP,
  PET_STATUS_PRIORITY_CARE_REVIEW,
  PET_STATUS_PRIORITY_NONE,
} from '../../lib/care/awayPlan/derivePerPetAwayPlanStatus.js';
import { COVERAGE_STATE_HAS_ITEMS_TO_REVIEW } from '../../lib/care/carePeriodCoverage.js';

describe('derivePerPetAwayPlanStatus', () => {
  it('prefers carer gap when carer unset', () => {
    const status = derivePerPetAwayPlanStatus(
      { pet_id: 'p1', carer_kind: null },
      { review_care_item_count: 3 },
    );
    expect(status.priority).toBe(PET_STATUS_PRIORITY_CARER_GAP);
    expect(status.copy_key).toBe(PET_STATUS_COPY_NO_CARER);
  });

  it('prefers carer gap over review count when carer unavailable', () => {
    const status = derivePerPetAwayPlanStatus(
      {
        pet_id: 'p1',
        carer_kind: 'shared_user',
        carer_user_id: null,
      },
      { review_care_item_count: 2 },
    );
    expect(status.priority).toBe(PET_STATUS_PRIORITY_CARER_GAP);
  });

  it('surfaces review count when carer is set', () => {
    const status = derivePerPetAwayPlanStatus(
      {
        pet_id: 'p1',
        carer_kind: 'note_only',
        carer_name: 'Sam',
      },
      {
        review_care_item_count: 2,
        coverage_state: COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
      },
    );
    expect(status.priority).toBe(PET_STATUS_PRIORITY_CARE_REVIEW);
    expect(status.copy_key).toBe(PET_STATUS_COPY_REVIEW_COUNT);
    expect(status.copy_params).toEqual({ count: 2 });
  });

  it('returns none when carer set and nothing to review', () => {
    const status = derivePerPetAwayPlanStatus(
      {
        pet_id: 'p1',
        carer_kind: 'note_only',
        carer_name: 'Sam',
      },
      { review_care_item_count: 0 },
    );
    expect(status.priority).toBe(PET_STATUS_PRIORITY_NONE);
    expect(status.copy_key).toBeNull();
  });
});
