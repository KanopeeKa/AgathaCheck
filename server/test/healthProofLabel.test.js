import request from 'supertest';
import { createApp } from '../bin/server.js';

function mockPool() {
  return {
    query: async () => ({ rows: [] }),
    end: async () => {},
  };
}

describe('GET /backend/health proof_label', () => {
  it('returns status OK and execute-plan v2 proof label', async () => {
    const app = createApp(mockPool());
    const res = await request(app).get('/backend/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('OK');
    expect(res.body.proof_label).toBe('execute-plan-v2-proof');
  });
});
