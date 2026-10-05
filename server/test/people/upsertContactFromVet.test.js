import { describe, it, expect } from '@jest/globals';

import { upsertContactFromVet } from '../../lib/people/vetSync.js';

function wrapPool(queryImpl) {
  const clientQuery = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [], command: sql };
    }
    return queryImpl(sql, params);
  };
  return {
    query: clientQuery,
    connect: async () => ({ query: clientQuery, release: () => {} }),
  };
}

describe('upsertContactFromVet', () => {
  it('does not overwrite private note when contact already exists', async () => {
    const noteUpserts = [];
    const pool = wrapPool(async (sql, params) => {
        if (sql.includes('people_directories')) {
          return { rows: [{ id: 'dir-1' }] };
        }
        if (sql.includes('SELECT id FROM people_contacts WHERE legacy_vet_id')) {
          return { rows: [{ id: 'contact-1' }] };
        }
        if (sql.includes('UPDATE people_contacts')) {
          return { rows: [] };
        }
        if (sql.includes('people_contact_private_notes')) {
          noteUpserts.push(params);
          return { rows: [] };
        }
        return { rows: [] };
    });

    await upsertContactFromVet(
      pool,
      {
        id: 'vet-1',
        name: 'Dr Adams',
        clinic: 'Greenhill',
        phone: '1',
        email: 'a@b.com',
        address: '1 High St',
        website: '',
        notes: 'Reception note',
      },
      'user-1',
    );

    expect(noteUpserts.length).toBe(0);
  });

  it('sets private note on first insert from vet', async () => {
    const noteUpserts = [];
    const pool = wrapPool(async (sql, params) => {
        if (sql.includes('people_directories')) {
          return { rows: [{ id: 'dir-1' }] };
        }
        if (sql.includes('SELECT id FROM people_contacts WHERE legacy_vet_id')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO people_contacts')) {
          return { rows: [] };
        }
        if (sql.includes('people_contact_private_notes')) {
          noteUpserts.push(params);
          return { rows: [] };
        }
        if (sql.includes('people_contact_roles')) {
          return { rows: [] };
        }
        return { rows: [] };
    });

    await upsertContactFromVet(
      pool,
      {
        id: 'vet-2',
        name: 'Dr Adams',
        clinic: 'Greenhill',
        phone: '',
        email: '',
        address: '',
        website: '',
        notes: 'Reception note',
      },
      'user-1',
    );

    expect(noteUpserts.length).toBe(1);
  });
});
