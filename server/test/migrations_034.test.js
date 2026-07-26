import { migrateFamilyEventsTimeline } from '../scripts/migrations/034_migrate_family_events_timeline.js';

describe('034_migrate_family_events_timeline', () => {
  it('copies non-placement family_events into pet_timeline_entries idempotently', async () => {
    const inserts = [];
    const familyRows = [
      {
        id: 'fe-1',
        pet_id: 'pet-1',
        notes: 'Early notes',
        from_date: '2020-01-01',
        to_date: '2020-06-01',
        created_by: 'user-1',
        created_at: new Date('2020-01-02T00:00:00Z'),
      },
    ];
    const client = {
      query: async (sql, params) => {
        if (sql.includes('FROM family_events fe')) {
          return { rows: familyRows };
        }
        if (sql.includes('INSERT INTO pet_timeline_entries')) {
          inserts.push(params);
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    await migrateFamilyEventsTimeline(client);
    expect(inserts).toHaveLength(1);
    expect(inserts[0][1]).toBe('pet-1');
    expect(inserts[0][2]).toBe('Early notes');
    expect(inserts[0][3]).toBe('Early notes');
    expect(inserts[0][4]).toBe('2020-01-01');
    expect(inserts[0][5]).toBe('2020-06-01');

    familyRows.length = 0;
    await migrateFamilyEventsTimeline(client);
    expect(inserts).toHaveLength(1);
  });
});
