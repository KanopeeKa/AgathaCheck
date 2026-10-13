import { describe, expect, it } from '@jest/globals';
import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  loadPetCareCriticalSpec,
  responseSchema,
} from '../../lib/openapi/petCareCriticalSpec.js';
import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import { vetVisitToMap } from '../../lib/pets/vetVisits.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import {
  createMockPool,
  makePetRow,
  petId,
  token,
  userId,
} from '../pets/helpers.js';

const spec = loadPetCareCriticalSpec();

function assertResponse(pathKey, method, status, body) {
  const schema = responseSchema(spec, pathKey, method, status);
  if (!schema) throw new Error(`No schema for ${method} ${pathKey} ${status}`);
  assertMatchesSchema(spec, schema, body);
}

const entryId = 'e1000001-0001-4001-8001-000000000001';
const occId = 'o1000001-0001-4001-8001-000000000001';
const visitId = 'v1000001-0001-4001-8001-000000000001';

function makeVisitRow(overrides = {}) {
  return {
    id: visitId,
    pet_id: petId,
    visited_on: '2026-10-01',
    status: 'open',
    completed_on: null,
    notes: '',
    created_by: userId,
    created_at: new Date('2026-10-01T12:00:00.000Z'),
    updated_at: new Date('2026-10-01T12:00:00.000Z'),
    ...overrides,
  };
}

function makeOccurrenceRow(overrides = {}) {
  return {
    occurrence_id: occId,
    health_entry_id: entryId,
    status: 'pending',
    scheduled_date: '2026-10-01',
    ...overrides,
  };
}

describe('vet visit helpers', () => {
  it('vetVisitToMap uses calendar dates on the wire', () => {
    const map = vetVisitToMap(makeVisitRow(), []);
    expect(map.visited_on).toBe('2026-10-01');
    expect(map.completed_on).toBeNull();
    expect(map.linked_occurrences).toEqual([]);
  });
});

describe('vet visit API (ACJ-VV-01 / AC-VV-01)', () => {
  it('ACJ-VV-01 POST occurrence-links returns OpenAPI PetVetVisit with link summaries', async () => {
    const visits = [makeVisitRow()];
    const links = [];
    const occurrences = [makeOccurrenceRow()];

    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [petId],
        healthEdit: true,
      });
      if (access) return access;

      if (sql.includes('SELECT id FROM pets WHERE id = $1')) {
        return { rows: [{ id: petId }] };
      }
      if (sql.includes('FROM vet_visits WHERE id = $1 AND pet_id = $2') && sql.includes('status')) {
        return { rows: [visits[0]] };
      }
      if (sql.includes('FROM vet_visits WHERE id = $1 AND pet_id = $2')) {
        return { rows: [visits[0]] };
      }
      if (sql.includes('he.pet_id = $1 AND ho.id = ANY')) {
        return { rows: [{ id: occId }] };
      }
      if (sql.includes('FROM vet_visit_occurrence_links') && sql.includes('health_occurrence_id = ANY')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO vet_visit_occurrence_links')) {
        links.push({ vet_visit_id: params[1], health_occurrence_id: params[2] });
        return { rows: [] };
      }
      if (sql.includes('FROM vet_visit_occurrence_links l')) {
        return { rows: occurrences };
      }
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [makePetRow()] };
      }
      return null;
    });

    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/pets/${petId}/vet-visits/${visitId}/occurrence-links`)
      .set('Authorization', `Bearer ${token}`)
      .send({ occurrence_ids: [occId] });

    expect(res.statusCode).toBe(200);
    expect(res.body.linked_occurrences).toHaveLength(1);
    expect(res.body.linked_occurrences[0].occurrence_id).toBe(occId);
    assertResponse(
      '/pets/{id}/vet-visits/{visitId}/occurrence-links',
      'post',
      200,
      res.body,
    );
  });
});

describe('vet visit completion (AC-FB-02)', () => {
  it('AC-FB-02 completing a visit does not UPDATE linked health_occurrences', async () => {
    const visits = [makeVisitRow()];
    const occurrenceUpdates = [];
    const occurrences = [makeOccurrenceRow()];

    const pool = createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, {
        userId,
        ownedPetIds: [petId],
        healthEdit: true,
      });
      if (access) return access;

      if (sql.includes('UPDATE health_occurrences')) {
        occurrenceUpdates.push({ sql, params });
        return { rows: [] };
      }
      if (sql.includes('SELECT * FROM vet_visits WHERE id = $1 AND pet_id = $2')) {
        return { rows: [visits[0]] };
      }
      if (sql.includes('UPDATE vet_visits')) {
        visits[0] = {
          ...visits[0],
          status: 'completed',
          completed_on: params[2],
          updated_at: new Date('2026-10-02T12:00:00.000Z'),
        };
        return { rows: [visits[0]] };
      }
      if (sql.includes('FROM vet_visit_occurrence_links l')) {
        return { rows: occurrences };
      }
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) {
        return { rows: [makePetRow()] };
      }
      return null;
    });

    const app = createApp(pool);
    const res = await request(app)
      .post(`/api/pets/${petId}/vet-visits/${visitId}/complete`)
      .set('Authorization', `Bearer ${token}`)
      .send({ completed_on: '2026-10-02' });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('completed');
    expect(res.body.completed_on).toBe('2026-10-02');
    expect(res.body.linked_occurrences[0].status).toBe('pending');
    expect(occurrenceUpdates).toHaveLength(0);
    assertResponse(
      '/pets/{id}/vet-visits/{visitId}/complete',
      'post',
      200,
      res.body,
    );
  });
});
