import { describe, expect, it, jest } from '@jest/globals';

import { buildRoster } from '../../lib/people/roster.js';
import { contactDetail, petPeople, relatedCare } from '../../lib/people/detail.js';
import * as absenceGuestGrants from '../../lib/people/absenceGuestGrants.js';
import * as petAccess from '../../lib/petAccess.js';

const userId = 'user-owner';
const contactId = 'contact-1';
const petId = 'pet-1';

function makePool(handlers) {
  let queryCount = 0;
  const query = jest.fn(async (sql, params) => {
    queryCount += 1;
    for (const handler of handlers) {
      const result = await handler(sql, params, queryCount);
      if (result !== undefined) return result;
    }
    return { rows: [] };
  });
  return { pool: { query }, getQueryCount: () => query.mock.calls.length };
}

describe('People read models', () => {
  it('buildRoster returns empty collections when no directories', async () => {
    const { pool } = makePool([
      (sql) => {
        if (sql.includes('people_directories WHERE owner_user_id')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO people_directories')) {
          return { rows: [{ id: 'dir-1' }] };
        }
        return undefined;
      },
    ]);
    const roster = await buildRoster(pool, userId);
    expect(roster).toEqual({
      households: [],
      contacts: [],
      pending_invites: [],
    });
  });

  it('buildRoster query count is bounded when contact count grows', async () => {
    const runCount = async (contactCount) => {
      const contacts = Array.from({ length: contactCount }, (_, i) => ({
        id: `c-${i}`,
        directory_id: 'dir-1',
        directory_household_id: null,
        kind: 'person',
        name: `Contact ${i}`,
        roles: ['sitter'],
        linked_user_id: null,
        works_at_contact_id: null,
        inactive_at: null,
      }));
      const { pool, getQueryCount } = makePool([
        (sql) => {
          if (sql.includes('people_directories WHERE owner_user_id')) {
            return { rows: [{ id: 'dir-1' }] };
          }
          if (sql.includes('pc.directory_id = ANY')) {
            return { rows: contacts };
          }
          if (sql.includes('pet_contact_relationships pcr')) return { rows: [] };
          if (sql.includes('people_contacts WHERE id = ANY')) return { rows: [] };
          if (sql.includes('planned_absence_pets pap')) return { rows: [] };
          if (sql.includes('pet_access pa')) return { rows: [] };
          if (sql.includes('household_members hm')) return { rows: [] };
          if (sql.includes('household_pets hp')) return { rows: [] };
          if (sql.includes('FROM households h')) return { rows: [] };
          if (sql.includes('pet_share_invites')) return { rows: [] };
          if (sql.includes('planned_absence_carer_invites')) return { rows: [] };
          return undefined;
        },
      ]);
      await buildRoster(pool, userId);
      return getQueryCount();
    };
    const small = await runCount(2);
    const large = await runCount(40);
    expect(large).toBe(small);
  });

  it('contactDetail returns enriched DTO shape', async () => {
    const row = {
      id: contactId,
      directory_id: 'dir-1',
      directory_household_id: null,
      owner_user_id: userId,
      kind: 'person',
      name: 'Jamie',
      phone: null,
      email: null,
      address: null,
      website: null,
      works_at_contact_id: null,
      linked_user_id: null,
      inactive_at: null,
      legacy_vet_id: null,
      roles: ['sitter'],
      private_note: 'note',
      created_at: new Date(),
      updated_at: new Date(),
    };
    const { pool } = makePool([
      (sql) => {
        if (sql.includes('pd.owner_user_id = $2') && sql.includes('WHERE pc.id = $1')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('FROM people_contacts pc') && sql.includes('WHERE pc.id = $1')) {
          return { rows: [row] };
        }
        if (sql.includes('pet_contact_relationships')) return { rows: [] };
        if (sql.includes('planned_absence_pets')) return { rows: [] };
        if (sql.includes('health_entries')) return { rows: [] };
        if (sql.includes('health_occurrences')) return { rows: [{ count: 0 }] };
        return undefined;
      },
    ]);
    const detail = await contactDetail(pool, userId, contactId);
    expect(detail).toMatchObject({
      id: contactId,
      name: 'Jamie',
      group: 'carer',
      status: 'active',
      directory: { type: 'personal', household_id: null },
      usage_counts: {},
      household_note: null,
      staff: [],
      linked_account: null,
    });
  });

  it('relatedCare returns empty related sections', async () => {
    const { pool } = makePool([
      (sql) => {
        if (sql.includes('pd.owner_user_id = $2')) return { rows: [{ '?column?': 1 }] };
        if (sql.includes('health_occurrences')) return { rows: [{ count: 0 }] };
        return { rows: [] };
      },
    ]);
    const related = await relatedCare(pool, userId, contactId);
    expect(related).toEqual({
      pets: [],
      care_items: [],
      absences: [],
      history_count: 0,
    });
  });

  it('petPeople denies stranger', async () => {
    jest.spyOn(petAccess, 'userCanManageProfile').mockResolvedValue(false);
    jest.spyOn(absenceGuestGrants, 'userHasActiveAbsenceGuestAccess').mockResolvedValue(false);
    jest.spyOn(petAccess, 'getPetAccessRole').mockResolvedValue(null);
    const { pool } = makePool([
      (sql) => {
        if (sql.includes('household_pets hp')) return { rows: [] };
        return undefined;
      },
    ]);
    const result = await petPeople(pool, 'stranger', petId);
    expect(result).toBeNull();
    petAccess.userCanManageProfile.mockRestore();
    absenceGuestGrants.userHasActiveAbsenceGuestAccess.mockRestore();
    petAccess.getPetAccessRole.mockRestore();
  });

  it('petPeople returns handover scope for carer', async () => {
    jest.spyOn(petAccess, 'userCanManageProfile').mockResolvedValue(false);
    jest.spyOn(absenceGuestGrants, 'userHasActiveAbsenceGuestAccess').mockResolvedValue(false);
    jest.spyOn(petAccess, 'getPetAccessRole').mockResolvedValue('carer');
    const { pool } = makePool([
      (sql) => {
        if (sql.includes('household_pets hp') && sql.includes('access_tier')) {
          return { rows: [] };
        }
        if (sql.includes('SELECT id, name, user_id FROM pets')) {
          return { rows: [{ id: petId, name: 'Buddy', user_id: userId }] };
        }
        if (sql.includes('FROM users WHERE id')) {
          return { rows: [{ first_name: 'Alex', last_name: 'M', email: 'a@example.com' }] };
        }
        if (sql.includes('relationship_kind = ANY')) {
          return { rows: [{ contact_id: 'vet-1' }] };
        }
        if (sql.includes('pet_contact_relationships')) {
          return {
            rows: [
              {
                id: 'rel-1',
                pet_id: petId,
                contact_id: 'vet-1',
                relationship_kind: 'primary_vet',
                is_primary: true,
                active: true,
                sort_order: 0,
                contact_kind: 'organisation',
                contact_name: 'Vet',
                contact_phone: null,
                contact_inactive_at: null,
                created_at: new Date(),
                updated_at: new Date(),
              },
              {
                id: 'rel-2',
                pet_id: petId,
                contact_id: 'other-1',
                relationship_kind: 'other',
                is_primary: false,
                active: true,
                sort_order: 1,
                contact_kind: 'person',
                contact_name: 'Other',
                contact_phone: null,
                contact_inactive_at: null,
                created_at: new Date(),
                updated_at: new Date(),
              },
            ],
          };
        }
        if (sql.includes('health_entries he')) return { rows: [] };
        if (sql.includes('planned_absence_guest_grants')) return { rows: [] };
        return undefined;
      },
    ]);
    const result = await petPeople(pool, 'carer-user', petId);
    expect(result.scope).toBe('handover');
    expect(result.household_members).toEqual([]);
    expect(result.relationships).toHaveLength(1);
    expect(result.relationships[0].relationship_kind).toBe('primary_vet');
    petAccess.userCanManageProfile.mockRestore();
    absenceGuestGrants.userHasActiveAbsenceGuestAccess.mockRestore();
    petAccess.getPetAccessRole.mockRestore();
  });
});
