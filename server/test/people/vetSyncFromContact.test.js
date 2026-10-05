import { describe, it, expect, jest } from '@jest/globals';

import { syncVetRowFromContact } from '../../lib/people/vetSync.js';

describe('syncVetRowFromContact', () => {
  it('updates vets row when contact has legacy_vet_id', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT name FROM vets')) {
          return { rows: [{ name: 'Dr. Smith' }] };
        }
        if (sql.includes('UPDATE vets')) {
          updates.push({ sql, params });
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    await syncVetRowFromContact(
      pool,
      {
        id: 'contact-1',
        legacy_vet_id: 'vet-1',
        kind: 'organisation',
        roles: ['vet'],
        name: 'Happy Paws',
        phone: '555',
        email: 'a@b.com',
        address: '1 St',
        website: 'https://x',
      },
      'user-1',
    );

    expect(updates.length).toBe(1);
    expect(updates[0].params[1]).toBe('Happy Paws');
  });
});
