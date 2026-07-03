import { migrateFamilyEventsPlacements } from '../scripts/migrations/016_migrate_family_events_placements.js';

describe('016_migrate_family_events_placements', () => {
  it('inserts foster_placements rows with app-generated UUIDs', async () => {
    const inserts = [];
    const client = {
      query: async (sql, params) => {
        if (sql.includes('FROM family_events fe')) {
          return {
            rows: [{
              organization_id: 'org-1',
              pet_id: 'pet-1',
              assigned_to_user_id: 'user-1',
              from_date: '2024-01-01',
              to_date: null,
              notes: 'Foster period',
              created_by: 'admin-1',
              created_at: new Date('2024-01-01'),
              updated_at: new Date('2024-01-02'),
            }],
          };
        }
        if (sql.includes('INSERT INTO foster_placements')) {
          inserts.push(params);
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    await migrateFamilyEventsPlacements(client);

    expect(inserts).toHaveLength(1);
    expect(inserts[0][0]).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
    expect(inserts[0][1]).toBe('org-1');
    expect(inserts[0][4]).toBe('not_in_foster');
    expect(inserts[0][7]).toBe('Foster period [migrated from family_events]');
  });
});
