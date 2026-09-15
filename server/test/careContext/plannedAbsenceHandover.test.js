import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import {
  createMockPool,
  createTransactionalMockPool,
  petId,
  token,
  userId,
} from '../pets/helpers.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('planned absence handover API', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);
  const absenceId = 'absence-handover-1';

  function absenceRow(overrides = {}) {
    return {
      id: absenceId,
      user_id: userId,
      starts_on: startsOn,
      ends_on: endsOn,
      provenance: 'user_declared',
      source_ref: null,
      status: 'active',
      handover_note: null,
      last_handover_downloaded_at: null,
      created_at: new Date(),
      updated_at: new Date(),
      cancelled_at: null,
      ...overrides,
    };
  }

  function createTransactionalTestApp(handler) {
    return createApp(createTransactionalMockPool(handler));
  }

  it('POST /api/planned-absences/:id/record-handover-download returns 401 without auth', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app).post(
      `/api/planned-absences/${absenceId}/record-handover-download`,
    );
    expect(res.statusCode).toBe(401);
  });

  it('POST record-handover-download sets last_handover_downloaded_at', async () => {
    const downloadedAt = new Date('2026-09-15T12:00:00.000Z');
    const app = createApp(createMockPool(async (sql) => {
      if (sql.includes('UPDATE planned_absences') && sql.includes('last_handover_downloaded_at')) {
        return {
          rows: [absenceRow({
            handover_note: 'Keep gate code private',
            last_handover_downloaded_at: downloadedAt,
          })],
        };
      }
      if (sql.includes('FROM planned_absence_pets')) {
        return { rows: [{ pet_id: petId, carer_kind: null }] };
      }
      return { rows: [] };
    }));

    const res = await request(app)
      .post(`/api/planned-absences/${absenceId}/record-handover-download`)
      .set(authHeader())
      .send({});

    expect(res.statusCode).toBe(200);
    expect(res.body.handover_note).toBe('Keep gate code private');
    expect(res.body.last_handover_downloaded_at).toBe(downloadedAt.toISOString());
  });

  it('PATCH accepts handover_note without changing dates', async () => {
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')
        || sql.includes('SELECT planned_absence_id, pet_id, carer_kind')) {
        return { rows: [{ planned_absence_id: absenceId, pet_id: petId, carer_kind: null }] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('handover_note')) {
        expect(params[2]).toBe('Feed twice daily — verbatim line 1\n**not parsed**');
        return {
          rows: [absenceRow({ handover_note: params[2] })],
        };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('FROM planned_absences pa')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({ handover_note: 'Feed twice daily — verbatim line 1\n**not parsed**' });

    expect(res.statusCode).toBe(200);
    expect(res.body.absence.handover_note).toBe(
      'Feed twice daily — verbatim line 1\n**not parsed**',
    );
  });
});
