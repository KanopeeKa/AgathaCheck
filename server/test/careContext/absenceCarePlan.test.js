import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('GET /api/planned-absences/:id/care-plan', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);
  const absenceId = 'abs-care-plan-1';

  function createTestApp(handler) {
    return createApp(createMockPool(handler));
  }

  it('returns 401 without auth', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app).get(`/api/planned-absences/${absenceId}/care-plan`);
    expect(res.statusCode).toBe(401);
  });

  it('returns care plan payload for owned absence', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return {
          rows: [{
            id: absenceId,
            user_id: userId,
            starts_on: startsOn,
            ends_on: endsOn,
            provenance: 'user_declared',
            source_ref: null,
            status: 'active',
            created_at: new Date(),
            updated_at: new Date(),
            cancelled_at: null,
          }],
        };
      }
      if (sql.includes('FROM planned_absence_pets')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: null,
            carer_user_id: null,
            carer_name: null,
            carer_note: null,
          }],
        };
      }
      if (sql.includes('FROM health_entries WHERE pet_id = $1')) {
        return { rows: [] };
      }
      if (sql.includes('FROM health_occurrences ho')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/care-plan`)
      .set(authHeader());

    expect(res.statusCode).toBe(200);
    expect(res.body.absence_id).toBe(absenceId);
    expect(res.body.starts_on).toBe(startsOn);
    expect(res.body.pets).toEqual([{
      pet_id: petId,
      suggestions: [],
      carer_tasks: { count: 0, by_entry: [] },
    }]);
  });

  it('returns 404 when absence is not owned by caller', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/care-plan`)
      .set(authHeader());

    expect(res.statusCode).toBe(404);
  });
});
