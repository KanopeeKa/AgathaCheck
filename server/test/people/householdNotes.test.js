import { describe, expect, it, jest } from '@jest/globals';

import { contactDetail } from '../../lib/people/detail.js';
import { householdNoteForViewer } from '../../lib/people/householdNotes.js';

const memberId = 'member-1';
const linkedUserId = 'linked-user';
const contactId = 'contact-1';
const householdId = 'hh-1';

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

describe('Household notes visibility (I10)', () => {
  it('returns note for household member', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('FROM household_members')) {
          return { rows: [{ access_tier: 'full_access', is_organiser: false }] };
        }
        if (sql.includes('people_contact_household_notes')) {
          return { rows: [{ note: 'Uses side gate' }] };
        }
        return undefined;
      },
    ]);
    const note = await householdNoteForViewer(pool, contactId, householdId, memberId, null);
    expect(note).toBe('Uses side gate');
  });

  it('hides note from linked person', async () => {
    const pool = makePool([]);
    const note = await householdNoteForViewer(
      pool,
      contactId,
      householdId,
      linkedUserId,
      linkedUserId,
    );
    expect(note).toBeNull();
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('hides note from non-member', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('FROM household_members')) return { rows: [] };
        return undefined;
      },
    ]);
    const note = await householdNoteForViewer(pool, contactId, householdId, 'stranger', null);
    expect(note).toBeNull();
  });

  it('contactDetail includes household_note for member', async () => {
    const pool = makePool([
      (sql, params) => {
        if (sql.includes('pd.owner_user_id = $2') && sql.includes('household_members')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('pd.household_id, pd.owner_user_id')) {
          return { rows: [{ household_id: householdId, owner_user_id: null }] };
        }
        if (sql.includes('FROM household_members') && params?.[0] === householdId) {
          return { rows: [{ access_tier: 'full_access' }] };
        }
        if (sql.includes('people_contact_household_notes')) {
          return { rows: [{ note: 'House note' }] };
        }
        if (sql.includes('FROM people_contacts pc') && sql.includes('directory_household_id')) {
          return {
            rows: [{
              id: contactId,
              directory_id: 'dir-1',
              directory_household_id: householdId,
              kind: 'person',
              name: 'Sam',
              phone: null,
              email: null,
              address: null,
              website: null,
              works_at_contact_id: null,
              linked_user_id: null,
              inactive_at: null,
              legacy_vet_id: null,
              roles: ['sitter'],
              private_note: '',
              created_at: new Date(),
              updated_at: new Date(),
            }],
          };
        }
        if (sql.includes('listUsages') || sql.includes('health_entries')) return { rows: [] };
        if (sql.includes('usage') || sql.includes('health_occurrences')) return { rows: [{ count: 0 }] };
        if (sql.includes('planned_absence')) return { rows: [] };
        if (sql.includes('pet_contact_relationships')) return { rows: [] };
        return { rows: [] };
      },
    ]);

    const detail = await contactDetail(pool, memberId, contactId);
    expect(detail?.household_note).toBe('House note');
  });
});
