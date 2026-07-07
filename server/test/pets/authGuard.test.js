import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { createMockPool, userId, petId, JWT_SECRET } from './helpers.js';

const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

describe('Pets API', () => {
  describe('Auth guard', () => {
    let app;
    beforeAll(() => {
      app = createApp(createMockPool());
    });

    it('GET /api/pets returns 401 without token', async () => {
      const res = await request(app).get('/api/pets');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error', 'Unauthorized');
    });

    it('GET /api/pets/all returns 401 without token', async () => {
      const res = await request(app).get('/api/pets/all');
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error', 'Unauthorized');
    });

    it('GET /api/pets/:id returns 401 without token', async () => {
      const res = await request(app).get(`/api/pets/${petId}`);
      expect(res.statusCode).toBe(401);
    });

    it('POST /api/pets returns 401 without token', async () => {
      const res = await request(app).post('/api/pets').send({ name: 'X' });
      expect(res.statusCode).toBe(401);
    });

    it('PUT /api/pets/:id returns 401 without token', async () => {
      const res = await request(app).put(`/api/pets/${petId}`).send({ name: 'X' });
      expect(res.statusCode).toBe(401);
    });

    it('DELETE /api/pets/:id returns 401 without token', async () => {
      const res = await request(app).delete(`/api/pets/${petId}`);
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with invalid token', async () => {
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', 'Bearer invalidtoken');
      expect(res.statusCode).toBe(401);
    });

    it('returns 401 with expired token', async () => {
      const expired = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '0s' });
      await new Promise(r => setTimeout(r, 10));
      const res = await request(app)
        .get('/api/pets')
        .set('Authorization', `Bearer ${expired}`);
      expect(res.statusCode).toBe(401);
    });
  });
});
