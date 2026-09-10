import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { todayCalendarIso, addCalendarDaysIso } from '../../lib/calendarDate.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('planned absences API', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);

  function createTestApp(handler) {
    return createApp(createMockPool(handler));
  }

  it('GET /api/planned-absences returns 401 without auth', async () => {
    const app = createTestApp(async () => ({ rows: [] }));
    const res = await request(app).get('/api/planned-absences');
    expect(res.statusCode).toBe(401);
  });

  it('POST creates absence for manageable pets with overlap warnings', async () => {
    const inserted = [];
    const app = createTestApp(async (sql, params) => {
      if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('FROM planned_absences pa') && sql.includes('overlap')) {
        return {
          rows: [{
            id: 'other-absence',
            starts_on: startsOn,
            ends_on: endsOn,
            pet_id: petId,
          }],
        };
      }
      if (sql.includes('INSERT INTO planned_absences')) {
        inserted.push(params);
        return {
          rows: [{
            id: params[0],
            user_id: params[1],
            starts_on: params[2],
            ends_on: params[3],
            provenance: params[4],
            source_ref: params[5],
            status: params[6],
            created_at: new Date(),
            updated_at: new Date(),
            cancelled_at: null,
          }],
        };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT pet_id FROM planned_absence_pets')) {
        return { rows: [{ pet_id: petId }] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .post('/api/planned-absences')
      .set(authHeader())
      .send({ starts_on: startsOn, ends_on: endsOn, pet_ids: [petId] });

    expect(res.statusCode).toBe(201);
    expect(res.body.absence.pet_ids).toEqual([petId]);
    expect(res.body.absence.starts_on).toBe(startsOn);
    expect(res.body.overlap_warnings.length).toBeGreaterThanOrEqual(0);
    expect(inserted.length).toBe(1);
  });

  it('GET list returns only declarer upcoming absences', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences') && sql.includes('ORDER BY starts_on')) {
        return {
          rows: [{
            id: 'abs-1',
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
      if (sql.includes('SELECT pet_id FROM planned_absence_pets')) {
        return { rows: [{ pet_id: petId }] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get('/api/planned-absences')
      .set(authHeader());
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].id).toBe('abs-1');
  });

  it('GET /:id returns 404 for another user absence', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [] };
      }
      return { rows: [] };
    });
    const res = await request(app)
      .get('/api/planned-absences/abs-other')
      .set(authHeader());
    expect(res.statusCode).toBe(404);
  });
});
