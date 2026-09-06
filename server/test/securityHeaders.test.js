import request from 'supertest';
import { createApp } from '../bin/server.js';

describe('Security headers (F-15)', () => {
  it('sets baseline Helmet headers on /health', async () => {
    const app = createApp({ query: async () => ({ rows: [] }) });
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['content-security-policy']).toBeDefined();
    const csp = String(res.headers['content-security-policy']);
    expect(csp).toContain("default-src 'self'");
    expect(csp).toContain("'unsafe-inline'");
    expect(csp).not.toContain('upgrade-insecure-requests');
  });

  it('omits upgrade-insecure-requests when E2E=1', async () => {
    const prev = process.env.E2E;
    process.env.E2E = '1';
    process.env.NODE_ENV = 'production';
    try {
      const app = createApp({ query: async () => ({ rows: [] }) });
      const res = await request(app).get('/health');
      const csp = String(res.headers['content-security-policy']);
      expect(csp).not.toContain('upgrade-insecure-requests');
    } finally {
      if (prev === undefined) delete process.env.E2E;
      else process.env.E2E = prev;
      delete process.env.NODE_ENV;
    }
  });
});
