import { deleteAllPetData } from '../../lib/petDataLifecycle.js';
import { petId, userId } from '../pets/helpers.js';

/**
 * Batch B2 contract — deleteAllPetData uses one checked-out PoolClient (finding A01 fix).
 */
describe('petDataLifecycle characterization', () => {
  describe('deleteAllPetData transaction boundary', () => {
    it('uses a single checked-out client for BEGIN through COMMIT', async () => {
      const queryLog = [];
      const client = {
        query: async (sql, params) => {
          queryLog.push({ client: 'checked-out', sql: String(sql).trim() });

          if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
            return { rows: [] };
          }
          if (sql.includes('SELECT photo_path FROM pets')) {
            return { rows: [{ photo_path: null }] };
          }
          if (sql.includes('FROM health_event_photos')) {
            return { rows: [] };
          }
          if (sql.includes('FROM health_issue_documents')) {
            return { rows: [] };
          }
          if (sql.startsWith('DELETE FROM ')) {
            return { rowCount: 1 };
          }
          if (sql.includes('UPDATE pets')) {
            return { rows: [] };
          }
          if (sql.includes('INSERT INTO audit_events')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
        release: jest.fn(),
      };

      const pool = {
        connect: jest.fn(async () => client),
        query: async () => {
          throw new Error('pool.query must not be used during deleteAllPetData');
        },
      };

      await deleteAllPetData(pool, petId, { actorUserId: userId });

      expect(pool.connect).toHaveBeenCalledTimes(1);
      expect(client.release).toHaveBeenCalledTimes(1);
      const begin = queryLog.find((q) => q.sql === 'BEGIN');
      const firstDelete = queryLog.find((q) => q.sql.startsWith('DELETE FROM '));
      const commit = queryLog.find((q) => q.sql === 'COMMIT');
      expect(begin).toBeDefined();
      expect(firstDelete).toBeDefined();
      expect(commit).toBeDefined();
      expect(queryLog.every((q) => q.client === 'checked-out')).toBe(true);
    });
  });
});
