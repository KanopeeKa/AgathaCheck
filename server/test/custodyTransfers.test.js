import {
  requestCustodyTransfer,
  acceptCustodyTransfer,
  TRANSFER_INDIVIDUAL,
  TRANSFER_ORG_TO_ORG,
} from '../lib/custodyTransfers.js';

const petId = 'pet-1';
const orgId = 'org-1';
const userId = 'user-1';
const recipientId = 'recipient-1';
const toOrgId = 'org-2';

function makePool(state = {}) {
  const queries = [];
  const handler = async (sql, params) => {
    queries.push({ sql, params });
    if (sql.includes('SELECT * FROM pets WHERE id = $1') && !sql.includes('FOR UPDATE')) {
      return {
        rows: [{
          id: petId,
          name: 'Max',
          species: 'dog',
          organization_id: state.orgId ?? orgId,
          user_id: state.petUserId ?? 'owner-1',
          vet_id: null,
        }],
      };
    }
    if (sql.includes('SELECT 1 FROM custody_transfers WHERE pet_id')) {
      return { rows: state.pendingTransfer ? [{ '?column?': 1 }] : [] };
    }
    if (sql.includes('SELECT 1 FROM organization_users') && sql.includes('super_admin')) {
      return { rows: state.isAdmin === false ? [] : [{ '?column?': 1 }] };
    }
    if (sql.includes('SELECT 1 FROM org_connections')) {
      return { rows: state.hasConnection === false ? [] : [{ '?column?': 1 }] };
    }
    if (sql.includes('org_low_id')) {
      return { rows: state.hasConnection === false ? [] : [{ id: 'conn-1' }] };
    }
    if (sql.includes('INSERT INTO custody_transfers')) {
      return { rows: [] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users')) {
      return { rows: [{ first_name: 'Test', last_name: 'User', email: 't@example.com' }] };
    }
    if (sql.includes('SELECT user_id FROM organization_users')) {
      return { rows: [{ user_id: 'admin-2' }] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
      return { rows: [] };
    }
    if (sql.includes('FOR UPDATE')) {
      return {
        rows: [{
          id: 'transfer-1',
          pet_id: petId,
          transfer_kind: state.transferKind || TRANSFER_INDIVIDUAL,
          from_org_id: orgId,
          to_user_id: recipientId,
          to_org_id: toOrgId,
          status: 'pending',
          notes: '',
        }],
      };
    }
    if (sql.includes('INSERT INTO archived_pets')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE custody_transfers')) return { rows: [] };
    if (sql.includes('UPDATE pets SET')) return { rows: [] };
    if (sql.includes('UPDATE foster_placements')) return { rows: [] };
    if (sql.includes('DELETE FROM pet_access')) return { rows: [] };
    if (sql.includes('DELETE FROM org_pet_home_hidden')) return { rows: [] };
    if (sql.includes('DELETE FROM archived_pets')) return { rows: [] };
    if (sql.includes('health_entries')) return { rows: [] };
    if (sql.includes('weight_entries')) return { rows: [] };
    if (sql.includes('INSERT INTO notifications')) return { rows: [] };
    return { rows: [] };
  };

  return {
    query: handler,
    queries,
    connect: async () => ({ query: handler, release: () => {} }),
  };
}

describe('custodyTransfers', () => {
  it('creates pending individual guardianship transfer', async () => {
    const pool = makePool();
    const result = await requestCustodyTransfer(pool, {
      petId,
      transferKind: TRANSFER_INDIVIDUAL,
      requestedByUserId: userId,
      requestingOrgId: orgId,
      toUserId: recipientId,
    });
    expect(result.status).toBe('pending');
    expect(pool.queries.some((q) => q.sql.includes('INSERT INTO custody_transfers'))).toBe(true);
  });

  it('rejects org-to-org transfer without connection', async () => {
    const pool = makePool({ hasConnection: false });
    await expect(requestCustodyTransfer(pool, {
      petId,
      transferKind: TRANSFER_ORG_TO_ORG,
      requestedByUserId: userId,
      requestingOrgId: orgId,
      toOrgId,
    })).rejects.toMatchObject({ statusCode: 400 });
  });

  it('accepts individual guardianship transfer for recipient', async () => {
    const pool = makePool();
    const result = await acceptCustodyTransfer(pool, 'transfer-1', recipientId);
    expect(result.accepted).toBe(true);
    expect(result.pet_id).toBe(petId);
    expect(pool.queries.some((q) => q.sql.includes('INSERT INTO archived_pets'))).toBe(true);
  });
});
