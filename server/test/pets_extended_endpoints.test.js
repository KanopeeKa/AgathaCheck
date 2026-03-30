import request from 'supertest';
import { createApp } from '../bin/server.js';

describe('Pets API extended endpoints', () => {
  let app;
  beforeAll(() => {
    const mockPool = {
      query: async () => ({ rows: [] }),
      end: async () => {}
    };
    app = createApp(mockPool);
  });

  it('POST /backend/api/pets/:id/transfer-to-org', async () => {
    const res = await request(app)
      .post('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/transfer-to-org')
      .send({ organization_id: 1, transfer_type: 'transfer', notes: 'Test' });
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('GET /backend/api/pets/:id/family-events', async () => {
    const res = await request(app)
      .get('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/family-events');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /backend/api/pets/:id/family-events', async () => {
    const res = await request(app)
      .post('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/family-events')
      .send({});
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('PUT /backend/api/pets/:id/family-events/:eventId', async () => {
    const res = await request(app)
      .put('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/family-events/1')
      .send({});
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('DELETE /backend/api/pets/:id/family-events/:eventId', async () => {
    const res = await request(app)
      .delete('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/family-events/1');
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('GET /backend/api/pets/:id/access', async () => {
    const res = await request(app)
      .get('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/access');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('PUT /backend/api/pets/:id/access/:userId/role', async () => {
    const res = await request(app)
      .put('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/access/42/role')
      .send({ role: 'editor' });
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('DELETE /backend/api/pets/:id/access/:userId', async () => {
    const res = await request(app)
      .delete('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/access/42');
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('DELETE /backend/api/pets/:id/data', async () => {
    const res = await request(app)
      .delete('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/data');
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });

  it('POST /backend/api/pets/:id/passed-away', async () => {
    const res = await request(app)
      .post('/backend/api/pets/123e4567-e89b-12d3-a456-426614174000/passed-away')
      .send({ pet_name: 'TestPet' });
    expect(res.statusCode).toBeGreaterThanOrEqual(200);
    expect(res.statusCode).toBeLessThan(300);
  });
});
