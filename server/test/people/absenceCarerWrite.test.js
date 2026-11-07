import { describe, expect, it } from '@jest/globals';

import { CARER_KIND_SHARED_USER } from '../../lib/care/plannedAbsence.js';
import { resolveCarerWrite } from '../../lib/people/absenceCarer.js';

const travellerId = '11111111-1111-4111-8111-111111111111';
const actorId = '22222222-2222-4222-8222-222222222222';
const petId = '33333333-3333-4333-8333-333333333333';
const carerId = '44444444-4444-4444-8444-444444444444';
const contactId = '55555555-5555-4555-8555-555555555555';

describe('resolveCarerWrite actor vs traveller', () => {
  it('rejects assigning the traveller as shared_user carer', async () => {
    const pool = {
      query: async (sql) => {
        if (sql.includes('FROM pets')) return { rows: [{ user_id: travellerId }] };
        if (sql.includes('FROM pet_access')) return { rows: [{ user_id: carerId }] };
        return { rows: [] };
      },
    };
    const result = await resolveCarerWrite(pool, {
      actorUserId: actorId,
      travellerUserId: travellerId,
      petId,
      item: { carer_kind: CARER_KIND_SHARED_USER, carer_user_id: travellerId },
    });
    expect(result.ok).toBe(false);
    expect(result.status).toBe(400);
  });

  it('does not copy private contact note into carer_note when actor is not traveller', async () => {
    const pool = {
      query: async (sql, params) => {
        if (sql.includes('FROM pets')) return { rows: [{ user_id: travellerId }] };
        if (sql.includes('FROM people_contacts')) {
          return {
            rows: [{
              id: contactId,
              name: 'Vet',
              linked_user_id: null,
              inactive_at: null,
              private_note: 'secret',
            }],
          };
        }
        if (sql.includes('people_contact_private_notes')) {
          expect(params[1]).toBe(actorId);
        }
        return { rows: [] };
      },
    };
    const result = await resolveCarerWrite(pool, {
      actorUserId: actorId,
      travellerUserId: travellerId,
      petId,
      item: { contact_id: contactId },
    });
    expect(result.ok).toBe(true);
    expect(result.carer_note).toBeNull();
  });
});
