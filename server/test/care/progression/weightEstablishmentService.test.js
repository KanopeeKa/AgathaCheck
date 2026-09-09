import {
  establishmentToDto,
  maybePersistWeightEstablishment,
} from '../../../lib/care/progression/weightEstablishmentService.js';
import { WEIGHT_ESTABLISHMENT_POLICY_VERSION } from '../../../lib/care/progression/weightEstablishmentPolicy.js';

const petId = 'pet-1';
const healthEntryId = 'he-weight';

function makePool(handlers) {
  return {
    query: async (sql, params) => {
      for (const handler of handlers) {
        const result = await handler(sql, params);
        if (result !== undefined) return result;
      }
      throw new Error(`Unhandled query: ${sql}`);
    },
  };
}

describe('weightEstablishmentService', () => {
  it('maps establishment rows to API DTOs', () => {
    const dto = establishmentToDto({
      id: 'est-1',
      care_family: 'weight_monitoring',
      health_entry_id: healthEntryId,
      established_at: new Date('2026-09-09T12:00:00.000Z'),
      policy_version: WEIGHT_ESTABLISHMENT_POLICY_VERSION,
    });
    expect(dto).toEqual({
      id: 'est-1',
      care_family: 'weight_monitoring',
      health_entry_id: healthEntryId,
      established_at: '2026-09-09T12:00:00.000Z',
      policy_version: WEIGHT_ESTABLISHMENT_POLICY_VERSION,
    });
  });

  it('persists establishment on first eligible transition', async () => {
    let inserted = false;
    const pool = makePool([
      (sql) => {
        if (sql.includes('FROM health_entries') && sql.includes('pet_id = $2')) {
          return {
            rows: [{
              id: healthEntryId,
              pet_id: petId,
              care_family: 'weight_monitoring',
              status: 'active',
              frequency: 'weekly',
              frequency_interval: 1,
            }],
          };
        }
        return undefined;
      },
      (sql) => {
        if (sql.includes('FROM care_establishments') && sql.includes('health_entry_id = $1')) {
          return { rows: inserted ? [{ id: 'est-1' }] : [] };
        }
        return undefined;
      },
      (sql) => {
        if (sql.includes('FROM health_occurrences ho')) {
          return {
            rows: [
              { id: 'o1', status: 'completed', completed_on: '2026-06-01', scheduled_date: '2026-06-01', weight_id: 'w1', date: '2026-06-01', weight: 10, unit: 'kg', measurement_source: 'guardian' },
              { id: 'o2', status: 'completed', completed_on: '2026-06-08', scheduled_date: '2026-06-08', weight_id: 'w2', date: '2026-06-08', weight: 11, unit: 'kg', measurement_source: 'guardian' },
              { id: 'o3', status: 'completed', completed_on: '2026-06-15', scheduled_date: '2026-06-15', weight_id: 'w3', date: '2026-06-15', weight: 12, unit: 'kg', measurement_source: 'guardian' },
              { id: 'o4', status: 'completed', completed_on: '2026-06-22', scheduled_date: '2026-06-22', weight_id: 'w4', date: '2026-06-22', weight: 13, unit: 'kg', measurement_source: 'guardian' },
            ],
          };
        }
        return undefined;
      },
      (sql) => {
        if (sql.includes('INSERT INTO care_establishments')) {
          inserted = true;
          return {
            rows: [{
              id: 'est-1',
              pet_id: petId,
              care_family: 'weight_monitoring',
              health_entry_id: healthEntryId,
              established_at: new Date('2026-09-09T12:00:00.000Z'),
              policy_version: WEIGHT_ESTABLISHMENT_POLICY_VERSION,
            }],
          };
        }
        return undefined;
      },
    ]);

    const outcome = await maybePersistWeightEstablishment(pool, { petId, healthEntryId });
    expect(outcome.persisted).toBe(true);
    expect(outcome.establishment.policy_version).toBe(WEIGHT_ESTABLISHMENT_POLICY_VERSION);
    expect(outcome.evaluation.maturity).toBe('established');
  });

  it('does not persist when evidence is insufficient', async () => {
    const pool = makePool([
      (sql) => {
        if (sql.includes('FROM health_entries')) {
          return {
            rows: [{
              id: healthEntryId,
              pet_id: petId,
              care_family: 'weight_monitoring',
              status: 'active',
              frequency: 'weekly',
              frequency_interval: 1,
            }],
          };
        }
        return undefined;
      },
      (sql) => {
        if (sql.includes('FROM care_establishments')) return { rows: [] };
        return undefined;
      },
      (sql) => {
        if (sql.includes('FROM health_occurrences ho')) {
          return {
            rows: [
              { id: 'o1', status: 'completed', completed_on: '2026-06-01', scheduled_date: '2026-06-01', weight_id: 'w1', date: '2026-06-01', weight: 10, unit: 'kg', measurement_source: 'guardian' },
            ],
          };
        }
        return undefined;
      },
    ]);

    const outcome = await maybePersistWeightEstablishment(pool, { petId, healthEntryId });
    expect(outcome.persisted).toBe(false);
    expect(outcome.establishment).toBeNull();
    expect(outcome.evaluation.maturity).toBeNull();
  });
});
