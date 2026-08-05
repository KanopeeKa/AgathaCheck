import request from 'supertest';
import { createApp } from '../bin/server.js';

describe('PUBLIC_ACCESS_MODE gate', () => {
  const originalMode = process.env.PUBLIC_ACCESS_MODE;

  afterEach(() => {
    if (originalMode === undefined) {
      delete process.env.PUBLIC_ACCESS_MODE;
    } else {
      process.env.PUBLIC_ACCESS_MODE = originalMode;
    }
  });

  function mockPool() {
    return {
      query: async () => ({ rows: [] }),
      end: async () => {},
    };
  }

  it('default/open: signup reaches validation (400), not 403', async () => {
    delete process.env.PUBLIC_ACCESS_MODE;
    const app = createApp(mockPool());
    const res = await request(app).post('/backend/api/auth/signup').send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.code).not.toBe('public_access_closed');
    expect(res.body.error).toMatch(/required/i);
  });

  it('open: signup reaches validation (400), not 403', async () => {
    process.env.PUBLIC_ACCESS_MODE = 'open';
    const app = createApp(mockPool());
    const res = await request(app).post('/backend/api/auth/signup').send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.code).not.toBe('public_access_closed');
  });

  it('coming_soon: GET /backend/health → 200', async () => {
    process.env.PUBLIC_ACCESS_MODE = 'coming_soon';
    const app = createApp(mockPool());
    const res = await request(app).get('/backend/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('OK');
  });

  it('coming_soon: POST signup → 403 public_access_closed', async () => {
    process.env.PUBLIC_ACCESS_MODE = 'coming_soon';
    const app = createApp(mockPool());
    const res = await request(app)
      .post('/backend/api/auth/signup')
      .send({ email: 'a@b.com', password: 'longenough' });
    expect(res.statusCode).toBe(403);
    expect(res.body).toEqual({
      error: 'Public access is closed.',
      code: 'public_access_closed',
    });
  });

  it('coming_soon: POST login → 403', async () => {
    process.env.PUBLIC_ACCESS_MODE = 'coming_soon';
    const app = createApp(mockPool());
    const res = await request(app)
      .post('/backend/api/auth/login')
      .send({ email: 'a@b.com', password: 'longenough' });
    expect(res.statusCode).toBe(403);
    expect(res.body.code).toBe('public_access_closed');
  });
});
