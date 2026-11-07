import { describe, expect, it } from '@jest/globals';

import { CARER_KIND_NOTE_ONLY } from '../../lib/care/plannedAbsence.js';
import { updateAbsenceCarers } from '../../routes/careContext/plannedAbsenceStore.js';

const absenceId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const petId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const contactId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const travellerId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const coParentId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';

describe('updateAbsenceCarers unchanged contact_id', () => {
  it('does not re-resolve carer when contact_id is unchanged (pet_note-only patch)', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT carer_user_id, contact_id')) {
          return {
            rows: [{
              carer_user_id: null,
              contact_id: contactId,
              carer_kind: CARER_KIND_NOTE_ONLY,
              carer_name: 'Handover carer',
              carer_note: 'traveller private note',
            }],
          };
        }
        if (sql.includes('UPDATE planned_absence_pets SET pet_note')) {
          updates.push({ sql, params });
          return { rows: [] };
        }
        if (sql.includes('people_contacts') || sql.includes('contactUsableForPet')) {
          throw new Error('resolveCarerWrite should not run for unchanged contact_id');
        }
        return { rows: [] };
      },
    };

    const result = await updateAbsenceCarers(
      pool,
      absenceId,
      [{ pet_id: petId, contact_id: contactId, pet_note: 'Buddy gets pills' }],
      [petId],
      { actorUserId: coParentId, travellerUserId: travellerId },
    );

    expect(result.ok).toBe(true);
    expect(updates).toHaveLength(1);
    expect(updates[0].params[0]).toBe('Buddy gets pills');
  });

  it('allows traveller to save pet_note when contact was chosen by a co-parent', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('SELECT carer_user_id, contact_id')) {
          return {
            rows: [{
              carer_user_id: null,
              contact_id: contactId,
            }],
          };
        }
        if (sql.includes('UPDATE planned_absence_pets SET pet_note')) {
          updates.push(params);
          return { rows: [] };
        }
        if (sql.includes('FROM people_contacts')) {
          return { ok: false };
        }
        return { rows: [] };
      },
    };

    const result = await updateAbsenceCarers(
      pool,
      absenceId,
      [{ pet_id: petId, contact_id: contactId, pet_note: 'Updated note' }],
      [petId],
      { actorUserId: travellerId, travellerUserId: travellerId },
    );

    expect(result.ok).toBe(true);
    expect(updates).toEqual([['Updated note', absenceId, petId]]);
  });
});
