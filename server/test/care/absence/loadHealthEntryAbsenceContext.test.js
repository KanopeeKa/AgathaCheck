import { loadHealthEntryAbsenceContext } from '../../../lib/care/absence/loadHealthEntryAbsenceContext.js';

describe('loadHealthEntryAbsenceContext active window', () => {
  afterEach(() => {
    jest.useRealTimers();
  });

  it('keeps absences active through ends_on on declarer calendar day when UTC has rolled forward', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-10-09T02:30:00.000Z'));

    const pool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT timezone FROM users')) {
          return { rows: [{ timezone: 'America/Los_Angeles' }] };
        }
        if (sql.includes('home_timezone FROM pets')) {
          return { rows: [{ home_timezone: 'America/Los_Angeles' }] };
        }
        if (sql.includes('FROM planned_absences pa')) {
          expect(params[3]).toBe('2026-10-08');
          return {
            rows: [{
              id: 'abs-1',
              starts_on: '2026-10-02',
              ends_on: '2026-10-08',
            }],
          };
        }
        if (sql.includes('planned_absence_pets')) {
          return { rows: [{ carer_kind: null, pet_id: 'pet-1' }] };
        }
        if (sql.includes('health_entry_absence_resolutions')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
    };

    const entry = { id: 'entry-1', pet_id: 'pet-1' };
    const context = await loadHealthEntryAbsenceContext(pool, entry, 'user-1');
    expect(context.absences).toHaveLength(1);
    expect(context.absences[0].ends_on).toBe('2026-10-08');
  });
});
