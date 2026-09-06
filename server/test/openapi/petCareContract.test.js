import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import {
  loadPetCareCriticalSpec,
  responseSchema,
} from '../../lib/openapi/petCareCriticalSpec.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, petId, token, userId } from '../pets/helpers.js';

const spec = loadPetCareCriticalSpec();

function assertResponse(pathKey, method, status, body) {
  const schema = responseSchema(spec, pathKey, method, status);
  if (!schema) throw new Error(`No schema for ${method} ${pathKey} ${status}`);
  assertMatchesSchema(spec, schema, body);
}

describe('Pet Care OpenAPI contract (F-14)', () => {
  it('GET /api/pets/:id matches Pet schema', async () => {
    const row = makePetRow();
    const app = createApp(
      createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('AS is_foster') && sql.includes('WHERE p.id = $1')) {
          return { rows: [row] };
        }
        return { rows: [] };
      }),
    );
    const res = await request(app)
      .get(`/api/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    assertResponse('/pets/{id}', 'get', 200, res.body);
  });

  it('POST /api/pets matches Pet schema', async () => {
    const returnedRow = makePetRow();
    const app = createApp(
      createMockPool(async (sql) => {
        if (sql.includes('organization_users')) return { rows: [{ '?column?': 1 }] };
        if (sql.includes('FROM weight_entries')) return { rows: [] };
        if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
        if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
        if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
        if (sql.includes('INSERT INTO pets')) return { rows: [returnedRow] };
        return { rows: [] };
      }),
    );
    const res = await request(app)
      .post('/api/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Fluffy', species: 'cat' });
    expect(res.statusCode).toBe(201);
    assertResponse('/pets', 'post', 201, res.body);
  });

  it('DELETE /api/pets/:id matches DeletePetResponse schema', async () => {
    const app = createApp(
      createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
        if (sql.includes('SELECT photo_path FROM pets')) return { rows: [{ photo_path: null }] };
        if (sql.includes('FROM health_event_photos')) return { rows: [] };
        if (sql.includes('FROM health_issue_documents')) return { rows: [] };
        if (sql.startsWith('DELETE FROM ')) return { rowCount: 0 };
        if (sql.includes('UPDATE pets')) return { rows: [] };
        if (sql.includes('DELETE FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO audit_events')) return { rows: [] };
        return { rows: [] };
      }),
    );
    const res = await request(app)
      .delete(`/api/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    assertResponse('/pets/{id}', 'delete', 200, res.body);
  });

  it('DELETE /api/pets/:id/data matches PetDataDeleteResponse schema', async () => {
    const app = createApp(
      createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
        if (sql.includes('SELECT photo_path FROM pets')) return { rows: [{ photo_path: null }] };
        if (sql.includes('FROM health_event_photos')) return { rows: [] };
        if (sql.includes('FROM health_issue_documents')) return { rows: [] };
        if (sql.startsWith('DELETE FROM ')) return { rowCount: 1 };
        if (sql.includes('UPDATE pets')) return { rows: [] };
        if (sql.includes('INSERT INTO audit_events')) return { rows: [] };
        return { rows: [] };
      }),
    );
    const res = await request(app)
      .delete(`/api/pets/${petId}/data`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    assertResponse('/pets/{id}/data', 'delete', 200, res.body);
  });

  it('POST /api/pets/:id/passed-away matches PassedAwayResponse schema', async () => {
    const app = createApp(
      createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT name FROM pets WHERE id = $1')) {
          return { rows: [{ name: 'Fluffy' }] };
        }
        if (sql.includes('FROM pet_access pa')) return { rows: [{ user_id: 'collab-1' }] };
        if (sql.includes('FROM users WHERE id')) {
          return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
        }
        if (sql.includes('INSERT INTO notifications')) return { rows: [] };
        return { rows: [] };
      }),
    );
    const res = await request(app)
      .post(`/api/pets/${petId}/passed-away`)
      .set('Authorization', `Bearer ${token}`)
      .send({ pet_name: 'Fluffy' });
    expect(res.statusCode).toBe(200);
    assertResponse('/pets/{id}/passed-away', 'post', 200, res.body);
  });
});
