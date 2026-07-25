import {
  createFosterProfileForManualParent,
  findMergeSuggestionsByEmail,
  mergeManualFosterIntoUser,
  migrateFosterProfiles,
} from '../../lib/fosterProfiles.js';

describe('fosterProfiles', () => {
  describe('migrateFosterProfiles', () => {
    it('creates foster_profiles table and backfills org_foster_parents', async () => {
      const queries = [];
      const client = {
        query: async (sql, params) => {
          queries.push(sql);
          if (sql.includes('FROM org_foster_parents') && sql.includes('foster_profile_id IS NULL')) {
            return {
              rows: [{
                id: 'fp-1',
                user_id: null,
                display_name: 'Manual Parent',
                email: 'manual@example.com',
                phone: '555',
                foster_address: '123 St',
                foster_profile_id: null,
              }],
            };
          }
          if (sql.includes('INSERT INTO foster_profiles')) {
            return { rows: [] };
          }
          if (sql.includes('UPDATE org_foster_parents')) {
            return { rows: [] };
          }
          return { rows: [] };
        },
      };

      await migrateFosterProfiles(client);

      expect(queries.some((q) => q.includes('CREATE TABLE IF NOT EXISTS foster_profiles'))).toBe(true);
      expect(queries.some((q) => q.includes('ADD COLUMN IF NOT EXISTS foster_profile_id'))).toBe(true);
      expect(queries.some((q) => q.includes('INSERT INTO foster_profiles'))).toBe(true);
    });
  });

  describe('createFosterProfileForManualParent', () => {
    it('inserts a foster profile row and returns its id', async () => {
      let insertedId = null;
      const client = {
        query: async (sql, params) => {
          if (sql.includes('INSERT INTO foster_profiles')) {
            insertedId = params[0];
            return { rows: [] };
          }
          return { rows: [] };
        },
      };

      const profileId = await createFosterProfileForManualParent(client, {
        displayName: 'New Parent',
        email: 'new@example.com',
        phone: '555-1234',
        fosterAddress: '1 Main St',
      });

      expect(profileId).toBe(insertedId);
      expect(profileId).toMatch(/^[0-9a-f-]{36}$/);
    });
  });

  describe('findMergeSuggestionsByEmail', () => {
    it('returns empty array for blank email', async () => {
      const pool = { query: jest.fn() };
      const result = await findMergeSuggestionsByEmail(pool, '  ', 'org-1');
      expect(result).toEqual([]);
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('returns registered users matching email', async () => {
      const pool = {
        query: async () => ({
          rows: [{
            user_id: 'user-1',
            display_name: 'Jane Doe',
            email: 'jane@example.com',
            foster_profile_id: 'fprof-1',
          }],
        }),
      };

      const result = await findMergeSuggestionsByEmail(pool, 'jane@example.com', 'org-1');
      expect(result).toEqual([{
        user_id: 'user-1',
        display_name: 'Jane Doe',
        email: 'jane@example.com',
        foster_profile_id: 'fprof-1',
        is_org_member: false,
      }]);
    });
  });

  describe('mergeManualFosterIntoUser', () => {
    it('returns 404 when foster parent not found', async () => {
      const pool = {
        query: async () => ({ rows: [] }),
      };
      const result = await mergeManualFosterIntoUser(pool, {
        orgId: 'org-1',
        fosterParentId: 'missing',
        targetUserId: 'user-1',
        actorUserId: 'admin-1',
      });
      expect(result).toEqual({ error: 'not_found', status: 404 });
    });

    it('merges manual foster into registered user profile', async () => {
      const pool = {
        query: async (sql) => {
          if (sql.includes('SELECT * FROM org_foster_parents')) {
            return {
              rows: [{
                id: 'fp-1',
                organization_id: 'org-1',
                user_id: null,
                foster_profile_id: 'fprof-manual',
                display_name: 'Manual',
                email: 'user@example.com',
                phone: '555',
                foster_address: '',
              }],
            };
          }
          if (sql.includes('SELECT id, email, first_name, last_name FROM users')) {
            return {
              rows: [{
                id: 'user-1',
                email: 'user@example.com',
                first_name: 'Registered',
                last_name: 'User',
              }],
            };
          }
          if (sql.includes('SELECT id FROM foster_profiles WHERE user_id')) {
            return { rows: [{ id: 'fprof-user' }] };
          }
          if (sql.includes('UPDATE org_foster_parents')) {
            return {
              rows: [{
                id: 'fp-1',
                organization_id: 'org-1',
                user_id: 'user-1',
                foster_profile_id: 'fprof-user',
                display_name: 'Manual',
                email: 'user@example.com',
              }],
            };
          }
          if (sql.includes('SELECT COUNT(*)::int AS count FROM org_foster_parents')) {
            return { rows: [{ count: 0 }] };
          }
          return { rows: [] };
        },
      };

      const result = await mergeManualFosterIntoUser(pool, {
        orgId: 'org-1',
        fosterParentId: 'fp-1',
        targetUserId: 'user-1',
        actorUserId: 'admin-1',
      });

      expect(result.status).toBe(200);
      expect(result.survivorProfileId).toBe('fprof-user');
      expect(result.row.user_id).toBe('user-1');
    });
  });
});
