import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import {
  cancelEmptyActiveAbsences,
  deleteAbsenceResolutionsForPet,
} from '../../lib/care/absence/absencePetLifecycle.js';
import { resolveCarerWrite } from '../../lib/people/absenceCarer.js';
import { CARER_KIND_SHARED_USER } from '../../lib/care/plannedAbsence.js';
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

describe('absence pet lifecycle helpers', () => {
  it('deleteAbsenceResolutionsForPet targets health entries for the pet', async () => {
    let capturedSql = '';
    const client = {
      query: async (sql) => {
        capturedSql = sql;
        return { rowCount: 2 };
      },
    };
    await deleteAbsenceResolutionsForPet(client, 'abs-1', 'pet-1');
    expect(capturedSql).toContain('health_entry_absence_resolutions');
    expect(capturedSql).toContain('health_entries');
  });

  it('cancelEmptyActiveAbsences cancels absences with no pets', async () => {
    const updates = [];
    const client = {
      query: async (sql, params) => {
        if (sql.includes('NOT EXISTS')) {
          return { rows: [{ id: 'abs-empty', user_id: userId }] };
        }
        if (sql.includes('UPDATE planned_absences')) {
          updates.push(params);
          return { rows: [{ id: params[1], user_id: userId, status: 'cancelled' }] };
        }
        if (sql.includes('planned_absence_guest_grants')) {
          return { rows: [] };
        }
        return { rows: [] };
      },
    };
    await cancelEmptyActiveAbsences(client, ['abs-empty']);
    expect(updates.length).toBeGreaterThan(0);
  });
});

describe('AWAY-PLANNING-CARER-R-016 traveller not carer', () => {
  it('rejects declarer as shared_user carer', async () => {
    const pool = {
      query: async () => ({ rows: [{ user_id: userId }] }),
    };
    const result = await resolveCarerWrite(pool, {
      actorUserId: userId,
      travellerUserId: userId,
      petId,
      item: { carer_kind: CARER_KIND_SHARED_USER, carer_user_id: userId },
    });
    expect(result.ok).toBe(false);
    expect(result.status).toBe(400);
  });
});

describe('planned absence add/remove pets API', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);
  const absenceId = 'abs-pet-life-1';
  const secondPetId = '222e4567-e89b-12d3-a456-426614174099';

  function absenceRow(overrides = {}) {
    return {
      id: absenceId,
      user_id: userId,
      starts_on: startsOn,
      ends_on: endsOn,
      provenance: 'user_declared',
      source_ref: null,
      status: 'active',
      timezone: 'UTC',
      title: null,
      handover_note: null,
      created_at: new Date(),
      updated_at: new Date(),
      cancelled_at: null,
      ...overrides,
    };
  }

  it('POST /:id/pets returns 401 without auth', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app)
      .post(`/api/planned-absences/${absenceId}/pets`)
      .send({ pet_id: secondPetId });
    expect(res.status).toBe(401);
  });

  it('POST /:id/pets adds pet with overlap warnings', async () => {
    let insertedPet = false;
    const app = createApp(createTransactionalMockPool(async (sql, params) => {
        if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
          return { rows: [absenceRow()] };
        }
        if (sql.includes('FROM planned_absence_pets') && sql.includes('planned_absence_id = $1')) {
          const petRows = [{ pet_id: petId, carer_kind: null }];
          if (insertedPet) {
            petRows.push({ pet_id: secondPetId, carer_kind: null });
          }
          return { rows: petRows };
        }
        if (sql.includes('INSERT INTO planned_absence_pets')) {
          insertedPet = true;
          expect(params[1]).toBe(secondPetId);
          return { rows: [] };
        }
        if (sql.includes('UPDATE planned_absences SET updated_at')) {
          return { rows: [] };
        }
        if (sql.includes('planned_absence_guest_grants')) {
          return { rows: [] };
        }
        if (sql.includes('FROM pets WHERE id = $1')) {
          return { rows: [{ user_id: userId }] };
        }
        if (sql.includes('pet_access') || sql.includes('household_members')) {
          return { rows: [{ id: 1 }] };
        }
        if (sql.includes('FROM planned_absences pa') && sql.includes('INNER JOIN planned_absence_pets')) {
          return { rows: [] };
        }
        if (sql.includes('SELECT timezone FROM users')) {
          return { rows: [{ timezone: 'UTC' }] };
        }
        if (sql.includes('people_contacts')) {
          return { rows: [] };
        }
        return { rows: [] };
      }));

    const res = await request(app)
      .post(`/api/planned-absences/${absenceId}/pets`)
      .set(authHeader())
      .send({ pet_id: secondPetId });

    expect(res.status).toBe(200);
    expect(insertedPet).toBe(true);
    expect(res.body.absence.pet_ids).toContain(secondPetId);
    expect(Array.isArray(res.body.overlap_warnings)).toBe(true);
  });

  it('DELETE /:id/pets/:petId requires confirm when last pet', async () => {
    const app = createApp(createTransactionalMockPool(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('FROM planned_absence_pets')) {
        return { rows: [{ pet_id: petId, carer_kind: null }] };
      }
      return { rows: [] };
    }));

    const res = await request(app)
      .delete(`/api/planned-absences/${absenceId}/pets/${petId}`)
      .set(authHeader())
      .send({});

    expect(res.status).toBe(409);
    expect(res.body.code).toBe('last_pet_removal_requires_confirm');
  });

  it('DELETE /:id/pets/:petId cancels absence when last pet confirmed', async () => {
    let cancelled = false;
    const app = createApp(createTransactionalMockPool(async (sql) => {
        if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
          return { rows: [absenceRow()] };
        }
        if (sql.includes('FROM planned_absence_pets')) {
          return { rows: [{ pet_id: petId, carer_kind: null }] };
        }
        if (sql.includes('DELETE FROM planned_absence_pets')) {
          return { rowCount: 1 };
        }
        if (sql.includes('DELETE FROM health_entry_absence_resolutions')) {
          return { rowCount: 0 };
        }
        if (sql.includes('UPDATE planned_absence_guest_grants')) {
          return { rowCount: 0 };
        }
        if (sql.includes('DELETE FROM planned_absence_carer_invite_pets')) {
          return { rowCount: 0 };
        }
        if (sql.includes('UPDATE planned_absences') && sql.includes('cancelled')) {
          cancelled = true;
          return { rows: [absenceRow({ status: 'cancelled' })] };
        }
        if (sql.includes('SELECT COUNT(*)')) {
          return { rows: [{ count: 0 }] };
        }
        if (sql.includes('people_contacts')) {
          return { rows: [] };
        }
        return { rows: [] };
    }));

    const res = await request(app)
      .delete(`/api/planned-absences/${absenceId}/pets/${petId}`)
      .set(authHeader())
      .send({ confirm_delete_absence: true });

    expect(res.status).toBe(200);
    expect(cancelled).toBe(true);
    expect(res.body.absence_deleted).toBe(true);
  });

  it('PATCH /:id rejects pet_ids changes', async () => {
    const app = createApp(createTransactionalMockPool(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      return { rows: [] };
    }));

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({ pet_ids: [petId, secondPetId] });

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/POST \/:id\/pets/);
  });
});
