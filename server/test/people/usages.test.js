import { describe, expect, it } from '@jest/globals';

import { listUsages } from '../../lib/people/usages.js';

describe('listUsages', () => {
  it('aggregates active usage kinds for a contact', async () => {
    const contactId = 'contact-1';
    const pool = {
      query: async (sql, params) => {
        expect(params[0]).toBe(contactId);
        if (sql.includes('pet_contact_relationships')) {
          return { rows: [{ id: 'rel-1', pet_id: 'pet-1', relationship_kind: 'care_provider' }] };
        }
        if (sql.includes('planned_absence_pets')) {
          return { rows: [{ id: 'abs-1', pet_id: 'pet-1', starts_on: '2026-06-01', ends_on: '2026-06-10' }] };
        }
        if (sql.includes('health_entries')) {
          return { rows: [{ id: 'he-1', pet_id: 'pet-1', name: 'Vaccine' }] };
        }
        if (sql.includes('planned_absence_carer_invites')) {
          return { rows: [{ id: 'inv-1', pet_id: 'pet-1' }] };
        }
        if (sql.includes('works_at_contact_id')) {
          return { rows: [{ id: 'staff-1', name: 'Dr A' }] };
        }
        return { rows: [] };
      },
    };

    const usages = await listUsages(pool, contactId);
    expect(usages.map((u) => u.kind).sort()).toEqual([
      'absence_carer',
      'care_item_provider',
      'carer_invite',
      'pet_relationship',
      'works_at',
    ]);
    expect(usages.find((u) => u.kind === 'care_item_provider')).toMatchObject({
      id: 'he-1',
      pet_id: 'pet-1',
      label: 'Vaccine',
    });
  });
});
