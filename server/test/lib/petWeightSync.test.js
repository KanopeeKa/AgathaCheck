import {
  weightsDiffer,
  getLatestWeightEntry,
  refreshPetWeightCache,
  createWeightEntryAndSyncPet,
  maybeCreateWeightEntryFromPetPayload,
} from '../../lib/petWeightSync.js';

describe('petWeightSync', () => {
  describe('weightsDiffer', () => {
    it('returns false for equal numbers', () => {
      expect(weightsDiffer(12.5, 12.5)).toBe(false);
    });

    it('returns true when one side is null', () => {
      expect(weightsDiffer(12, null)).toBe(true);
      expect(weightsDiffer(null, 12)).toBe(true);
    });

    it('returns true for different values', () => {
      expect(weightsDiffer(12, 13)).toBe(true);
    });
  });

  describe('getLatestWeightEntry', () => {
    it('returns the first row from the latest-entry query', async () => {
      const row = { id: 'we-1', weight: 10 };
      const pool = {
        query: jest.fn(async () => ({ rows: [row] })),
      };
      const result = await getLatestWeightEntry(pool, 'pet-1');
      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('FROM weight_entries'),
        ['pet-1'],
      );
    });
  });

  describe('refreshPetWeightCache', () => {
    it('updates pets.weight from latest entry subquery', async () => {
      const pool = { query: jest.fn(async () => ({ rows: [] })) };
      await refreshPetWeightCache(pool, 'pet-1');
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE pets SET weight = ('),
        ['pet-1'],
      );
    });
  });

  describe('createWeightEntryAndSyncPet', () => {
    it('inserts an entry and refreshes the pet cache', async () => {
      const queries = [];
      const pool = {
        query: jest.fn(async (sql, params) => {
          queries.push({ sql, params });
          return { rows: [] };
        }),
      };
      await createWeightEntryAndSyncPet(pool, {
        petId: 'pet-1',
        userId: 'user-1',
        weight: 12.5,
        date: '2026-07-29',
        notes: '',
      });
      expect(queries).toHaveLength(2);
      expect(queries[0].sql).toContain('INSERT INTO weight_entries');
      expect(queries[0].params[3]).toBe(12.5);
      expect(queries[1].sql).toContain('UPDATE pets SET weight = (');
    });
  });

  describe('maybeCreateWeightEntryFromPetPayload', () => {
    it('skips when weight is null', async () => {
      const pool = { query: jest.fn() };
      await maybeCreateWeightEntryFromPetPayload(pool, {
        petId: 'pet-1',
        userId: 'user-1',
        weight: null,
      });
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('creates an entry when weight changed', async () => {
      const pool = {
        query: jest.fn(async (sql) => {
          if (sql.includes('FROM weight_entries')) {
            return { rows: [{ id: 'we-1', weight: 10 }] };
          }
          return { rows: [] };
        }),
      };
      await maybeCreateWeightEntryFromPetPayload(pool, {
        petId: 'pet-1',
        userId: 'user-1',
        weight: 12,
      });
      expect(pool.query).toHaveBeenCalledTimes(3);
      expect(pool.query.mock.calls[1][0]).toContain('INSERT INTO weight_entries');
    });

    it('does not create an entry when weight matches latest', async () => {
      const pool = {
        query: jest.fn(async (sql) => {
          if (sql.includes('FROM weight_entries')) {
            return { rows: [{ id: 'we-1', weight: 12 }] };
          }
          return { rows: [] };
        }),
      };
      await maybeCreateWeightEntryFromPetPayload(pool, {
        petId: 'pet-1',
        userId: 'user-1',
        weight: 12,
      });
      expect(pool.query).toHaveBeenCalledTimes(1);
    });
  });
});
