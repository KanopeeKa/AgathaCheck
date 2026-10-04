import { describe, expect, it, jest } from '@jest/globals';

import {
  canAttachContactToPet,
  canEditContact,
  canViewContact,
} from '../../lib/people/access.js';
import * as petAccess from '../../lib/petAccess.js';

const ownerId = 'owner-1';
const coParentId = 'co-1';
const strangerId = 'stranger-1';
const contactId = 'contact-1';
const petId = 'pet-1';

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

describe('People access policy (personal directory, s1)', () => {
  it('owner can view and edit own directory contact', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('pd.owner_user_id = $2') && sql.includes('FROM people_contacts pc')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return undefined;
      },
    ]);
    expect(await canViewContact(pool, contactId, ownerId)).toBe(true);
    expect(await canEditContact(pool, contactId, ownerId)).toBe(true);
  });

  it('co-parent can view contact related to shared pet but not edit', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('pd.owner_user_id = $2')) return { rows: [] };
        if (sql.includes('pet_contact_relationships')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return undefined;
      },
    ]);
    expect(await canViewContact(pool, contactId, coParentId)).toBe(true);
    expect(await canEditContact(pool, contactId, coParentId)).toBe(false);
  });

  it('stranger cannot view or edit', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('people_contacts')) return { rows: [] };
        return undefined;
      },
    ]);
    expect(await canViewContact(pool, contactId, strangerId)).toBe(false);
    expect(await canEditContact(pool, contactId, strangerId)).toBe(false);
  });

  it('owner can attach own contact when managing pet profile', async () => {
    jest.spyOn(petAccess, 'userCanManageProfile').mockResolvedValue(true);
    const pool = makePool([
      (sql) => {
        if (sql.includes('SELECT user_id FROM pets')) return { rows: [{ user_id: ownerId }] };
        if (sql.includes('pd.owner_user_id = $2')) return { rows: [{ '?column?': 1 }] };
        return undefined;
      },
    ]);
    expect(await canAttachContactToPet(pool, ownerId, contactId, petId)).toBe(true);
    petAccess.userCanManageProfile.mockRestore();
  });

  it('co-parent can attach owner directory contact', async () => {
    jest.spyOn(petAccess, 'userCanManageProfile').mockResolvedValue(true);
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('SELECT user_id FROM pets')) return { rows: [{ user_id: ownerId }] };
        if (sql.includes('pd.owner_user_id = $2')) {
          const viewer = params[1];
          if (viewer === ownerId) return { rows: [{ '?column?': 1 }] };
          return { rows: [] };
        }
        return undefined;
      },
    ]);
    expect(await canAttachContactToPet(pool, coParentId, contactId, petId)).toBe(true);
    petAccess.userCanManageProfile.mockRestore();
  });

  it('stranger cannot attach', async () => {
    jest.spyOn(petAccess, 'userCanManageProfile').mockResolvedValue(false);
    const pool = makePool([]);
    expect(await canAttachContactToPet(pool, strangerId, contactId, petId)).toBe(false);
    petAccess.userCanManageProfile.mockRestore();
  });
});
