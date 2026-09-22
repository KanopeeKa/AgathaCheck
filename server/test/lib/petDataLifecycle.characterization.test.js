import { deleteAllPetData } from '../../lib/petDataLifecycle.js';
import { petId, userId } from '../pets/helpers.js';

/**
 * Batch A1 characterization — documents current transaction boundary (finding A01).
 * Target state (Batch B1): single checked-out PoolClient for the whole operation.
 */
describe('petDataLifecycle characterization', () => {
  describe('deleteAllPetData transaction boundary', () => {
    it('characterization: issues BEGIN and mutations via pool.query (rotating connections)', async () => {
      let connectionSerial = 0;
      const queryLog = [];

      const pool = {
        query: async (sql, params) => {
          const connectionId = connectionSerial++;
          queryLog.push({ connectionId, sql: String(sql).trim() });

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
      };

      await deleteAllPetData(pool, petId, { actorUserId: userId });

      const begin = queryLog.find((q) => q.sql === 'BEGIN');
      const firstDelete = queryLog.find((q) => q.sql.startsWith('DELETE FROM '));
      expect(begin).toBeDefined();
      expect(firstDelete).toBeDefined();
      // Documents A01: pool.query may use a different connection per call.
      expect(begin.connectionId).not.toBe(firstDelete.connectionId);
      expect(queryLog.every((q) => !q.sql.includes('connect'))).toBe(true);
    });
  });
});
