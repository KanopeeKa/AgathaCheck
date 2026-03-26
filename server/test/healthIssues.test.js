import request from 'supertest';
import express from 'express';
import healthIssuesRoutes from '../routes/healthIssues.js';

describe('Health Issues API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/backend/api/health-issues', healthIssuesRoutes());
  });

  it('GET /backend/api/health-issues returns array', async () => {
    const res = await request(app).get('/backend/api/health-issues');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /backend/api/health-issues creates issue', async () => {
    const issue = { pet_id: 'pet-1', description: 'Fever', date: '2026-03-26' };
    const res = await request(app)
      .post('/backend/api/health-issues')
      .send(issue);
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('created', true);
    expect(res.body).toHaveProperty('issue');
    expect(res.body.issue).toMatchObject(issue);
  });
});
