import {
  CARER_STATE_SET,
  CARER_STATE_UNAVAILABLE,
  CARER_STATE_UNSET,
  deriveCarerState,
  enrichAbsencePetCarerContacts,
} from '../../lib/people/absenceCarer.js';
import {
  deriveCarerCoverage,
  petHasCarer,
} from '../../lib/care/awayPlan/readiness.js';
import { petId } from '../pets/helpers.js';

describe('deriveCarerState', () => {
  it('marks shared_user without user id unavailable', () => {
    expect(deriveCarerState({
      pet_id: petId,
      carer_kind: 'shared_user',
      carer_user_id: null,
    })).toBe(CARER_STATE_UNAVAILABLE);
  });

  it('marks inactive contact unavailable', () => {
    expect(deriveCarerState({
      pet_id: petId,
      carer_kind: 'note_only',
      carer_name: 'Tom',
      contact_id: 'c-1',
      contact_inactive: true,
    })).toBe(CARER_STATE_UNAVAILABLE);
  });

  it('marks assigned note_only as set', () => {
    expect(deriveCarerState({
      pet_id: petId,
      carer_kind: 'note_only',
      carer_name: 'Tom',
    })).toBe(CARER_STATE_SET);
  });

  it('marks unset when no carer_kind', () => {
    expect(deriveCarerState({ pet_id: petId })).toBe(CARER_STATE_UNSET);
  });
});

describe('deriveCarerCoverage unavailable pets', () => {
  it('does not count unavailable toward all_have_carers', () => {
    const result = deriveCarerCoverage([
      {
        pet_id: petId,
        carer_kind: 'shared_user',
        carer_user_id: null,
      },
      {
        pet_id: 'pet-2',
        carer_kind: 'note_only',
        carer_name: 'Jamie',
      },
    ]);
    expect(result.state).toBe('some_have_carers');
    expect(result.unavailable_pet_ids).toEqual([petId]);
    expect(petHasCarer({
      pet_id: 'pet-2',
      carer_kind: 'note_only',
      carer_name: 'Jamie',
    })).toBe(true);
  });
});

describe('enrichAbsencePetCarerContacts', () => {
  it('flags missing contacts', async () => {
    const pool = {
      query: async () => ({ rows: [] }),
    };
    const enriched = await enrichAbsencePetCarerContacts(pool, [{
      pet_id: petId,
      carer_kind: 'note_only',
      carer_name: 'Tom',
      contact_id: 'missing-id',
    }]);
    expect(enriched[0].contact_missing).toBe(true);
    expect(deriveCarerState(enriched[0])).toBe(CARER_STATE_UNAVAILABLE);
  });
});
