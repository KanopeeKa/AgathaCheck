import { setSupportStaffFlagByEmail } from '../../lib/support/staff/staffFlag.js';

describe('setSupportStaffFlagByEmail', () => {
  it('grants staff by email', async () => {
    const queries = [];
    const pool = {
      query: async (sql, params) => {
        queries.push({ sql: String(sql), params });
        return {
          rowCount: 1,
          rows: [
            {
              id: 'user-1',
              email: 'staff@example.com',
              is_support_staff: true,
            },
          ],
        };
      },
    };

    const result = await setSupportStaffFlagByEmail(pool, 'Staff@Example.com', true);
    expect(result.ok).toBe(true);
    expect(result.user.is_support_staff).toBe(true);
    expect(queries[0].params).toEqual([true, 'staff@example.com']);
  });

  it('returns not_found when email is unknown', async () => {
    const pool = {
      query: async () => ({ rowCount: 0, rows: [] }),
    };
    const result = await setSupportStaffFlagByEmail(pool, 'missing@example.com', true);
    expect(result.ok).toBe(false);
    expect(result.reason).toBe('not_found');
  });

  it('revokes staff', async () => {
    const pool = {
      query: async (_sql, params) => ({
        rowCount: 1,
        rows: [
          {
            id: 'user-1',
            email: 'staff@example.com',
            is_support_staff: params[0],
          },
        ],
      }),
    };
    const result = await setSupportStaffFlagByEmail(pool, 'staff@example.com', false);
    expect(result.ok).toBe(true);
    expect(result.user.is_support_staff).toBe(false);
  });
});
