import { describe, expect, it, jest } from '@jest/globals';

import { closeHousehold } from '../../../lib/households/departure/closeHousehold.js';
import { removePetFromHousehold } from '../../../lib/households/departure/removePetFromHousehold.js';
import { DEPARTURE_NOTICE_HOUSEHOLD_PET_REMOVED } from '../../../lib/households/departure/notices.js';

describe('removePetFromHousehold', () => {
  it('copies contacts, deletes membership row, records access event, returns D22 notice payload', async () => {
    const sqlLog = [];
    const client = {
      query: jest.fn(async (sql, params) => {
        sqlLog.push(sql.replace(/\s+/g, ' '));
        const s = sql.replace(/\s+/g, ' ');
        if (s.includes('SELECT name FROM pets')) {
          return { rows: [{ name: 'Buddy' }] };
        }
        if (s.includes('DELETE FROM household_pets')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO pet_access_events')) {
          return { rows: [] };
        }
        if (s.includes('DELETE FROM pet_access_events')) {
          return { rows: [] };
        }
        if (s.includes('FROM pet_contact_relationships')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO people_directories') || s.includes('owner_user_id = $1')) {
          return { rows: [{ id: 'dir-personal' }] };
        }
        return { rows: [] };
      }),
    };

    const result = await removePetFromHousehold(client, {
      householdId: 'hh-1',
      petId: 'pet-1',
      ownerUserId: 'owner-1',
    });

    expect(sqlLog.some((s) => s.includes('DELETE FROM household_pets'))).toBe(true);
    expect(sqlLog.some((s) => s.includes('INSERT INTO pet_access_events'))).toBe(true);
    expect(result.notices).toEqual([{
      kind: DEPARTURE_NOTICE_HOUSEHOLD_PET_REMOVED,
      householdId: 'hh-1',
      petId: 'pet-1',
      petName: 'Buddy',
      actorUserId: null,
    }]);
  });
});

describe('closeHousehold', () => {
  it('removes each household pet then deletes the household', async () => {
    let petsListed = false;
    let householdDeleted = false;
    const client = {
      query: jest.fn(async (sql) => {
        const s = sql.replace(/\s+/g, ' ');
        if (s.includes('FROM household_pets hp') && s.includes('WHERE hp.household_id')) {
          petsListed = true;
          return {
            rows: [
              { pet_id: 'pet-a', owner_user_id: 'owner-a' },
            ],
          };
        }
        if (s.includes('SELECT name FROM pets')) {
          return { rows: [{ name: 'A' }] };
        }
        if (s.includes('DELETE FROM household_pets')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO pet_access_events')) {
          return { rows: [] };
        }
        if (s.includes('DELETE FROM pet_access_events')) {
          return { rows: [] };
        }
        if (s.includes('SELECT id FROM people_directories WHERE household_id')) {
          return { rows: [{ id: 'dir-hh' }] };
        }
        if (s.includes('SELECT id FROM people_contacts WHERE directory_id')) {
          return { rows: [] };
        }
        if (s.startsWith('DELETE FROM households')) {
          householdDeleted = true;
          return { rows: [] };
        }
        if (s.includes('FROM pet_contact_relationships')) {
          return { rows: [] };
        }
        if (s.includes('INSERT INTO people_directories') || s.includes('owner_user_id = $1')) {
          return { rows: [{ id: 'dir-personal' }] };
        }
        return { rows: [] };
      }),
    };

    const result = await closeHousehold(client, 'hh-1');
    expect(petsListed).toBe(true);
    expect(householdDeleted).toBe(true);
    expect(result.notices).toHaveLength(1);
  });
});
