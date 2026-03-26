import request from 'supertest';
import express from 'express';
import organizationsRoutes from '../routes/organizations.js';

describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/organizations', organizationsRoutes());
  });

  it('GET /api/organizations returns array', async () => {
    const res = await request(app).get('/api/organizations');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/organizations creates organization', async () => {
    const org = { name: 'Test Org' };
    const res = await request(app)
      .post('/api/organizations')
      .send(org);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('created', true);
    expect(res.body).toHaveProperty('organization');
    expect(res.body.organization).toMatchObject(org);
  });
});
