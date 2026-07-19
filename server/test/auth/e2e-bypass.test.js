import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  getE2eAuthBypassSkipCount,
  resetE2eAuthBypassSkipCountForTests,
} from '../../config/e2eBypass.js';
import { buildMockPool, mockComparePassword } from './helpers.js';

describe('Auth E2E rate-limit bypass', () => {
  function restoreEnv(key, prev) {
    if (prev === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = prev;
    }
  }

  afterEach(() => {
    resetE2eAuthBypassSkipCountForTests();
  });

  it('returns 429 without bypass header when limit exceeded', async () => {
    const prevTest = process.env.AUTH_RATE_LIMIT_TEST;
    const prevMax = process.env.AUTH_RATE_LIMIT_MAX;
    const prevAllowed = process.env.E2E_BYPASS_ALLOWED;
    const prevToken = process.env.E2E_BYPASS_TOKEN;
    process.env.AUTH_RATE_LIMIT_TEST = '1';
    process.env.AUTH_RATE_LIMIT_MAX = '2';
    process.env.E2E_BYPASS_ALLOWED = 'true';
    process.env.E2E_BYPASS_TOKEN = 'ci-secret-token';
    try {
      const app = createApp(buildMockPool(), mockComparePassword);
      const send = () => request(app)
        .post('/api/auth/signup')
        .send({ email: `rate-${Date.now()}@example.com`, password: 'Password123' });
      expect((await send()).statusCode).toBe(201);
      expect((await send()).statusCode).toBe(201);
      expect((await send()).statusCode).toBe(429);
    } finally {
      restoreEnv('AUTH_RATE_LIMIT_TEST', prevTest);
      restoreEnv('AUTH_RATE_LIMIT_MAX', prevMax);
      restoreEnv('E2E_BYPASS_ALLOWED', prevAllowed);
      restoreEnv('E2E_BYPASS_TOKEN', prevToken);
    }
  });

  it('skips auth rate limit when bypass header matches configured token', async () => {
    const prevTest = process.env.AUTH_RATE_LIMIT_TEST;
    const prevMax = process.env.AUTH_RATE_LIMIT_MAX;
    const prevAllowed = process.env.E2E_BYPASS_ALLOWED;
    const prevToken = process.env.E2E_BYPASS_TOKEN;
    process.env.AUTH_RATE_LIMIT_TEST = '1';
    process.env.AUTH_RATE_LIMIT_MAX = '2';
    process.env.E2E_BYPASS_ALLOWED = 'true';
    process.env.E2E_BYPASS_TOKEN = 'ci-secret-token';
    try {
      const app = createApp(buildMockPool(), mockComparePassword);
      const send = () => request(app)
        .post('/api/auth/signup')
        .set('X-E2E-Bypass-Token', 'ci-secret-token')
        .send({ email: `bypass-${Date.now()}@example.com`, password: 'Password123' });
      expect((await send()).statusCode).toBe(201);
      expect((await send()).statusCode).toBe(201);
      expect((await send()).statusCode).toBe(201);
      expect(getE2eAuthBypassSkipCount()).toBeGreaterThanOrEqual(3);
    } finally {
      restoreEnv('AUTH_RATE_LIMIT_TEST', prevTest);
      restoreEnv('AUTH_RATE_LIMIT_MAX', prevMax);
      restoreEnv('E2E_BYPASS_ALLOWED', prevAllowed);
      restoreEnv('E2E_BYPASS_TOKEN', prevToken);
    }
  });

  it('does not bypass when token header is wrong', async () => {
    const prevTest = process.env.AUTH_RATE_LIMIT_TEST;
    const prevMax = process.env.AUTH_RATE_LIMIT_MAX;
    const prevAllowed = process.env.E2E_BYPASS_ALLOWED;
    const prevToken = process.env.E2E_BYPASS_TOKEN;
    process.env.AUTH_RATE_LIMIT_TEST = '1';
    process.env.AUTH_RATE_LIMIT_MAX = '1';
    process.env.E2E_BYPASS_ALLOWED = 'true';
    process.env.E2E_BYPASS_TOKEN = 'ci-secret-token';
    try {
      const app = createApp(buildMockPool(), mockComparePassword);
      const send = (token) => request(app)
        .post('/api/auth/signup')
        .set('X-E2E-Bypass-Token', token)
        .send({ email: `wrong-${Date.now()}-${Math.random()}@example.com`, password: 'Password123' });
      expect((await send('wrong-token')).statusCode).toBe(201);
      expect((await send('wrong-token')).statusCode).toBe(429);
    } finally {
      restoreEnv('AUTH_RATE_LIMIT_TEST', prevTest);
      restoreEnv('AUTH_RATE_LIMIT_MAX', prevMax);
      restoreEnv('E2E_BYPASS_ALLOWED', prevAllowed);
      restoreEnv('E2E_BYPASS_TOKEN', prevToken);
    }
  });

  it('ignores bypass token when E2E_BYPASS_ALLOWED is not true', async () => {
    const prevTest = process.env.AUTH_RATE_LIMIT_TEST;
    const prevMax = process.env.AUTH_RATE_LIMIT_MAX;
    const prevAllowed = process.env.E2E_BYPASS_ALLOWED;
    const prevToken = process.env.E2E_BYPASS_TOKEN;
    process.env.AUTH_RATE_LIMIT_TEST = '1';
    process.env.AUTH_RATE_LIMIT_MAX = '1';
    delete process.env.E2E_BYPASS_ALLOWED;
    process.env.E2E_BYPASS_TOKEN = 'ci-secret-token';
    try {
      const app = createApp(buildMockPool(), mockComparePassword);
      const send = () => request(app)
        .post('/api/auth/signup')
        .set('X-E2E-Bypass-Token', 'ci-secret-token')
        .send({ email: `disallowed-${Date.now()}@example.com`, password: 'Password123' });
      expect((await send()).statusCode).toBe(201);
      expect((await send()).statusCode).toBe(429);
    } finally {
      restoreEnv('AUTH_RATE_LIMIT_TEST', prevTest);
      restoreEnv('AUTH_RATE_LIMIT_MAX', prevMax);
      restoreEnv('E2E_BYPASS_ALLOWED', prevAllowed);
      restoreEnv('E2E_BYPASS_TOKEN', prevToken);
    }
  });
});
