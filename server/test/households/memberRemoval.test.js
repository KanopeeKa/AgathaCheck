import { describe, expect, it, jest } from '@jest/globals';

import { getHouseholdMemberRemovalPreview } from '../../lib/households/memberRemoval.js';

const householdId = 'hh-1';
const organiserId = 'org-1';
const memberId = 'mem-2';
const targetId = 'org-1';

function makePool(handlers) {
  return {
    query: jest.fn(async (sql, params) => {
      for (const handler of handlers) {
        const result = await handler(sql, params);
        if (result !== undefined) return result;
      }
      return { rows: [] };
    }),
    connect: undefined,
  };
}

describe('Household member removal (s5)', () => {
  it('removal preview lists remaining direct share access', async () => {
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('FROM household_members') && params?.[1] === organiserId) {
          return { rows: [{ is_organiser: true, access_tier: 'full_access' }] };
        }
        if (sql.includes('FROM household_members') && params?.[1] === targetId) {
          return { rows: [{ is_organiser: true, access_tier: 'full_access' }] };
        }
        if (sql.includes('FROM household_pets hp')) {
          return { rows: [{ pet_id: 'pet-1', pet_name: 'Buddy', owner_user_id: targetId }] };
        }
        if (sql.includes('FROM pet_access')) {
          return { rows: [{ role: 'co_parent' }] };
        }
        if (sql.includes('planned_absence_guest_grants')) return { rows: [] };
        if (sql.includes('is_organiser = true')) return { rows: [{ user_id: targetId }] };
        if (sql.includes('count(*)')) return { rows: [{ c: 2 }] };
        return undefined;
      },
    ]);

    const preview = await getHouseholdMemberRemovalPreview(pool, organiserId, householdId, targetId);
    expect(preview.remaining_access).toEqual([
      {
        pet_id: 'pet-1',
        pet_name: 'Buddy',
        source: 'direct_share',
        role: 'co_parent',
      },
    ]);
    expect(preview.requires_successor).toBe(true);
    expect(preview.pets_leaving).toEqual([
      { pet_id: 'pet-1', pet_name: 'Buddy' },
    ]);
    expect(preview.access_to_revoke_if_remove_all).toEqual([]);
  });

  it('organiser removal preview lists H3 grants on all owned pets', async () => {
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('FROM household_members') && params?.[1] === organiserId) {
          return { rows: [{ is_organiser: true, access_tier: 'full_access' }] };
        }
        if (sql.includes('FROM household_members') && params?.[1] === memberId) {
          return { rows: [{ is_organiser: false, access_tier: 'can_log_care' }] };
        }
        if (sql.includes('FROM household_pets hp')) {
          return { rows: [] };
        }
        if (sql.includes('FROM pets WHERE user_id')) {
          return { rows: [{ pet_id: 'pet-owned', pet_name: 'Mine' }] };
        }
        if (sql.includes('FROM pet_access')) {
          return { rows: [{ role: 'carer' }] };
        }
        if (sql.includes('planned_absence_guest_grants')) return { rows: [] };
        if (sql.includes('is_organiser = true')) return { rows: [{ user_id: organiserId }] };
        if (sql.includes('count(*)')) return { rows: [{ c: 2 }] };
        return undefined;
      },
    ]);

    const preview = await getHouseholdMemberRemovalPreview(
      pool,
      organiserId,
      householdId,
      memberId,
    );
    expect(preview.access_to_revoke_if_remove_all).toEqual([
      {
        pet_id: 'pet-owned',
        pet_name: 'Mine',
        source: 'direct_share',
        role: 'carer',
      },
    ]);
  });

  it('removal preview lists pets the target owns in the household', async () => {
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('FROM household_members') && params?.[1] === organiserId) {
          return { rows: [{ is_organiser: true, access_tier: 'full_access' }] };
        }
        if (sql.includes('FROM household_members') && params?.[1] === memberId) {
          return { rows: [{ is_organiser: false, access_tier: 'can_log_care' }] };
        }
        if (sql.includes('FROM household_pets hp')) {
          return {
            rows: [
              { pet_id: 'pet-1', pet_name: 'Buddy', owner_user_id: organiserId },
              { pet_id: 'pet-2', pet_name: 'Luna', owner_user_id: memberId },
            ],
          };
        }
        if (sql.includes('FROM pets WHERE user_id')) {
          return { rows: [{ pet_id: 'pet-1', pet_name: 'Buddy' }] };
        }
        if (sql.includes('FROM pet_access')) return { rows: [] };
        if (sql.includes('planned_absence_guest_grants')) return { rows: [] };
        if (sql.includes('is_organiser = true')) return { rows: [{ user_id: organiserId }] };
        if (sql.includes('count(*)')) return { rows: [{ c: 2 }] };
        return undefined;
      },
    ]);

    const preview = await getHouseholdMemberRemovalPreview(
      pool,
      organiserId,
      householdId,
      memberId,
    );
    expect(preview.pets_leaving).toEqual([
      { pet_id: 'pet-2', pet_name: 'Luna' },
    ]);
    expect(preview.access_to_revoke_if_remove_all).toEqual([]);
  });
});
