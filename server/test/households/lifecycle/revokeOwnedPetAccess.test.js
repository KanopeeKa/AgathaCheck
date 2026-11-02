import { describe, expect, it, jest } from '@jest/globals';

import { revokeRemoveAllAccessToMyPets } from '../../../lib/households/lifecycle/revokeOwnedPetAccess.js';

describe('revokeRemoveAllAccessToMyPets', () => {
  it('deletes direct shares and revokes active absence grants on all organiser pets', async () => {
    const sqlLog = [];
    const client = {
      query: jest.fn(async (sql, params) => {
        sqlLog.push(sql.replace(/\s+/g, ' '));
        if (sql.includes('SELECT id AS pet_id FROM pets')) {
          return { rows: [{ pet_id: 'pet-1' }, { pet_id: 'pet-2' }] };
        }
        if (sql.includes('DELETE FROM pet_access')) {
          return { rows: [{ id: 'grant-1' }] };
        }
        if (sql.includes('UPDATE planned_absence_guest_grants')) {
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    await revokeRemoveAllAccessToMyPets(client, 'org-1', 'target-1');

    expect(sqlLog.filter((s) => s.includes('DELETE FROM pet_access'))).toHaveLength(2);
    expect(sqlLog.filter((s) => s.includes('UPDATE planned_absence_guest_grants'))).toHaveLength(2);
  });
});
