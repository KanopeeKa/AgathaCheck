import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';
import { createMockPool, makePetRow, token, userId, petId } from './helpers.js';

describe('Pets API', () => {
  describe('Ownership / cross-user access', () => {
    it('GET /api/pets/:id scopes the query to the authenticated user', async () => {
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
          capturedParams = params;
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('EXISTS') && sql.includes('AS is_foster') && sql.includes('WHERE p.id = $1')) {
          return { rows: [makePetRow()] };
        }
        return { rows: [] };
      }));
      await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(capturedParams[0]).toBe(petId);
      expect(capturedParams[1]).toBe(userId);
    });

    it('GET /api/pets/:id returns 404 when the pet belongs to another user', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .get(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Pet not found');
    });

    it('PUT /api/pets/:id scopes the update to the pet id', async () => {
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('SELECT organization_id FROM pets WHERE id = $1')) {
          return { rows: [{ organization_id: null }] };
        }
        if (sql.includes('UPDATE pets SET')) {
          capturedParams = params;
          return { rows: [makePetRow()] };
        }
        return { rows: [] };
      }));
      await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(capturedParams).toContain(petId);
    });

    it('PUT /api/pets/:id returns 404 when the pet belongs to another user', async () => {
      const app = createApp(createMockPool(async () => ({ rows: [] })));
      const res = await request(app)
        .put(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'X', species: 'dog' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('error', 'Pet not found');
    });

    it('DELETE /api/pets/:id scopes the delete to the authenticated user', async () => {
      let capturedParams;
      const app = createApp(createMockPool(async (sql, params) => {
        const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId] });
        if (access) return access;
        if (sql.includes('DELETE FROM pets')) {
          capturedParams = params;
          return { rows: [] };
        }
        return { rows: [] };
      }));
      await request(app)
        .delete(`/api/pets/${petId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(capturedParams[0]).toBe(petId);
      expect(capturedParams[1]).toBe(userId);
    });
  });
});
