import { describe, expect, it, jest } from '@jest/globals';

import {
  canEditContact,
  canViewContact,
  visibleDirectoryIds,
} from '../../lib/people/access.js';
import * as petAccess from '../../lib/petAccess.js';
import { canAttachContactToPet } from '../../lib/people/access.js';

const fullMemberId = 'full-member';
const logMemberId = 'log-member';
const organiserId = 'organiser';
const householdId = 'hh-1';
const contactId = 'hh-contact';
const petId = 'pet-1';
const ownerId = 'owner-1';

function makePool(handlers) {
  return {
    query: jest.fn(async (sql, params) => {
      for (const handler of handlers) {
        const result = await handler(sql, params);
        if (result !== undefined) return result;
      }
      return { rows: [] };
    }),
  };
}

describe('People access — household directory (s5)', () => {
  it('visibleDirectoryIds includes household directory for Full access and organisers', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('owner_user_id = $1')) return { rows: [{ id: 'dir-personal' }] };
        if (sql.includes('FROM people_directories pd') && sql.includes('household_members')) {
          return { rows: [{ id: 'dir-household' }] };
        }
        return undefined;
      },
    ]);
    const ids = await visibleDirectoryIds(pool, fullMemberId);
    expect(ids).toEqual(['dir-personal', 'dir-household']);
  });

  it('Full access member can view and edit household directory contact', async () => {
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('pd.household_id, pd.owner_user_id')) {
          return { rows: [{ household_id: householdId, owner_user_id: null }] };
        }
        if (sql.includes('pd.owner_user_id = $2') && sql.includes('people_contacts')) {
          return { rows: [] };
        }
        if (sql.includes('FROM household_members') && params?.[0] === householdId) {
          const userId = params[1];
          if (userId === fullMemberId) {
            return { rows: [{ access_tier: 'full_access', is_organiser: false }] };
          }
        }
        if (sql.includes('pet_contact_relationships')) return { rows: [] };
        return undefined;
      },
    ]);
    expect(await canViewContact(pool, contactId, fullMemberId)).toBe(true);
    expect(await canEditContact(pool, contactId, fullMemberId)).toBe(true);
  });

  it('Can log care member cannot view household directory contact without pet relation', async () => {
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('pd.household_id, pd.owner_user_id')) {
          return { rows: [{ household_id: householdId, owner_user_id: null }] };
        }
        if (sql.includes('pd.owner_user_id = $2')) return { rows: [] };
        if (sql.includes('FROM household_members') && params?.[0] === householdId) {
          return { rows: [{ access_tier: 'can_log_care', is_organiser: false }] };
        }
        if (sql.includes('pet_contact_relationships')) return { rows: [] };
        return undefined;
      },
    ]);
    expect(await canViewContact(pool, contactId, logMemberId)).toBe(false);
    expect(await canEditContact(pool, contactId, logMemberId)).toBe(false);
  });

  it('organiser can attach household directory contact to household pet', async () => {
    jest.spyOn(petAccess, 'userCanManageProfile').mockResolvedValue(true);
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('SELECT user_id FROM pets')) return { rows: [{ user_id: ownerId }] };
        if (sql.includes('pd.owner_user_id = $2')) return { rows: [] };
        if (sql.includes('household_pets hp') && sql.includes('people_contacts pc')) {
          return { rows: [{ household_id: householdId }] };
        }
        if (sql.includes('FROM household_members') && params?.[0] === householdId) {
          return { rows: [{ access_tier: 'full_access', is_organiser: true }] };
        }
        return undefined;
      },
    ]);
    expect(await canAttachContactToPet(pool, organiserId, contactId, petId)).toBe(true);
    petAccess.userCanManageProfile.mockRestore();
  });
});
