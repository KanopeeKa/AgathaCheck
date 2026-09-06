import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, token, userId, petId } from './helpers.js';

describe('Pets API', () => {
  describe('Extended endpoints', () => {
    let app;
    beforeAll(() => {
      app = createApp(createMockPool());
    });

    const extendedEndpoints = [
      ['POST', `/api/pets/${petId}/transfer`],
      ['POST', `/api/pets/${petId}/transfer-to-org`],
      ['GET', `/api/pets/${petId}/family-events`],
      ['POST', `/api/pets/${petId}/family-events`],
      ['PUT', `/api/pets/${petId}/family-events/1`],
      ['DELETE', `/api/pets/${petId}/family-events/1`],
      ['GET', `/api/pets/${petId}/access`],
      ['PUT', `/api/pets/${petId}/access/user-42/role`],
      ['DELETE', `/api/pets/${petId}/access/user-42`],
      ['DELETE', `/api/pets/${petId}/data`],
      ['POST', `/api/pets/${petId}/passed-away`],
    ];

    extendedEndpoints.forEach(([method, url]) => {
      it(`${method} ${url.replace(petId, ':id')} returns 401 without token`, async () => {
        const res = await request(app)[method.toLowerCase()](url).send({});
        expect(res.statusCode).toBe(401);
        expect(res.body).toHaveProperty('error', 'Unauthorized');
      });
    });

    it('POST /:id/transfer-to-org transfers pet to organization', async () => {
      let updatedOrgId = null;
      const pool = createMockPool(async (sql, params) => {
        if (sql.includes('SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1 AND user_id = $2')) {
          return { rows: [{ id: petId, name: 'Fluffy', species: 'dog', user_id: userId, organization_id: null }] };
        }
        if (sql.includes('SELECT 1 FROM organization_users') && sql.includes('super_admin')) {
          return { rows: [{ '?column?': 1 }] };
        }
        if (sql.includes('UPDATE pets') && sql.includes('organization_id = $1')) {
          updatedOrgId = params[0];
          return { rows: [] };
        }
        if (sql.includes('INSERT INTO archived_pets')) {
          return { rows: [] };
        }
        return { rows: [] };
      });
      const res = await request(createApp(pool))
        .post(`/api/pets/${petId}/transfer-to-org`)
        .set('Authorization', `Bearer ${token}`)
        .send({ organization_id: 'org-1' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('transferred', true);
      expect(updatedOrgId).toBe('org-1');
    });

    it('POST /:id/transfer-to-org returns 400 without organization_id', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer-to-org`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
    });

    it('GET /:id/family-events returns an (empty) array', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('POST /:id/family-events creates an event when dates are provided', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`)
        .send({ from_date: '2023-01-01', notes: 'Foster' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
    });

    it('PUT /:id/family-events/:eventId updates an event', async () => {
      const res = await request(app)
        .put(`/api/pets/${petId}/family-events/fe-1`)
        .set('Authorization', `Bearer ${token}`)
        .send({ from_date: '2023-01-01', to_date: '2023-06-01' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('to_date');
    });

    it('DELETE /:id/family-events/:eventId deletes an event', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}/family-events/fe-1`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
    });

    it('GET /:id/access returns access list for owner', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/access`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('PUT /:id/access/:userId/role returns 501 (not implemented)', async () => {
      const res = await request(app)
        .put(`/api/pets/${petId}/access/user-42/role`)
        .set('Authorization', `Bearer ${token}`)
        .send({ role: 'editor' });
      expect(res.statusCode).toBe(501);
    });

    it('DELETE /:id/access/:userId removes access and notifies user', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}/access/user-42`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Access removed');
    });

    it('DELETE /:id/data returns deleted with rows_removed', async () => {
      const res = await request(app)
        .delete(`/api/pets/${petId}/data`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
      expect(res.body).toHaveProperty('pet_id', petId);
      expect(res.body).toHaveProperty('rows_removed');
    });

    it('POST /:id/passed-away returns passed_away and notified_count', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/passed-away`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('passed_away', true);
      expect(res.body).toHaveProperty('pet_id', petId);
      expect(res.body).toHaveProperty('notified_count');
    });
  });
});
