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

describe('planned absence carers', () => {
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 7);
  const endsOn = addCalendarDaysIso(today, 14);
  const absenceId = 'abs-carer-1';
  const carerUserId = '333e4567-e89b-12d3-a456-426614174002';

  function absenceRow(overrides = {}) {
    return {
      id: absenceId,
      user_id: userId,
      starts_on: startsOn,
      ends_on: endsOn,
      provenance: 'user_declared',
      source_ref: null,
      status: 'active',
      created_at: new Date('2026-01-01T00:00:00.000Z'),
      updated_at: new Date('2026-01-01T00:00:00.000Z'),
      cancelled_at: null,
      ...overrides,
    };
  }

  it('PATCH assigns shared_user carer and bumps updated_at', async () => {
    let updatedAtBumped = false;
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT planned_absence_id, pet_id, carer_kind')) {
        return {
          rows: [{
            planned_absence_id: absenceId,
            pet_id: petId,
            carer_kind: null,
            carer_user_id: null,
            carer_name: null,
            carer_note: null,
          }],
        };
      }
      if (sql.includes('SELECT 1 FROM pet_access') && sql.includes('role IN')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('UPDATE planned_absence_pets') && sql.includes('carer_kind')) {
        expect(params[0]).toBe('shared_user');
        expect(params[1]).toBe(carerUserId);
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('updated_at = NOW()')) {
        updatedAtBumped = true;
        return { rows: [absenceRow({ updated_at: new Date('2026-02-01T00:00:00.000Z') })] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets') && sql.includes('NOT (pet_id = ANY')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets') && sql.includes('ON CONFLICT')) {
        return { rows: [] };
      }
      if (sql.includes('FROM planned_absences pa') && sql.includes('INNER JOIN planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: 'shared_user',
            carer_user_id: carerUserId,
            carer_name: null,
            carer_note: null,
          }],
        };
      }
      if (sql.includes('FROM users') && sql.includes('id = ANY')) {
        return {
          rows: [{
            id: carerUserId,
            first_name: 'Sarah',
            last_name: 'Miller',
          }],
        };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({
        pet_carers: [{
          pet_id: petId,
          carer_kind: 'shared_user',
          carer_user_id: carerUserId,
        }],
      });

    expect(res.statusCode).toBe(200);
    expect(updatedAtBumped).toBe(true);
    expect(res.body.absence.pet_carers).toEqual([{
      pet_id: petId,
      carer_kind: 'shared_user',
      carer_user_id: carerUserId,
      carer_name: 'Sarah M.',
      carer_note: null,
      carer_removed: false,
      pet_note: null,
    }]);
  });

  it('PATCH assigns note_only carer without access implication', async () => {
    let carerUpdated = false;
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT planned_absence_id, pet_id, carer_kind')
        || sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            planned_absence_id: absenceId,
            pet_id: petId,
            carer_kind: carerUpdated ? 'note_only' : null,
            carer_user_id: null,
            carer_name: carerUpdated ? 'Tom' : null,
            carer_note: carerUpdated ? 'Neighbour' : null,
          }],
        };
      }
      if (sql.includes('UPDATE planned_absence_pets') && sql.includes('carer_kind')) {
        expect(params[0]).toBe('note_only');
        expect(params[1]).toBeNull();
        expect(params[2]).toBe('Tom');
        expect(params[3]).toBe('Neighbour');
        carerUpdated = true;
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
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
      .send({
        pet_carers: [{
          pet_id: petId,
          carer_kind: 'note_only',
          carer_name: 'Tom',
          carer_note: 'Neighbour',
        }],
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.absence.pet_carers[0]).toMatchObject({
      pet_id: petId,
      carer_kind: 'note_only',
      carer_user_id: null,
      carer_name: 'Tom',
      carer_note: 'Neighbour',
      carer_removed: false,
    });
  });

  it('PATCH returns 403 when shared_user is not a carer candidate', async () => {
    const app = createTransactionalTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind') || sql.includes('SELECT planned_absence_id, pet_id, carer_kind')) {
        return {
          rows: [{
            planned_absence_id: absenceId,
            pet_id: petId,
            carer_kind: null,
            carer_user_id: null,
            carer_name: null,
            carer_note: null,
          }],
        };
      }
      if (sql.includes('SELECT 1 FROM pet_access') && sql.includes('role IN')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({
        pet_carers: [{
          pet_id: petId,
          carer_kind: 'shared_user',
          carer_user_id: carerUserId,
        }],
      });

    expect(res.statusCode).toBe(403);
  });

  it('PATCH with pet_note only updates pet_note and leaves carer untouched', async () => {
    let noteUpdated = false;
    let carerColumnsTouched = false;
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: 'shared_user',
            carer_user_id: carerUserId,
            carer_name: null,
            carer_note: null,
            pet_note: noteUpdated ? 'Feeds twice daily' : null,
          }],
        };
      }
      if (sql.includes('UPDATE planned_absence_pets')) {
        if (sql.includes('carer_kind')) carerColumnsTouched = true;
        expect(sql).toMatch(/SET pet_note = \$1/);
        expect(params[0]).toBe('Feeds twice daily');
        noteUpdated = true;
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('updated_at = NOW()')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('FROM planned_absences pa')) {
        return { rows: [] };
      }
      if (sql.includes('FROM users') && sql.includes('id = ANY')) {
        return { rows: [] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({
        pet_carers: [{ pet_id: petId, pet_note: 'Feeds twice daily' }],
      });

    expect(res.statusCode).toBe(200);
    expect(carerColumnsTouched).toBe(false);
    expect(res.body.absence.pet_carers[0]).toMatchObject({
      carer_kind: 'shared_user',
      carer_user_id: carerUserId,
      pet_note: 'Feeds twice daily',
    });
  });

  it('PATCH with carer_kind only updates carer and leaves pet_note untouched', async () => {
    let carerUpdated = false;
    let petNoteColumnTouched = false;
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: carerUpdated ? 'shared_user' : null,
            carer_user_id: carerUpdated ? carerUserId : null,
            carer_name: null,
            carer_note: null,
            pet_note: 'Feeds twice daily',
          }],
        };
      }
      if (sql.includes('SELECT 1 FROM pet_access') && sql.includes('role IN')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('UPDATE planned_absence_pets')) {
        if (sql.includes('pet_note')) petNoteColumnTouched = true;
        expect(params[0]).toBe('shared_user');
        expect(params[1]).toBe(carerUserId);
        carerUpdated = true;
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('updated_at = NOW()')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('FROM planned_absences pa')) {
        return { rows: [] };
      }
      if (sql.includes('FROM users') && sql.includes('id = ANY')) {
        return { rows: [{ id: carerUserId, first_name: 'Sarah', last_name: 'Miller' }] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({
        pet_carers: [{ pet_id: petId, carer_kind: 'shared_user', carer_user_id: carerUserId }],
      });

    expect(res.statusCode).toBe(200);
    expect(petNoteColumnTouched).toBe(false);
    expect(res.body.absence.pet_carers[0]).toMatchObject({
      carer_kind: 'shared_user',
      pet_note: 'Feeds twice daily',
    });
  });

  it('PATCH clearing carer_kind preserves pet_note', async () => {
    let cleared = false;
    let petNoteColumnTouched = false;
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: cleared ? null : 'shared_user',
            carer_user_id: cleared ? null : carerUserId,
            carer_name: null,
            carer_note: null,
            pet_note: 'Feeds twice daily',
          }],
        };
      }
      if (sql.includes('UPDATE planned_absence_pets')) {
        if (sql.includes('pet_note')) petNoteColumnTouched = true;
        expect(params[0]).toBeNull();
        cleared = true;
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('updated_at = NOW()')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
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
      .send({
        pet_carers: [{ pet_id: petId, carer_kind: null }],
      });

    expect(res.statusCode).toBe(200);
    expect(petNoteColumnTouched).toBe(false);
    expect(res.body.absence.pet_carers[0]).toMatchObject({
      carer_kind: null,
      pet_note: 'Feeds twice daily',
    });
  });

  it('PATCH pet_note: null clears the note without touching carer', async () => {
    let noteCleared = false;
    let carerColumnsTouched = false;
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: 'shared_user',
            carer_user_id: carerUserId,
            carer_name: null,
            carer_note: null,
            pet_note: noteCleared ? null : 'Feeds twice daily',
          }],
        };
      }
      if (sql.includes('UPDATE planned_absence_pets')) {
        if (sql.includes('carer_kind')) carerColumnsTouched = true;
        expect(params[0]).toBeNull();
        noteCleared = true;
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('updated_at = NOW()')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('FROM planned_absences pa')) {
        return { rows: [] };
      }
      if (sql.includes('FROM users') && sql.includes('id = ANY')) {
        return { rows: [{ id: carerUserId, first_name: 'Sarah', last_name: 'Miller' }] };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set(authHeader())
      .send({
        pet_carers: [{ pet_id: petId, pet_note: null }],
      });

    expect(res.statusCode).toBe(200);
    expect(carerColumnsTouched).toBe(false);
    expect(res.body.absence.pet_carers[0]).toMatchObject({
      carer_kind: 'shared_user',
      pet_note: null,
    });
  });

  it('PATCH pet_note is stored and returned verbatim (D-AWAY-008)', async () => {
    const verbatimNote = 'Feeds twice daily — **not parsed**\nline 2';
    const app = createTransactionalTestApp(async (sql, params) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: null,
            carer_user_id: null,
            carer_name: null,
            carer_note: null,
            pet_note: verbatimNote,
          }],
        };
      }
      if (sql.includes('UPDATE planned_absence_pets')) {
        expect(params[0]).toBe(verbatimNote);
        return { rows: [] };
      }
      if (sql.includes('UPDATE planned_absences') && sql.includes('updated_at = NOW()')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('DELETE FROM planned_absence_pets')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO planned_absence_pets')) {
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
      .send({ pet_carers: [{ pet_id: petId, pet_note: verbatimNote }] });

    expect(res.statusCode).toBe(200);
    expect(res.body.absence.pet_carers[0].pet_note).toBe(verbatimNote);
  });

  it('GET absence marks shared_user with null user_id as carer_removed', async () => {
    const app = createTestApp(async (sql) => {
      if (sql.includes('FROM planned_absences WHERE id = $1 AND user_id = $2')) {
        return { rows: [absenceRow()] };
      }
      if (sql.includes('SELECT pet_id, carer_kind')) {
        return {
          rows: [{
            pet_id: petId,
            carer_kind: 'shared_user',
            carer_user_id: null,
            carer_name: null,
            carer_note: null,
          }],
        };
      }
      return { rows: [] };
    });

    const res = await request(app)
      .get(`/api/planned-absences/${absenceId}`)
      .set(authHeader());

    expect(res.statusCode).toBe(200);
    expect(res.body.pet_carers[0].carer_removed).toBe(true);
  });
});

function createTestApp(handler) {
  return createApp(createMockPool(handler));
}

function createTransactionalTestApp(handler) {
  return createApp(createTransactionalMockPool(handler));
}
