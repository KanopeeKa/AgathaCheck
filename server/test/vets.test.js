import request from 'supertest';
import express from 'express';
import vetsRoutes from '../routes/vets.js';

describe('Vets API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/backend/api/vets', vetsRoutes());
  });

  it('GET /backend/api/vets returns array', async () => {
    const res = await request(app).get('/backend/api/vets');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /backend/api/vets creates vet', async () => {
    const vet = { name: 'Dr. Smith' };
    const res = await request(app)
      .post('/backend/api/vets')
      .send(vet);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('created', true);
    expect(res.body).toHaveProperty('vet');
    expect(res.body.vet).toMatchObject(vet);
  });
});
