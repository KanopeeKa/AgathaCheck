import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('care-period coverage API', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);

  function createTestApp(handler) {
    return createApp(createMockPool(handler));
  }

  it('GET returns coverage nested in projection payload', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: petId, user_id: userId }] };
      }
      if (sql.includes('FROM health_entries WHERE pet_id = $1')) {
        return {
          rows: [{
            id: 'entry-1',
            pet_id: petId,
            type: 'medication',
            name: 'Monthly',
            frequency: 'monthly',
            frequency_interval: 1,
            recurrence_anchor: 'from_due_date',
            next_due_date: startsOn,
            status: 'active',
            schedule_times: null,
            care_family: 'medication',
          }],
        };
      }
      if (sql.includes('FROM health_occurrences ho')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/pets/${petId}/care-period-coverage?starts_on=${startsOn}&ends_on=${endsOn}`)
      .set(authHeader());

    expect(res.statusCode).toBe(200);
    expect(res.body.coverage.policy_version).toBe('1');
    expect(res.body.coverage.coverage_state).toBe('has_items_to_review');
    expect(res.body.projection_status).toBe('complete');
    expect(res.body.items.length).toBeGreaterThanOrEqual(1);
    expect(res.body.planned_care_items.length).toBeGreaterThanOrEqual(1);
    expect(res.body.planned_care_items[0].kind).toBe('recurring_calendar');
    expect(res.body.routine_items).toBeUndefined();
    expect(res.body.dated_items).toBeUndefined();
    expect(res.body.uncertainties).toBeUndefined();
  });

  it('GET returns 500 when the database layer throws (does not hang)', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: petId, user_id: userId }] };
      }
      if (sql.includes('FROM health_entries WHERE pet_id = $1')) {
        throw new Error('boom: simulated DB failure');
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/pets/${petId}/care-period-coverage?starts_on=${startsOn}&ends_on=${endsOn}`)
      .set(authHeader())
      .timeout({ deadline: 4000 });

    expect(res.statusCode).toBe(500);
    expect(res.body.error).toBeTruthy();
  });
});
