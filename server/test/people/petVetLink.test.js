import { describe, it, expect } from '@jest/globals';

import {
  reconcilePeopleVets,
  syncPetPrimaryVetFromLegacyVetId,
} from '../../lib/people/petVetLink.js';
import { createTransactionalMockPool } from '../helpers/transactionMockPool.js';

describe('petVetLink', () => {
  it('syncPetPrimaryVetFromLegacyVetId deactivates prior primary_vet when vet cleared', async () => {
    const queries = [];
    const pool = createTransactionalMockPool(async (sql, params) => {
      queries.push({ sql, params });
      if (sql.includes('FROM pet_contact_relationships pcr')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    await syncPetPrimaryVetFromLegacyVetId(pool, 'pet-1', null, 'user-1');

    expect(queries.some((q) => q.sql.includes('UPDATE pet_contact_relationships'))).toBe(
      true,
    );
    expect(queries.some((q) => q.sql.includes('FROM vets'))).toBe(false);
  });

  it('reconcilePeopleVets runs rebuildAll without error on empty data', async () => {
    const pool = {
      query: async () => ({ rows: [] }),
    };

    await expect(reconcilePeopleVets(pool)).resolves.toBeUndefined();
  });
});
