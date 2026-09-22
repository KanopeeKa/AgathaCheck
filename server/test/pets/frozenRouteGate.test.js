import request from 'supertest';

import { createApp } from '../../bin/server.js';
import { createMockPool, petId, token } from './helpers.js';

describe('frozen shelter route gate (Batch A2)', () => {
  const originalFrozen = process.env.ENABLE_FROZEN_DOMAINS;

  afterEach(() => {
    if (originalFrozen === undefined) {
      delete process.env.ENABLE_FROZEN_DOMAINS;
    } else {
      process.env.ENABLE_FROZEN_DOMAINS = originalFrozen;
    }
  });

  describe('with frozen domains disabled (default)', () => {
    beforeEach(() => {
      delete process.env.ENABLE_FROZEN_DOMAINS;
    });

    let app;
    beforeAll(() => {
      app = createApp(createMockPool());
    });

    it('POST /:id/transfer-to-org returns 404', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer-to-org`)
        .set('Authorization', `Bearer ${token}`)
        .send({ organization_id: 'org-1' });
      expect(res.statusCode).toBe(404);
      expect(res.body).toEqual({ error: 'Not found' });
    });

    it('POST /:id/transfer remains reachable (401 without token)', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/transfer`)
        .send({});
      expect(res.statusCode).toBe(401);
    });

    it('POST /:id/family-events returns 404', async () => {
      const res = await request(app)
        .post(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`)
        .send({ from_date: '2023-01-01' });
      expect(res.statusCode).toBe(404);
    });

    it('GET /:id/family-events remains available for historical reads', async () => {
      const res = await request(app)
        .get(`/api/pets/${petId}/family-events`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });
});
