import { ensurePersonalDirectory } from '../../lib/people/directory.js';

describe('ensurePersonalDirectory', () => {
  it('uses ON CONFLICT matching partial unique index on owner_user_id', async () => {
    const queries = [];
    const pool = {
      query: async (sql, params) => {
        queries.push(sql);
        if (sql.includes('SELECT id FROM people_directories')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO people_directories')) {
          return { rows: [{ id: 'dir-new' }] };
        }
        return { rows: [] };
      },
    };

    const id = await ensurePersonalDirectory(pool, 'user-abc');
    expect(id).toBe('dir-new');
    const insertSql = queries.find((q) => q.includes('INSERT INTO people_directories'));
    expect(insertSql).toContain(
      'ON CONFLICT (owner_user_id) WHERE (owner_user_id IS NOT NULL) DO UPDATE',
    );
  });

  it('returns existing directory without insert', async () => {
    const pool = {
      query: async (sql) => {
        if (sql.includes('SELECT id FROM people_directories')) {
          return { rows: [{ id: 'dir-existing' }] };
        }
        throw new Error(`unexpected query: ${sql}`);
      },
    };
    const id = await ensurePersonalDirectory(pool, 'user-abc');
    expect(id).toBe('dir-existing');
  });
});
