import { migrateRetireFosterWireRole } from '../scripts/migrations/044_org_retire_foster_wire_role.js';

describe('044_org_retire_foster_wire_role migration', () => {
  it('renames foster wire roles and tightens role check constraint', async () => {
    const queries = [];
    const client = {
      query: jest.fn(async (sql) => {
        queries.push(sql);
        if (sql.includes("WHERE role = 'foster'")) return { rowCount: 2 };
        if (sql.includes("WHERE role = 'pending_foster'")) return { rowCount: 1 };
        return { rowCount: 0 };
      }),
    };

    await migrateRetireFosterWireRole(client);

    expect(queries.some((sql) => sql.includes("SET role = 'associate'"))).toBe(true);
    expect(queries.some((sql) => sql.includes("SET role = 'pending_associate'"))).toBe(true);
    expect(queries.some((sql) => sql.includes('organization_users_role_check'))).toBe(true);
    expect(
      queries.some(
        (sql) => sql.includes("'associate'") && !sql.includes("'foster'"),
      ),
    ).toBe(true);
  });
});
