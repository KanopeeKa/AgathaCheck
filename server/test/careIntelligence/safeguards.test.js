import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { evaluateWeightSafeguard } from '../../routes/careIntelligence/weightSafeguardEvaluator.js';
import {
  evidenceFingerprint,
  safeguardToMap,
} from '../../routes/careIntelligence/safeguardsService.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

const decliningSeries = [
  { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
  { date: '2026-01-20', weight: 5.7, unit: 'kg', measurement_source: 'guardian' },
  { date: '2026-02-10', weight: 5.3, unit: 'kg', measurement_source: 'guardian' },
  { date: '2026-03-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
];

describe('weightSafeguardEvaluator', () => {
  it('surfaces weight trend down safeguard when review relevant', () => {
    const result = evaluateWeightSafeguard({
      pet: { id: 'pet-1', date_of_birth: '2018-01-01' },
      measurements: decliningSeries,
      weightContext: {
        management_context: 'none',
        reference_authority: null,
        reference_value: null,
      },
    });
    expect(result).not.toBeNull();
    expect(result.safeguard_type).toBe('weight_trend_down');
    expect(result.copy_key).toBe('careSafeguardWeightTrendDown');
  });

  it('does not surface when management context explains change', () => {
    const result = evaluateWeightSafeguard({
      pet: { id: 'pet-1', date_of_birth: '2018-01-01' },
      measurements: decliningSeries,
      weightContext: {
        management_context: 'vet_managed',
        reference_authority: 'vet_target',
        reference_value: 5.0,
      },
    });
    expect(result).toBeNull();
  });

  it('does not surface with insufficient measurements', () => {
    const result = evaluateWeightSafeguard({
      pet: { id: 'pet-1', date_of_birth: '2018-01-01' },
      measurements: decliningSeries.slice(0, 1),
      weightContext: { management_context: 'none' },
    });
    expect(result).toBeNull();
  });
});

describe('safeguardToMap', () => {
  it('maps row to API shape', () => {
    const mapped = safeguardToMap({
      id: 'sg-1',
      pet_id: 'pet-1',
      safeguard_type: 'weight_trend_down',
      safeguard_key: 'weight_trend_down:pet-1',
      status: 'active',
      policy_version: '1.0.0',
      copy_key: 'careSafeguardWeightTrendDown',
      evidence_json: { measurement_count: 4 },
      dismissed_at: null,
      created_at: '2026-09-09T00:00:00Z',
      updated_at: '2026-09-09T00:00:00Z',
    });
    expect(mapped.evidence.measurement_count).toBe(4);
    expect(mapped.status).toBe('active');
  });
});

describe('evidenceFingerprint', () => {
  it('is stable for equivalent evidence', () => {
    const a = evidenceFingerprint({
      measurement_count: 4,
      direction: 'down',
      classification: 'unexplained_material',
    });
    const b = evidenceFingerprint({
      measurement_count: 4,
      direction: 'down',
      classification: 'unexplained_material',
      reasons: ['extra'],
    });
    expect(a).toBe(b);
  });
});

describe('Care safeguards API', () => {
  let app;
  let safeguards;
  let weightEntries;
  let pets;

  beforeAll(() => {
    safeguards = [];
    weightEntries = [];
    pets = [{
      id: 'pet-1',
      species: 'Dog',
      date_of_birth: '2018-01-01',
      weight_management_context: 'none',
      weight_reference_authority: null,
      weight_reference_value: null,
    }];

    const mockPool = {
      query: async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, {
          userId,
          ownedPetIds: ['pet-1'],
        });
        if (access) return access;

        if (sql.includes('FROM pets p') && sql.includes('WHERE p.id')) {
          const pet = pets.find((p) => p.id === params[0]);
          return { rows: pet ? [pet] : [] };
        }

        if (sql.includes('FROM weight_entries') && sql.includes('WHERE pet_id')) {
          return { rows: weightEntries.filter((w) => w.pet_id === params[0]) };
        }

        if (sql.includes('FROM care_safeguards WHERE pet_id = $1')
          && !sql.includes('DELETE') && !sql.includes('UPDATE')) {
          return { rows: safeguards.filter((s) => s.pet_id === params[0]) };
        }

        if (sql.includes('DELETE FROM care_safeguards')) {
          safeguards = safeguards.filter(
            (s) => !(s.pet_id === params[0] && s.status === 'active'),
          );
          return { rows: [] };
        }

        if (sql.includes('INSERT INTO care_safeguards')) {
          const row = {
            id: params[0],
            pet_id: params[1],
            safeguard_type: params[2],
            safeguard_key: params[3],
            status: 'active',
            policy_version: params[4],
            copy_key: params[5],
            evidence_json: JSON.parse(params[6]),
            dismissed_at: null,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          };
          const idx = safeguards.findIndex(
            (s) => s.pet_id === row.pet_id && s.safeguard_key === row.safeguard_key,
          );
          if (idx >= 0) {
            safeguards[idx] = { ...safeguards[idx], ...row };
            return { rows: [safeguards[idx]] };
          }
          safeguards.push(row);
          return { rows: [row] };
        }

        if (sql.includes('UPDATE care_safeguards') && sql.includes("status = 'dismissed'")) {
          const idx = safeguards.findIndex(
            (s) => s.id === params[1] && s.pet_id === params[2] && s.status === 'active',
          );
          if (idx < 0) return { rows: [] };
          safeguards[idx] = {
            ...safeguards[idx],
            status: 'dismissed',
            dismissed_at: new Date().toISOString(),
            evidence_json: JSON.parse(params[0]),
          };
          return { rows: [safeguards[idx]] };
        }

        if (sql.includes('UPDATE care_safeguards') && sql.includes('evidence_json = $1')) {
          const idParam = sql.includes('dismissed_at = NULL') ? params[3] : params[3];
          const idx = safeguards.findIndex((s) => s.id === idParam);
          if (idx < 0) return { rows: [] };
          safeguards[idx] = {
            ...safeguards[idx],
            evidence_json: JSON.parse(params[0]),
            policy_version: params[1],
            copy_key: params[2],
            ...(sql.includes("status = 'active'") ? { status: 'active', dismissed_at: null } : {}),
          };
          return { rows: [safeguards[idx]] };
        }

        if (sql.includes('SELECT * FROM care_safeguards')
          && sql.includes("status = 'active'")) {
          const row = safeguards.find(
            (s) => s.id === params[0] && s.pet_id === params[1] && s.status === 'active',
          );
          return { rows: row ? [row] : [] };
        }

        return { rows: [] };
      },
    };

    app = createApp(mockPool);
  });

  beforeEach(() => {
    safeguards = [];
    weightEntries = [
      { pet_id: 'pet-1', weight: 6.0, unit: 'kg', date: '2026-01-01', measurement_source: 'guardian' },
      { pet_id: 'pet-1', weight: 5.7, unit: 'kg', date: '2026-01-20', measurement_source: 'guardian' },
      { pet_id: 'pet-1', weight: 5.3, unit: 'kg', date: '2026-02-10', measurement_source: 'guardian' },
      { pet_id: 'pet-1', weight: 5.0, unit: 'kg', date: '2026-03-01', measurement_source: 'guardian' },
    ];
  });

  it('GET returns active safeguard when weight trend qualifies', async () => {
    const res = await request(app)
      .get('/api/pets/pet-1/care-safeguards')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].safeguard_type).toBe('weight_trend_down');
  });

  it('POST dismiss marks safeguard dismissed', async () => {
    const list = await request(app)
      .get('/api/pets/pet-1/care-safeguards')
      .set('Authorization', `Bearer ${token}`);
    const safeguardId = list.body[0].id;

    const dismiss = await request(app)
      .post(`/api/pets/pet-1/care-safeguards/${safeguardId}/dismiss`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(dismiss.status).toBe(200);
    expect(dismiss.body.status).toBe('dismissed');

    const after = await request(app)
      .get('/api/pets/pet-1/care-safeguards')
      .set('Authorization', `Bearer ${token}`);
    expect(after.body).toHaveLength(0);
  });
});
