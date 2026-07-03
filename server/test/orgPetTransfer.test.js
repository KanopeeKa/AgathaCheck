import {
  transferOrgPetToUser,
  transferPetToOrganization,
} from '../lib/orgPetTransfer.js';

const orgId = 'org-1';
const petId = 'pet-1';
const adminId = 'admin-1';
const ownerId = 'owner-1';
const recipientId = 'recipient-1';

function makeTransferPool() {
  let updatedOwnerId = null;
  let updatedOrgId = null;
  let archivedRow = null;

  const handleQuery = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1 AND organization_id = $2')) {
      return { rows: [{ id: petId, name: 'Buddy', species: 'dog', user_id: ownerId, organization_id: orgId }] };
    }
    if (sql.includes('SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1 AND user_id = $2')) {
      return { rows: [{ id: petId, name: 'Buddy', species: 'dog', user_id: ownerId, organization_id: null }] };
    }
    if (sql.includes('SELECT id, first_name, last_name, email FROM users WHERE id = $1')) {
      return { rows: [{ id: params[0], first_name: 'Test', last_name: 'User', email: 'user@example.com' }] };
    }
    if (sql.includes('SELECT 1 FROM organization_users') && sql.includes('super_admin')) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
      return { rows: [] };
    }
    if (sql.includes('UPDATE pets') && sql.includes('user_id = $1')) {
      updatedOwnerId = params[0];
      return { rows: [] };
    }
    if (sql.includes('UPDATE pets') && sql.includes('organization_id = $1')) {
      updatedOrgId = params[0];
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM pet_access')) return { rows: [] };
    if (sql.includes('INSERT INTO archived_pets')) {
      archivedRow = params;
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO notifications')) return { rows: [] };
    return { rows: [] };
  };

  const pool = {
    query: handleQuery,
    connect: async () => ({
      query: handleQuery,
      release: () => {},
    }),
    get updatedOwnerId() { return updatedOwnerId; },
    get updatedOrgId() { return updatedOrgId; },
    get archivedRow() { return archivedRow; },
  };
  return pool;
}

describe('orgPetTransfer', () => {
  it('transferOrgPetToUser updates owner and archives transfer', async () => {
    const pool = makeTransferPool();
    const result = await transferOrgPetToUser(pool, {
      orgId,
      petId,
      adminId,
      recipientId,
      transferType: 'adoption',
      notes: 'Happy home',
    });
    expect(result.transferred).toBe(true);
    expect(result.new_owner_id).toBe(recipientId);
    expect(pool.updatedOwnerId).toBe(recipientId);
    expect(pool.archivedRow[6]).toBe('adoption');
    expect(pool.archivedRow[7]).toBe(recipientId);
  });

  it('transferPetToOrganization assigns org custody', async () => {
    const pool = makeTransferPool();
    const result = await transferPetToOrganization(pool, {
      petId,
      ownerId,
      orgId,
      transferType: 'transfer',
      notes: 'Surrendered',
    });
    expect(result.transferred).toBe(true);
    expect(result.organization_id).toBe(orgId);
    expect(pool.updatedOrgId).toBe(orgId);
    expect(pool.archivedRow[6]).toBe('transfer');
    expect(pool.archivedRow[7]).toBe(orgId);
  });
});
