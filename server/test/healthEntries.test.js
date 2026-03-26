import request from 'supertest';
import express from 'express';
import healthEntriesRoutes from '../routes/healthEntries.js';

describe('Health Entries API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/backend/api/health-entries', healthEntriesRoutes());
  });

  it('GET /backend/api/health-entries returns array', async () => {
    const res = await request(app).get('/backend/api/health-entries');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /backend/api/health-entries creates entry', async () => {
    const entry = { pet_id: 'pet-1', type: 'checkup', date: '2026-03-26' };
    const res = await request(app)
      .post('/backend/api/health-entries')
      .send(entry);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('created', true);
    expect(res.body).toHaveProperty('entry');
    expect(res.body.entry).toMatchObject(entry);
  });
});
