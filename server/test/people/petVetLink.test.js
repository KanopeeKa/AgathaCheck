import { describe, it, expect, jest } from '@jest/globals';

import {
  reconcilePeopleVets,
  syncPetPrimaryVetFromLegacyVetId,
} from '../../lib/people/petVetLink.js';
import * as vetSync from '../../lib/people/vetSync.js';

describe('petVetLink', () => {
  it('syncPetPrimaryVetFromLegacyVetId deactivates prior primary_vet when vet cleared', async () => {
    const queries = [];
    const pool = {
      query: async (sql, params) => {
        queries.push({ sql, params });
        return { rows: [] };
      },
    };

    await syncPetPrimaryVetFromLegacyVetId(pool, 'pet-1', null, 'user-1');

    expect(queries.some((q) => q.sql.includes('UPDATE pet_contact_relationships'))).toBe(
      true,
    );
    expect(queries.some((q) => q.sql.includes('FROM vets'))).toBe(false);
  });

  it('reconcilePeopleVets upserts contacts and links pets', async () => {
    const upsertSpy = jest
      .spyOn(vetSync, 'upsertContactFromVet')
      .mockResolvedValue('contact-1');

    const pool = {
      query: async (sql) => {
        if (sql.includes('FROM vets v')) {
          return {
            rows: [
              {
                id: 'vet-1',
                user_id: 'user-1',
                name: 'Dr. Test',
                clinic: 'Clinic',
              },
            ],
          };
        }
        if (sql.includes('FROM pets p') && sql.includes('vet_id IS NOT NULL')) {
          return {
            rows: [{ pet_id: 'pet-1', vet_id: 'vet-1', owner_user_id: 'user-1' }],
          };
        }
        if (sql.includes('FROM vets WHERE id')) {
          return {
            rows: [
              {
                id: 'vet-1',
                user_id: 'user-1',
                name: 'Dr. Test',
                clinic: 'Clinic',
              },
            ],
          };
        }
        if (sql.includes('UPDATE pet_contact_relationships')) {
          return { rows: [] };
        }
        if (sql.includes('SELECT id FROM pet_contact_relationships')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO pet_contact_relationships')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    await reconcilePeopleVets(pool);

    expect(upsertSpy).toHaveBeenCalled();
    upsertSpy.mockRestore();
  });
});
