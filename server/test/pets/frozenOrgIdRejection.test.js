import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, makePetRow, token, petId, userId } from './helpers.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';

describe('Pets API frozen org linkage', () => {
  it('POST /api/pets rejects organization_id when frozen domains are off', async () => {
    const app = createApp(createMockPool(async () => ({ rows: [] })));
    const res = await request(app)
      .post('/api/pets')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Fluffy', species: 'cat', organization_id: 'org-uuid-1' });

    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/organization_id is not supported/i);
  });

  it('PUT /api/pets/:id rejects organization_id when frozen domains are off', async () => {
    const app = createApp(createMockPool(async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
      if (access) return access;
      if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
        return { rows: [{ organization_id: null }] };
      }
      return { rows: [] };
    }));

    const res = await request(app)
      .put(`/api/pets/${petId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'X', species: 'dog', organization_id: 'org-uuid-1' });

    expect(res.statusCode).toBe(400);
    expect(res.body.error).toMatch(/organization_id is not supported/i);
  });
});
