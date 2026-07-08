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
  let careUpdated = false;
  const handleQuery = async (sql, params) => {
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
    if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
      return { rows: [{ id: petId, name: 'Buddy', organization_id: orgId, user_id: ownerId }] };
    }
    if (sql.includes('SELECT 1 FROM custody_transfers WHERE pet_id')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO custody_transfers')) return { rows: [] };
    if (sql.includes('INSERT INTO notifications')) return { rows: [] };
    if (sql.includes('UPDATE pets SET') && sql.includes('care_holder_kind')) {
      careUpdated = true;
      return { rows: [] };
    }
    return { rows: [] };
  };

  return {
    query: handleQuery,
    get careUpdated() { return careUpdated; },
  };
}

describe('orgPetTransfer', () => {
  it('transferOrgPetToUser creates pending custody transfer', async () => {
    const pool = makeTransferPool();
    const result = await transferOrgPetToUser(pool, {
      orgId,
      petId,
      adminId,
      recipientId,
      transferType: 'adoption',
      notes: 'Happy home',
    });
    expect(result.pending).toBe(true);
    expect(result.transfer_id).toBeTruthy();
    expect(result.recipient_id).toBe(recipientId);
  });

  it('transferPetToOrganization assigns org guardian and care', async () => {
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
    expect(pool.careUpdated).toBe(true);
  });
});
