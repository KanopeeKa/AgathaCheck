import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import {
  evaluateCareRecommendationCandidates,
  hasActiveRecurringCare,
} from '../../routes/careIntelligence/ruleEngine.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makePet(overrides = {}) {
  return {
    id: 'pet-1',
    species: 'Dog',
    date_of_birth: new Date('2020-01-01'),
    ...overrides,
  };
}

describe('care intelligence rule engine', () => {
  const now = new Date('2026-09-07');

  test('does not suggest for unsupported species', () => {
    const candidates = evaluateCareRecommendationCandidates({
      pet: makePet({ species: 'Rabbit' }),
      healthEntries: [],
      existingRecommendations: [],
      now,
    });
    expect(candidates).toHaveLength(0);
  });

  test('suggests three families for adult dog without established rhythms', () => {
    const candidates = evaluateCareRecommendationCandidates({
      pet: makePet(),
      healthEntries: [],
      existingRecommendations: [],
      now,
    });
    expect(candidates.map((c) => c.care_family).sort()).toEqual([
      'dental',
      'weight_monitoring',
      'wellness_review',
    ]);
  });

  test('hasActiveRecurringCare detects recurring family', () => {
    expect(hasActiveRecurringCare([
      { frequency: 'monthly', care_family: 'weight_monitoring' },
    ], 'weight_monitoring')).toBe(true);
    expect(hasActiveRecurringCare([
      { frequency: 'once', care_family: 'weight_monitoring' },
    ], 'weight_monitoring')).toBe(false);
  });

  test('suppresses when active recurring care exists for family', () => {
    const candidates = evaluateCareRecommendationCandidates({
      pet: makePet(),
      healthEntries: [{
        frequency: 'monthly',
        care_family: 'weight_monitoring',
      }],
      existingRecommendations: [],
      now,
    });
    expect(candidates.some((c) => c.care_family === 'weight_monitoring')).toBe(false);
  });

  test('suppresses when vet cadence exists for family', () => {
    const candidates = evaluateCareRecommendationCandidates({
      pet: makePet(),
      healthEntries: [{
        frequency: 'yearly',
        care_family: 'dental',
        care_source: 'vet_instruction',
      }],
      existingRecommendations: [],
      now,
    });
    expect(candidates.some((c) => c.care_family === 'dental')).toBe(false);
  });

  test('suppresses when not_relevant recorded for family', () => {
    const candidates = evaluateCareRecommendationCandidates({
      pet: makePet(),
      healthEntries: [],
      existingRecommendations: [{
        care_family: 'wellness_review',
        status: 'not_relevant',
      }],
      now,
    });
    expect(candidates.some((c) => c.care_family === 'wellness_review')).toBe(false);
  });
});

describe('Care recommendations API', () => {
  let app;
  let recommendations;
  let healthEntries;
  let pets;

  beforeAll(() => {
    recommendations = [];
    healthEntries = [];
    pets = [makePet()];

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

        if (sql.includes('FROM health_entries he') && sql.includes('WHERE he.pet_id')) {
          return {
            rows: healthEntries.filter((e) => e.pet_id === params[0]),
          };
        }

        if (sql.includes('FROM care_recommendations WHERE pet_id = $1')
          && !sql.includes('care_family')) {
          return {
            rows: recommendations.filter((r) => r.pet_id === params[0]),
          };
        }

        if (sql.includes('FROM care_recommendations')
          && sql.includes('care_family = $2')) {
          const row = recommendations.find((r) => (
            r.pet_id === params[0]
            && r.care_family === params[1]
            && r.suggestion_key === params[2]
          ));
          return { rows: row ? [row] : [] };
        }

        if (sql.includes('INSERT INTO care_recommendations')) {
          const row = {
            id: params[0],
            pet_id: params[1],
            care_family: params[2],
            suggestion_key: params[3],
            status: params[4],
            engine_version: params[5],
            knowledge_version: params[6],
            suggested_name: params[7],
            suggested_frequency: params[8],
            suggested_frequency_interval: params[9],
            suggested_health_entry_type: params[10],
            rationale_key: params[11],
            health_entry_id: null,
            responded_at: null,
            created_at: new Date(),
            updated_at: new Date(),
          };
          recommendations.push(row);
          return { rows: [row] };
        }

        if (sql.includes('FROM care_recommendations WHERE id = $1')) {
          const row = recommendations.find((r) => r.id === params[0] && r.pet_id === params[1]);
          return { rows: row ? [row] : [] };
        }

        if (sql.includes('INSERT INTO health_entries')) {
          const row = {
            id: params[0],
            pet_id: params[1],
            care_family: params[9],
            care_source: params[10],
          };
          healthEntries.push(row);
          return { rows: [row] };
        }

        if (sql.includes('UPDATE care_recommendations')) {
          const row = recommendations.find((r) => r.id === params[params.length - 1]);
          if (!row) return { rows: [] };
          if (sql.includes('health_entry_id')) {
            row.status = params[0];
            row.health_entry_id = params[1];
          } else {
            row.status = params[0];
          }
          row.responded_at = new Date();
          return { rows: [row] };
        }

        if (sql.includes('materialise') || sql.includes('occurrence')) {
          return { rows: [] };
        }

        return { rows: [] };
      },
    };

    app = createApp(mockPool);
  });

  test('GET returns pending recommendations for eligible pet', async () => {
    const res = await request(app)
      .get('/api/pets/pet-1/care-recommendations')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
    expect(res.body[0].status).toBe('pending');
  });

  test('POST accept creates rhythm and is idempotent', async () => {
    const list = await request(app)
      .get('/api/pets/pet-1/care-recommendations')
      .set('Authorization', `Bearer ${token}`);
    const recId = list.body[0].id;

    const accepted = await request(app)
      .post(`/api/pets/pet-1/care-recommendations/${recId}/respond`)
      .set('Authorization', `Bearer ${token}`)
      .send({ action: 'accept' });
    expect(accepted.status).toBe(200);
    expect(accepted.body.status).toBe('accepted');
    expect(accepted.body.health_entry_id).toBeTruthy();
    expect(healthEntries.length).toBe(1);

    const again = await request(app)
      .post(`/api/pets/pet-1/care-recommendations/${recId}/respond`)
      .set('Authorization', `Bearer ${token}`)
      .send({ action: 'accept' });
    expect(again.status).toBe(200);
    expect(healthEntries.length).toBe(1);
  });
});
