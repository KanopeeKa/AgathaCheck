import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { createMockPool, token, userId, petId } from './helpers.js';

describe('Pets API', () => {
  describe('Extended endpoints', () => {
    let app;
    beforeAll(() => {
      app = createApp(createMockPool());
    });

    const authRequiredEndpoints = [
      ['POST', `/api/pets/${petId}/transfer`],
      ['GET', `/api/pets/${petId}/family-events`],
      ['GET', `/api/pets/${petId}/access`],
      ['PUT', `/api/pets/${petId}/access/user-42/role`],
      ['DELETE', `/api/pets/${petId}/access/user-42`],
      ['DELETE', `/api/pets/${petId}/data`],
      ['POST', `/api/pets/${petId}/passed-away`],
    ];

    const frozenGatedEndpoints = [
      ['POST', `/api/pets/${petId}/transfer-to-org`],
      ['POST', `/api/pets/${petId}/family-events`],
      ['PUT', `/api/pets/${petId}/family-events/1`],
      ['DELETE', `/api/pets/${petId}/family-events/1`],
    ];

    authRequiredEndpoints.forEach(([method, url]) => {
      it(`${method} ${url.replace(petId, ':id')} returns 401 without token`, async () => {
        const res = await request(app)[method.toLowerCase()](url).send({});
        expect(res.statusCode).toBe(401);
        expect(res.body).toHaveProperty('error', 'Unauthorized');
      });
    });

    frozenGatedEndpoints.forEach(([method, url]) => {
      it(`${method} ${url.replace(petId, ':id')} returns 404 when frozen domains disabled`, async () => {
        const res = await request(app)[method.toLowerCase()](url).send({});
        expect(res.statusCode).toBe(404);
        expect(res.body).toEqual({ error: 'Not found' });
      });
    });

    it('POST /:id/transfer-to-org transfers pet to organization when frozen domains enabled', async () => {
      const prev = process.env.ENABLE_FROZEN_DOMAINS;
      process.env.ENABLE_FROZEN_DOMAINS = 'true';
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
      if (prev === undefined) delete process.env.ENABLE_FROZEN_DOMAINS;
      else process.env.ENABLE_FROZEN_DOMAINS = prev;
    });

    it('POST /:id/transfer-to-org returns 400 without organization_id when frozen domains enabled', async () => {
      const prev = process.env.ENABLE_FROZEN_DOMAINS;
      process.env.ENABLE_FROZEN_DOMAINS = 'true';
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer-to-org`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(400);
      if (prev === undefined) delete process.env.ENABLE_FROZEN_DOMAINS;
      else process.env.ENABLE_FROZEN_DOMAINS = prev;
    });

    it('GET /:id/family-events returns an (empty) array', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('POST /:id/family-events creates an event when frozen domains enabled', async () => {
      const prev = process.env.ENABLE_FROZEN_DOMAINS;
      process.env.ENABLE_FROZEN_DOMAINS = 'true';
      const res = await request(app)
        .post(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`)
        .send({ from_date: '2023-01-01', notes: 'Foster' });
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
      if (prev === undefined) delete process.env.ENABLE_FROZEN_DOMAINS;
      else process.env.ENABLE_FROZEN_DOMAINS = prev;
    });

    it('PUT /:id/family-events/:eventId updates an event when frozen domains enabled', async () => {
      const prev = process.env.ENABLE_FROZEN_DOMAINS;
      process.env.ENABLE_FROZEN_DOMAINS = 'true';
      const res = await request(app)
        .put(`/api/pets/${petId}/family-events/fe-1`)
        .set('Authorization', `Bearer ${token}`)
        .send({ from_date: '2023-01-01', to_date: '2023-06-01' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('to_date');
      if (prev === undefined) delete process.env.ENABLE_FROZEN_DOMAINS;
      else process.env.ENABLE_FROZEN_DOMAINS = prev;
    });

    it('DELETE /:id/family-events/:eventId deletes an event when frozen domains enabled', async () => {
      const prev = process.env.ENABLE_FROZEN_DOMAINS;
      process.env.ENABLE_FROZEN_DOMAINS = 'true';
      const res = await request(app)
        .delete(`/api/pets/${petId}/family-events/fe-1`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('deleted', true);
      if (prev === undefined) delete process.env.ENABLE_FROZEN_DOMAINS;
      else process.env.ENABLE_FROZEN_DOMAINS = prev;
    });

    it('GET /:id/access returns access list for owner', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/access`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('PUT /:id/access/:userId/role updates carer/co_parent role', async () => {
      const res = await request(app)
        .put(`/api/pets/${petId}/access/user-42/role`)
        .set('Authorization', `Bearer ${token}`)
        .send({ role: 'co_parent' });
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('role', 'co_parent');
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

    it('POST /:id/passed-away returns notification_sent and notified_count', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/passed-away`)
        .set('Authorization', `Bearer ${token}`)
        .send({});
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('pet_id', petId);
      expect(res.body).toHaveProperty('notified_count');
      expect(typeof res.body.notification_sent).toBe('boolean');
      expect(res.body.delivery_status).toBe(
        res.body.notified_count > 0 ? 'delivered' : 'no_recipients',
      );
      expect(res.body.notification_sent).toBe(res.body.notified_count > 0);
    });
  });
});
