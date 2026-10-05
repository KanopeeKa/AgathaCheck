import { describe, expect, it } from '@jest/globals';

import { projectPet } from '../../lib/people/vetProjection.js';
import { setSlot } from '../../lib/people/relationships.js';
import { createTransactionalMockPool } from '../helpers/transactionMockPool.js';

describe('vet projection invariant I5', () => {
  it('projectPet clears pets.vet_id when primary_vet slot is empty', async () => {
    const queries = [];
    const pool = createTransactionalMockPool(async (sql, params) => {
      queries.push({ sql, params });
      if (sql.includes('LEFT JOIN pet_contact_relationships')) {
        return { rows: [{ owner_user_id: 'user-1', contact_id: null }] };
      }
      return { rows: [] };
    });

    await projectPet(pool, 'pet-1');
    const update = queries.find((q) => q.sql.includes('UPDATE pets SET vet_id'));
    expect(update.params[0]).toBeNull();
    expect(update.params[1]).toBe('pet-1');
  });

  it('setSlot with null contact clears primary vet projection', async () => {
    const queries = [];
    const pool = createTransactionalMockPool(async (sql, params) => {
      queries.push({ sql, params });
      if (sql.includes('LEFT JOIN pet_contact_relationships')) {
        return { rows: [{ owner_user_id: 'user-1', contact_id: null }] };
      }
      if (sql.includes('FROM pet_contact_relationships pcr')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    await setSlot(pool, 'pet-1', 'primary_vet', null, 'user-1');
    const update = queries.find((q) => q.sql.includes('UPDATE pets SET vet_id'));
    expect(update?.params?.[0]).toBeNull();
  });
});
