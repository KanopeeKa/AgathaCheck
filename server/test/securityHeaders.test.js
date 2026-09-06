import request from 'supertest';
import { createApp } from '../bin/server.js';

describe('Security headers (F-15)', () => {
  it('sets baseline Helmet headers on /health', async () => {
    const app = createApp({ query: async () => ({ rows: [] }) });
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['content-security-policy']).toBeDefined();
    expect(String(res.headers['content-security-policy'])).toContain("default-src 'self'");
  });
});
