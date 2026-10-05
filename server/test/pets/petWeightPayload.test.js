import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId } from './helpers.js';

describe('Pet weight payload via shared service (W1)', () => {
  it('P-2 PUT /api/pets/:id rejects weight 0, -1, and abc with invalid_weight', async () => {
    for (const weight of [0, -1, 'abc']) {
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id, photo_path')) {
          return { rows: [{ organization_id: null, photo_path: null, weight_reference_value: null, weight_reference_authority: null, weight_management_context: 'none', home_timezone: 'UTC' }] };
        }
        return null;
      }));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Fluffy', species: 'cat', weight });
      expect(res.statusCode).toBe(400);
      expect(res.body.code).toBe('invalid_weight');
    }
  });

  it('P-2 POST /api/pets rejects invalid weight before insert', async () => {
    const queries = [];
    const app = createApp(createMockPool(async (sql) => {
      queries.push(sql);
      const access = handlePetAccessQuery(sql, [], { userId, ownedPetIds: [petId] });
      if (access) return access;
      return { rows: [] };
    }));
    const res = await request(app)
      .post('/api/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'New', species: 'cat', weight: 0 });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('invalid_weight');
    expect(queries.some((s) => s.includes('INSERT INTO pets'))).toBe(false);
  });

  it('P-4 POST /api/pets with weight records first weight through service', async () => {
    const queries = [];
    const returnedRow = makePetRow({ weight: 4.2 });
    const app = createApp(createMockPool(async (sql, params) => {
      queries.push(sql);
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('INSERT INTO pets')) return { rows: [returnedRow] };
      if (sql.includes('FROM weight_entries')) return { rows: [] };
      if (sql.includes('INSERT INTO weight_entries')) return { rows: [] };
      if (sql.includes('SELECT home_timezone FROM pets')) return { rows: [{ home_timezone: 'UTC' }] };
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [returnedRow] };
      if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
      return null;
    }));
    const res = await request(app)
      .post('/api/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'New', species: 'cat', weight: 4.2 });
    expect(res.statusCode).toBe(201);
    expect(queries.some((s) => s.includes('INSERT INTO weight_entries'))).toBe(true);
  });

  it('P-3 PUT without weight does not insert a weight row', async () => {
    const queries = [];
    const row = makePetRow();
    const app = createApp(createMockPool(async (sql, params) => {
      queries.push(sql);
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('SELECT organization_id, photo_path')) {
        return { rows: [{ organization_id: null, photo_path: null, weight_reference_value: null, weight_reference_authority: null, weight_management_context: 'none', home_timezone: 'UTC' }] };
      }
      if (sql.includes('UPDATE pets SET')) return { rows: [row] };
      if (sql.includes('SELECT * FROM pets WHERE id = $1')) return { rows: [row] };
      if (sql.includes('UPDATE pets SET weight = (')) return { rows: [] };
      return null;
    }));
    const res = await request(app)
      .put(`/api/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Fluffy', species: 'cat' });
    expect(res.statusCode).toBe(200);
    expect(queries.some((s) => s.includes('INSERT INTO weight_entries'))).toBe(false);
  });
});
