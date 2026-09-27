import {
  getHouseholdGrantForUser,
  householdAccessiblePetSql,
} from '../../lib/households/petAccessGrants.js';
import { userCanManageCare, userCanManageProfile } from '../../lib/petAccess.js';

const petId = 'pet-1';
const userId = 'user-1';

function mockPool(handler) {
  return { query: jest.fn(handler) };
}

describe('household pet access grants', () => {
  it('householdAccessiblePetSql includes household_pets join', () => {
    expect(householdAccessiblePetSql('p', '$2')).toContain('household_pets');
  });

  it('getHouseholdGrantForUser returns tier when member', async () => {
    const pool = mockPool(async () => ({ rows: [{ access_tier: 'can_log_care' }] }));
    expect(await getHouseholdGrantForUser(pool, petId, userId)).toBe('can_log_care');
  });

  it('full_access household grants profile and care', async () => {
    const pool = mockPool(async (sql) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) return { rows: [] };
      if (sql.includes('household_pets hp')) return { rows: [{ access_tier: 'full_access' }] };
      if (sql.includes('role IN') && sql.includes('co_parent')) return { rows: [] };
      if (sql.includes('role = $3')) return { rows: [] };
      return { rows: [] };
    });
    expect(await userCanManageCare(pool, petId, userId)).toBe(true);
    expect(await userCanManageProfile(pool, petId, userId)).toBe(true);
  });

  it('can_log_care household grants care only', async () => {
    const pool = mockPool(async (sql) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) return { rows: [] };
      if (sql.includes('household_pets hp')) return { rows: [{ access_tier: 'can_log_care' }] };
      if (sql.includes('role IN')) return { rows: [] };
      if (sql.includes('role = $3')) return { rows: [] };
      return { rows: [] };
    });
    expect(await userCanManageCare(pool, petId, userId)).toBe(true);
    expect(await userCanManageProfile(pool, petId, userId)).toBe(false);
  });
});
