import {
  CARER_ROLE,
  CO_PARENT_ROLE,
  FOSTER_PET_ACCESS_ROLE,
  PET_ACCESS_ROLES,
  getPetAccessRole,
  petAccessRolesSql,
  petNotificationRecipientIds,
  userCanManageCare,
  userCanManageProfile,
  userCanSharePet,
  userIsOwnerOrCoParent,
} from '../../lib/petAccess.js';

const petId = 'pet-1';
const ownerId = 'owner-1';
const coParentId = 'co-1';
const carerId = 'carer-1';

function mockPool(handler) {
  return { query: jest.fn(handler) };
}

describe('petAccess', () => {
  it('exports PET_ACCESS_ROLES and petAccessRolesSql', () => {
    expect(PET_ACCESS_ROLES).toEqual([CARER_ROLE, CO_PARENT_ROLE]);
    expect(petAccessRolesSql()).toContain("'carer'");
    expect(petAccessRolesSql()).toContain("'co_parent'");
  });

  describe('getPetAccessRole', () => {
    it('returns null when no access row', async () => {
      const pool = mockPool(async () => ({ rows: [] }));
      expect(await getPetAccessRole(pool, petId, carerId)).toBeNull();
    });

    it('returns carer or co_parent role', async () => {
      const pool = mockPool(async () => ({ rows: [{ role: CO_PARENT_ROLE }] }));
      expect(await getPetAccessRole(pool, petId, coParentId)).toBe(CO_PARENT_ROLE);
    });

    it('returns foster role', async () => {
      const pool = mockPool(async () => ({ rows: [{ role: FOSTER_PET_ACCESS_ROLE }] }));
      expect(await getPetAccessRole(pool, petId, 'foster-1')).toBe(FOSTER_PET_ACCESS_ROLE);
    });

    it('returns null for unknown role', async () => {
      const pool = mockPool(async () => ({ rows: [{ role: 'legacy' }] }));
      expect(await getPetAccessRole(pool, petId, carerId)).toBeNull();
    });
  });

  describe('userIsOwnerOrCoParent', () => {
    it('returns true for owner', async () => {
      const pool = mockPool(async (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return { rows: [] };
      });
      expect(await userIsOwnerOrCoParent(pool, petId, ownerId)).toBe(true);
    });

    it('returns true for co_parent access', async () => {
      const pool = mockPool(async (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [] };
        }
        if (sql.includes('role = $3')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return { rows: [] };
      });
      expect(await userIsOwnerOrCoParent(pool, petId, coParentId)).toBe(true);
    });
  });

  describe('userCanManageProfile vs userCanManageCare', () => {
    it('carer can manage care but not profile', async () => {
      const pool = mockPool(async (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [] };
        }
        if (sql.includes('role IN') && sql.includes('co_parent')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return { rows: [] };
      });
      expect(await userCanManageCare(pool, petId, carerId)).toBe(true);
      expect(await userCanManageProfile(pool, petId, carerId)).toBe(false);
    });

    it('co_parent can manage profile', async () => {
      const pool = mockPool(async (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [] };
        }
        if (sql.includes('role = $3')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return { rows: [] };
      });
      expect(await userCanManageProfile(pool, petId, coParentId)).toBe(true);
    });
  });

  describe('userCanSharePet', () => {
    it('returns true for foster with active placement', async () => {
      const pool = mockPool(async (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [] };
        }
        if (sql.includes('role = $3') && sql.includes('foster_placements')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return { rows: [] };
      });
      expect(await userCanSharePet(pool, petId, 'foster-1')).toBe(true);
    });
  });

  describe('petNotificationRecipientIds', () => {
    it('returns owner and collaborator user ids', async () => {
      const pool = mockPool(async () => ({
        rows: [{ user_id: ownerId }, { user_id: carerId }],
      }));
      const ids = await petNotificationRecipientIds(pool, petId);
      expect(ids).toEqual([ownerId, carerId]);
    });
  });
});
