import request from 'supertest';

import { createApp } from '../../bin/server.js';
import {
  createMockPool,
  petId,
  token,
  userId,
} from '../pets/helpers.js';
import {
  mockViewerAbsenceLoad,
  mockViewerFullAccessOnPets,
} from './plannedAbsenceViewerMocks.js';

const otherUserId = 'declarer-other-99';
const otherPetId = 'pet-other-99';
const buddyPetId = petId;
const absenceId = 'abs-co-visible-1';

function authHeader() {
  return { Authorization: `Bearer ${token}` };
}

function absenceRow(overrides = {}) {
  return {
    id: absenceId,
    user_id: otherUserId,
    starts_on: '2026-12-01',
    ends_on: '2026-12-07',
    status: 'active',
    provenance: 'user_declared',
    timezone: 'Europe/Paris',
    title: 'Trip',
    handover_note: null,
    last_handover_downloaded_at: null,
    created_at: new Date(),
    updated_at: new Date(),
    cancelled_at: null,
    source_ref: null,
    ...overrides,
  };
}

describe('planned absence co-visible visibility (phase 2)', () => {
  it('GET /api/planned-absences/:id omits inaccessible pets for co-parent viewer', async () => {
    const app = createApp(createMockPool(async (sql, params) => {
      const viewerAbsence = mockViewerAbsenceLoad(sql, absenceRow());
      if (viewerAbsence) return viewerAbsence;
      const access = mockViewerFullAccessOnPets(sql, params, userId, [buddyPetId]);
      if (access) return access;
      if (sql.includes('SELECT * FROM planned_absences WHERE id = $1') && !sql.includes('user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('FROM planned_absence_pets') && sql.includes('planned_absence_id = $1')) {
        return {
          rows: [
            {
              pet_id: buddyPetId,
              carer_kind: null,
              carer_user_id: null,
              carer_name: null,
              carer_note: null,
              pet_note: null,
              contact_id: null,
            },
            {
              pet_id: otherPetId,
              carer_kind: null,
              carer_user_id: null,
              carer_name: null,
              carer_note: null,
              pet_note: null,
              contact_id: null,
            },
          ],
        };
      }
      if (sql.includes('SELECT id, first_name, last_name, email FROM users')) {
        return { rows: [{ id: otherUserId, first_name: 'Frederique', last_name: 'Prevost', email: 'f@example.com' }] };
      }
      if (sql.includes('FROM contacts')) {
        return { rows: [] };
      }
      return { rows: [] };
    }));

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}`)
      .set(authHeader());

    expect(res.status).toBe(200);
    expect(res.body.is_own_absence).toBe(false);
    expect(res.body.declarer_display_name).toBeTruthy();
    expect(res.body.can_edit_trip).toBe(false);
    expect(res.body.pet_ids).toEqual([buddyPetId]);
    expect(res.body.pet_ids).not.toContain(otherPetId);
    expect(JSON.stringify(res.body)).not.toContain(otherPetId);
  });

});
