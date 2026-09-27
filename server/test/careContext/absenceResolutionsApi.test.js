import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('absence resolutions API', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);
  const absenceId = 'absence-1';
  const entryId = 'entry-1';

  it('GET /api/planned-absences/:id/resolutions returns 401 without auth', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app).get(`/api/planned-absences/${absenceId}/resolutions`);
    expect(res.statusCode).toBe(401);
  });

  it('GET lists resolutions for absence owner', async () => {
    const app = createApp(
      createMockPool(async (sql) => {
        if (sql.includes('FROM planned_absences WHERE id')) {
          return {
            rows: [{
              id: absenceId,
              user_id: userId,
              starts_on: startsOn,
              ends_on: endsOn,
              status: 'active',
            }],
          };
        }
        if (sql.includes('FROM health_entry_absence_resolutions')) {
          return {
            rows: [{
              id: 'res-1',
              health_entry_id: entryId,
              planned_absence_id: absenceId,
              decision: 'keep_date',
              carer_kind: null,
              carer_user_id: null,
              carer_name: null,
              absence_note: null,
              dates_decided_for: ['2026-10-26'],
              created_at: new Date(),
              updated_at: new Date(),
            }],
          };
        }
        return { rows: [] };
      })
    );

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/resolutions`)
      .set(authHeader());
    expect(res.statusCode).toBe(200);
    expect(res.body.resolutions).toHaveLength(1);
    expect(res.body.resolutions[0].decision).toBe('keep_date');
  });
});
