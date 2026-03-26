import request from 'supertest';
import express from 'express';
import weightEntriesRoutes from '../routes/weightEntries.js';

describe('Weight Entries API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/backend/api/weight-entries', weightEntriesRoutes());
  });

  it('POST /backend/api/weight-entries creates entry', async () => {
    const entry = { pet_id: 'pet-1', weight: 4.5, date: '2026-03-26' };
    const res = await request(app)
      .post('/backend/api/weight-entries')
      .send(entry);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('created', true);
    expect(res.body).toHaveProperty('entry');
    expect(res.body.entry).toMatchObject(entry);
  });

  it('GET /backend/api/weight-entries/latest returns latest entry', async () => {
    const res = await request(app).get('/backend/api/weight-entries/latest');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('pet_id');
    expect(res.body).toHaveProperty('weight');
    expect(res.body).toHaveProperty('date');
  });
});
