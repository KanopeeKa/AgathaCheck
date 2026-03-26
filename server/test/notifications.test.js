import request from 'supertest';
import express from 'express';
import notificationsRoutes from '../routes/notifications.js';

describe('Notifications API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/backend/api/notifications', notificationsRoutes());
  });

  it('GET /backend/api/notifications returns empty array', async () => {
    const res = await request(app).get('/backend/api/notifications');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /backend/api/notifications/preferences returns preferences object', async () => {
    const res = await request(app).get('/backend/api/notifications/preferences');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('email');
    expect(res.body).toHaveProperty('sms');
    expect(res.body).toHaveProperty('push');
  });

  it('POST /backend/api/notifications/check-due returns checked true', async () => {
    const res = await request(app)
      .post('/backend/api/notifications/check-due')
      .send({});
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('checked', true);
    expect(res.body).toHaveProperty('due');
    expect(Array.isArray(res.body.due)).toBe(true);
  });
});
