import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('care-period projection API', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);

  function createTestApp(handler) {
    return createApp(createMockPool(handler));
  }

  it('GET returns 401 without auth', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app).get(
      `/api/pets/${petId}/care-period-projection?starts_on=${startsOn}&ends_on=${endsOn}`
    );
    expect(res.statusCode).toBe(401);
  });

  it('GET returns 400 for invalid date window', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app)
      .get(`/api/pets/${petId}/care-period-projection?starts_on=${endsOn}&ends_on=${startsOn}`)
      .set(authHeader());
    expect(res.statusCode).toBe(400);
  });

  it('GET returns 403 when user cannot manage pet', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [] };
      }
      if (sql.includes('FROM pet_access')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/pets/${petId}/care-period-projection?starts_on=${startsOn}&ends_on=${endsOn}`)
      .set(authHeader());
    expect(res.statusCode).toBe(403);
  });

  it('GET returns projection payload for manageable pet', async () => {
    const app = createTestApp(async (sql, params) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: petId, user_id: userId }] };
      }
      if (sql.includes('FROM health_entries WHERE pet_id = $1')) {
        return {
          rows: [{
            id: 'entry-1',
            pet_id: petId,
            type: 'medication',
            name: 'Daily pill',
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
      .get(`/api/pets/${petId}/care-period-projection?starts_on=${startsOn}&ends_on=${endsOn}`)
      .set(authHeader());

    expect(res.statusCode).toBe(200);
    expect(res.body.pet_id).toBe(petId);
    expect(res.body.starts_on).toBe(startsOn);
    expect(res.body.ends_on).toBe(endsOn);
    expect(res.body.projection_status).toBe('complete');
    expect(res.body.items.length).toBeGreaterThanOrEqual(1);
    expect(res.body.items[0].source).toBe('projected');
  });
});
