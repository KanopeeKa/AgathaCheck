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
          return { rows: [{ pet_id: 'pet-1', pet_name: 'Buddy' }] };
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
  });

});
