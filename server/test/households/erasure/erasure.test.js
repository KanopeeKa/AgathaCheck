import { describe, expect, it, jest } from '@jest/globals';

import { pickHouseholdSuccessor } from '../../../lib/households/erasure/pickHouseholdSuccessor.js';
import { releaseHouseholdsForDepartingUser } from '../../../lib/households/erasure/releaseHouseholdsForDepartingUser.js';
import { HOUSEHOLD_TIER_FULL, HOUSEHOLD_TIER_LOG } from '../../../lib/households/constants.js';

describe('pickHouseholdSuccessor', () => {
  it('prefers longest-standing full_access member', async () => {
    const client = {
      query: jest.fn(async (sql, params) => {
        if (params?.[1] === HOUSEHOLD_TIER_FULL) {
          return { rows: [{ user_id: 'full-1' }] };
        }
        return { rows: [] };
      }),
    };
    const id = await pickHouseholdSuccessor(client, 'hh-1');
    expect(id).toBe('full-1');
  });

  it('falls back to can_log_care when no full_access remains', async () => {
    const client = {
      query: jest.fn(async (sql, params) => {
        if (params?.[1] === HOUSEHOLD_TIER_FULL) {
          return { rows: [] };
        }
        if (params?.[1] === HOUSEHOLD_TIER_LOG) {
          return { rows: [{ user_id: 'log-1' }] };
        }
        return { rows: [] };
      }),
    };
    const id = await pickHouseholdSuccessor(client, 'hh-1');
    expect(id).toBe('log-1');
  });
});

describe('releaseHouseholdsForDepartingUser', () => {
  it('closes a household when no members remain', async () => {
    let closed = false;
    const client = {
      query: jest.fn(async (sql) => {
        const s = sql.replace(/\s+/g, ' ');
        if (s.includes('SELECT name FROM households')) {
          return { rows: [{ name: 'Home' }] };
        }
        if (s.includes('count(*)') && s.includes('household_members')) {
          return { rows: [{ c: 0 }] };
        }
        if (s.includes('FROM household_pets hp') && s.includes('WHERE hp.household_id')) {
          return { rows: [] };
        }
        if (s.includes('DELETE FROM households')) {
          closed = true;
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    const result = await releaseHouseholdsForDepartingUser(client, {
      memberships: [{ household_id: 'hh-1' }],
    });
    expect(closed).toBe(true);
    expect(result.promotions).toEqual([]);
  });

  it('promotes a successor when no organiser remains', async () => {
    let promoted = false;
    const client = {
      query: jest.fn(async (sql, params) => {
        const s = sql.replace(/\s+/g, ' ');
        if (s.includes('SELECT name FROM households')) {
          return { rows: [{ name: 'Team' }] };
        }
        if (s.includes('count(*)') && s.includes('is_organiser = true')) {
          return { rows: [{ c: 0 }] };
        }
        if (s.includes('count(*)') && s.includes('household_members')) {
          return { rows: [{ c: 2 }] };
        }
        if (params?.[1] === HOUSEHOLD_TIER_FULL) {
          return { rows: [{ user_id: 'succ-1' }] };
        }
        if (s.includes('UPDATE household_members') && s.includes('is_organiser = true')) {
          promoted = params[1] === 'succ-1';
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    const result = await releaseHouseholdsForDepartingUser(client, {
      memberships: [{ household_id: 'hh-1', is_organiser: true }],
    });
    expect(promoted).toBe(true);
    expect(result.promotions).toEqual([{
      householdId: 'hh-1',
      householdName: 'Team',
      promotedUserId: 'succ-1',
    }]);
  });
});
