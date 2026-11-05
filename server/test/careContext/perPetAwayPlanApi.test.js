import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { createMockPool, petId, token, userId } from '../pets/helpers.js';
import {
  mockViewerAbsenceLoad,
  mockViewerFullAccessOnPets,
} from './plannedAbsenceViewerMocks.js';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

describe('per-pet away plan read API (phase 1)', () => {
  const absenceId = 'abs-per-pet-1';

  function absenceRow(overrides = {}) {
    return {
      id: absenceId,
      user_id: userId,
      starts_on: '2026-12-01',
      ends_on: '2026-12-07',
      status: 'active',
      provenance: 'user_declared',
      timezone: 'Europe/Paris',
      title: 'Holiday',
      handover_note: null,
      last_handover_downloaded_at: null,
      created_at: new Date(),
      updated_at: new Date(),
      cancelled_at: null,
      source_ref: null,
      ...overrides,
    };
  }

  function petRow(overrides = {}) {
    return {
      pet_id: petId,
      carer_kind: null,
      carer_user_id: null,
      carer_name: null,
      carer_note: null,
      pet_note: null,
      contact_id: null,
      ...overrides,
    };
  }

  async function mockAwayPlanQueries(sql, params, overrides = {}) {
    if (sql.includes('FROM planned_absences pa') && sql.includes('pap.pet_id = $2')) {
      return { rows: [absenceRow({ title: 'Trip', ...overrides.absence })] };
    }
    const viewerAbsence = mockViewerAbsenceLoad(sql, absenceRow(overrides.absence));
    if (viewerAbsence) return viewerAbsence;
    const access = mockViewerFullAccessOnPets(sql, params, userId, petId);
    if (access) return access;
    if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
      return { rows: [absenceRow(overrides.absence)] };
    }
    if (sql.includes('FROM planned_absence_pets')) {
      return { rows: [petRow(overrides.pet)] };
    }
    if (sql.includes('SELECT timezone FROM users')) {
      return { rows: [{ timezone: 'Europe/Paris' }] };
    }
    if (sql.includes('home_timezone FROM pets')) {
      return { rows: [{ home_timezone: 'Europe/Paris' }] };
    }
    if (sql.includes('FROM health_entries')) {
      return { rows: [] };
    }
    if (sql.includes('health_entry_occurrences')) {
      return { rows: [] };
    }
    if (sql.includes('health_entry_absence_resolutions')) {
      return { rows: [] };
    }
    if (sql.includes('FROM planned_absences pa') && sql.includes('pap.pet_id = $2')) {
      return { rows: [absenceRow({ title: 'Trip', ...overrides.absence })] };
    }
    if (sql.includes('INNER JOIN planned_absence_pets') && sql.includes('INNER JOIN pets p')) {
      return { rows: [absenceRow({ title: 'Trip', ...overrides.absence })] };
    }
    if (sql.includes('INNER JOIN planned_absence_pets')) {
      return { rows: [absenceRow({ title: 'Trip', ...overrides.absence })] };
    }
    return null;
  }

  function createTestApp(handler) {
    return createApp(createMockPool(handler));
  }

  it('GET /api/planned-absences/:id/pets/:petId/away-plan returns 401 without auth', async () => {
    const app = createTestApp(async () => null);
    const res = await request(app).get(
      `/api/planned-absences/${absenceId}/pets/${petId}/away-plan`,
    );
    expect(res.status).toBe(401);
  });

  it('GET away-plan returns payload for declarer-owned absence pet', async () => {
    const app = createTestApp(async (sql, params) => mockAwayPlanQueries(sql, params));

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/pets/${petId}/away-plan`)
      .set(authHeader());

    expect(res.status).toBe(200);
    expect(res.body.absence_id).toBe(absenceId);
    expect(res.body.pet_id).toBe(petId);
    expect(res.body.absence.title).toBe('Holiday');
    expect(res.body.pet_carer.pet_id).toBe(petId);
    expect(res.body.status.priority).toBe('carer_gap');
    expect(res.body.projection).toBeDefined();
  });

  it('GET status returns compact status facts', async () => {
    const app = createTestApp(async (sql, params) => mockAwayPlanQueries(sql, params, {
      absence: { title: null },
      pet: { carer_kind: 'note_only', carer_name: 'Alex' },
    }));

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}/pets/${petId}/status`)
      .set(authHeader());

    expect(res.status).toBe(200);
    expect(res.body.status.carer_state).toBe('set');
    expect(res.body.review_care_item_count).toBe(0);
  });

  it('GET /api/pets/:petId/planned-absences lists declarer absences for pet', async () => {
    const app = createTestApp(async (sql, params) => mockAwayPlanQueries(sql, params));

    const res = await request(app)
      .get(`/api/pets/${petId}/planned-absences`)
      .set(authHeader());

    expect(res.status).toBe(200);
    expect(res.body.pet_id).toBe(petId);
    expect(res.body.items).toHaveLength(1);
    expect(res.body.items[0].absence_id).toBe(absenceId);
    expect(res.body.items[0].status).toBeDefined();
  });
});
