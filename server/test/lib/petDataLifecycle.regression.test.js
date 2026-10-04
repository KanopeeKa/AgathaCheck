import { deleteAllPetData } from '../../lib/petDataLifecycle.js';
import { petId, userId } from '../pets/helpers.js';

describe('petDataLifecycle regression', () => {
  describe('deleteAllPetData transaction boundary', () => {
    it('uses a single checked-out client for BEGIN through COMMIT without pool.query', async () => {
      const queryLog = [];
      const client = {
        query: async (sql, params) => {
          queryLog.push({ client: 'checked-out', sql: String(sql).trim() });

          if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
            return { rows: [], command: sql };
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
          if (sql.includes('INSERT INTO cleanup_jobs')) {
            return { rows: [{ id: 'job-1' }] };
          }
          if (sql.startsWith('DELETE FROM ')) {
            return { rowCount: 1 };
          }
          if (sql.includes('UPDATE pets')) {
            return { rows: [] };
          }
          if (sql.includes('INSERT INTO audit_events')) {
            return { rows: [{ id: 'audit-1' }] };
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

      const result = await deleteAllPetData(pool, petId, { actorUserId: userId });

      expect(pool.connect).toHaveBeenCalledTimes(1);
      expect(client.release).toHaveBeenCalledTimes(1);
      const begin = queryLog.find((q) => q.sql === 'BEGIN');
      const firstDelete = queryLog.find((q) => q.sql.startsWith('DELETE FROM '));
      const commit = queryLog.find((q) => q.sql === 'COMMIT');
      expect(begin).toBeDefined();
      expect(firstDelete).toBeDefined();
      expect(commit).toBeDefined();
      expect(queryLog.every((q) => q.client === 'checked-out')).toBe(true);
      expect(result).toMatchObject({
        deleted: true,
        pet_id: petId,
        files_scheduled: 0,
        file_cleanup: 'none',
        files_removed: 0,
      });
    });
  });
});
