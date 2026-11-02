import { describe, expect, it, jest } from '@jest/globals';

import { copyHouseholdContactsForPetLeave } from '../../lib/people/contactCopyOnPetLeave.js';

describe('copyHouseholdContactsForPetLeave (D23)', () => {
  it('copies household-directory contacts via contactsRepo.copyContactToPersonalDirectory', async () => {
    const updates = [];
    const client = {
      query: jest.fn(async (sql, params) => {
        const s = sql.replace(/\s+/g, ' ');
        if (s.includes('FROM pet_contact_relationships') && s.includes('pd.household_id')) {
          return {
            rows: [{
              contact_id: 'contact-hh',
              household_id: 'hh-1',
            }],
          };
        }
        if (s.includes('SELECT pd.household_id')) {
          return { rows: [{ household_id: 'hh-1' }] };
        }
        if (s.includes('FROM people_contacts pc') && s.includes('array_agg')) {
          return {
            rows: [{
              id: 'contact-hh',
              kind: 'person',
              name: 'Groomer',
              email: null,
              phone: null,
              address: null,
              website: null,
              works_at_contact_id: null,
              linked_user_id: null,
              roles: ['groomer'],
            }],
          };
        }
        if (s.includes('SELECT pc.id FROM people_contacts pc') && s.includes('lower(pc.name)')) {
          return { rows: [] };
        }
        if (s.startsWith('INSERT INTO people_contacts')) {
          updates.push(params[0]);
          return { rows: [] };
        }
        if (s.includes('UPDATE pet_contact_relationships') && s.includes('SET contact_id')) {
          updates.push(`repoint:${params[0]}`);
          return { rows: [] };
        }
        if (s.includes('FROM health_entries he') || s.includes('FROM health_occurrences')
          || s.includes('FROM planned_absence')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO people_directories') || s.includes('owner_user_id = $1')) {
          return { rows: [{ id: 'dir-personal' }] };
        }
        if (s === 'BEGIN' || s === 'COMMIT' || s === 'ROLLBACK') return { rows: [], command: s };
        return { rows: [] };
      }),
    };

    const pool = {
      totalCount: 1,
      query: jest.fn(async (sql, params) => client.query(sql, params)),
      connect: jest.fn(async () => ({
        query: client.query,
        release: jest.fn(),
      })),
    };

    await copyHouseholdContactsForPetLeave(pool, 'pet-1', 'owner-1', 'hh-1');
    expect(updates.some((u) => typeof u === 'string' && u.startsWith('repoint:'))).toBe(true);
    expect(pool.connect).toHaveBeenCalled();
  });

  it('uses the supplied transaction client without opening a nested transaction', async () => {
    const client = {
      query: jest.fn(async (sql) => {
        const s = sql.replace(/\s+/g, ' ');
        if (s.includes('FROM pet_contact_relationships')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO people_directories') || s.includes('owner_user_id = $1')) {
          return { rows: [{ id: 'dir-personal' }] };
        }
        return { rows: [] };
      }),
    };

    await copyHouseholdContactsForPetLeave(client, 'pet-1', 'owner-1', 'hh-1');
    expect(client.query).toHaveBeenCalled();
  });
});
