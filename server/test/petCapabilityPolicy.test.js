import {
  PET_CAPABILITIES,
  hasPetCapability,
} from '../lib/petCapabilityPolicy.js';

describe('petCapabilityPolicy', () => {
  const petId = 'pet-1';
  const ownerId = 'owner-1';
  const viewerId = 'viewer-1';

  function mockPool(handlers) {
    return {
      query: jest.fn(async (sql, params) => {
        for (const handler of handlers) {
          const result = handler(sql, params);
          if (result !== undefined) return result;
        }
        return { rows: [] };
      }),
    };
  }

  it('exports discovery capability seeds', () => {
    expect(PET_CAPABILITIES.VIEW).toBe('pet.view');
    expect(PET_CAPABILITIES.SHARING_MANAGE).toBe('pet.sharing.manage');
    expect(PET_CAPABILITIES.DELETE).toBe('pet.delete');
  });

  it('returns false for unknown capability', async () => {
    const pool = mockPool([]);
    expect(await hasPetCapability(pool, ownerId, petId, 'pet.unknown')).toBe(false);
  });

  it('pet.view allows owner via userCanAccessPet', async () => {
    const pool = mockPool([
      (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return undefined;
      },
    ]);
    expect(await hasPetCapability(pool, ownerId, petId, PET_CAPABILITIES.VIEW)).toBe(true);
  });

  it('pet.delete requires ownership', async () => {
    const pool = mockPool([
      (sql, params) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2') && params[1] === ownerId) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2') && params[1] === viewerId) {
          return { rows: [] };
        }
        return undefined;
      },
    ]);
    expect(await hasPetCapability(pool, ownerId, petId, PET_CAPABILITIES.DELETE)).toBe(true);
    expect(await hasPetCapability(pool, viewerId, petId, PET_CAPABILITIES.DELETE)).toBe(false);
  });

  it('pet.sharing.manage delegates to userCanSharePet', async () => {
    const pool = mockPool([
      (sql) => {
        if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ '?column?': 1 }] };
        }
        return undefined;
      },
    ]);
    expect(await hasPetCapability(pool, ownerId, petId, PET_CAPABILITIES.SHARING_MANAGE)).toBe(true);
  });
});
