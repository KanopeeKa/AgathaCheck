import { migratePinnedOrganizationId } from '../scripts/migrations/049_pinned_organization_id.js';

describe('049_pinned_organization_id', () => {
  it('adds column, index, and membership-loss trigger', async () => {
    const statements = [];
    const client = {
      query: async (sql) => {
        statements.push(sql.trim());
        return { rows: [] };
      },
    };

    await migratePinnedOrganizationId(client);

    expect(statements.some((sql) => sql.includes('ADD COLUMN IF NOT EXISTS pinned_organization_id'))).toBe(true);
    expect(statements.some((sql) => sql.includes('idx_users_pinned_organization_id'))).toBe(true);
    expect(statements.some((sql) => sql.includes('clear_pinned_org_on_membership_loss'))).toBe(true);
    expect(statements.some((sql) => sql.includes('EXECUTE PROCEDURE clear_pinned_org_on_membership_loss()'))).toBe(true);
  });
});
