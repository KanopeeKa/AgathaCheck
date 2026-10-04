import { buildUserDataExport, exportAuditMetadata } from '../lib/gdprUserExport.js';

describe('gdprUserExport', () => {
  const userId = 'user-1';

  function poolReturning(rowsBySqlFragment) {
    return {
      query: jest.fn(async (sql) => {
        for (const [fragment, rows] of Object.entries(rowsBySqlFragment)) {
          if (sql.includes(fragment)) {
            return { rows };
          }
        }
        return { rows: [] };
      }),
    };
  }

  it('includes CARE ledger tables scoped via health_entries.user_id', async () => {
    const occurrence = { id: 'occ-1', health_entry_id: 'he-1' };
    const scheduleEvent = { id: 'cse-1', health_entry_id: 'he-1', event_type: 'completed' };
    const absenceResolution = {
      id: 'har-1',
      health_entry_id: 'he-1',
      planned_absence_id: 'pa-1',
      decision: 'keep_date',
    };

    const pool = poolReturning({
      'FROM health_occurrences ho': [occurrence],
      'FROM care_schedule_events cse': [scheduleEvent],
      'FROM health_entry_absence_resolutions hear': [absenceResolution],
    });

    const data = await buildUserDataExport(pool, userId);

    expect(data.health_occurrences).toEqual([occurrence]);
    expect(data.care_schedule_events).toEqual([scheduleEvent]);
    expect(data.health_entry_absence_resolutions).toEqual([absenceResolution]);

    const occurrenceQuery = pool.query.mock.calls.find(([sql]) =>
      sql.includes('FROM health_occurrences ho'),
    );
    expect(occurrenceQuery[1]).toEqual([userId]);

    const audit = exportAuditMetadata({
      pets: [],
      vets: [],
      health_entries: [],
      health_occurrences: [occurrence],
      care_schedule_events: [scheduleEvent, scheduleEvent],
      health_entry_absence_resolutions: [],
      health_issues: [],
      weight_entries: [],
      notifications: [],
      organizations: [],
      pet_access: [],
      pet_share_links: [],
    });
    expect(audit.health_occurrence_count).toBe(1);
    expect(audit.care_schedule_event_count).toBe(2);
    expect(audit.health_entry_absence_resolution_count).toBe(0);
  });
});
