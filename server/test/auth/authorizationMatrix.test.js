import request from 'supertest';
import { createApp } from '../../bin/server.js';
import { buildMockPool, mockComparePassword } from './helpers.js';
import {
  AUTH_API_PREFIXES,
  AUTH_STATUS_MATRIX,
  resolveProbeHeaders,
} from './authorizationMatrix.js';

describe('Auth authorization status matrix', () => {
  let app;

  beforeEach(() => {
    app = createApp(buildMockPool(), mockComparePassword);
  });

  for (const prefix of AUTH_API_PREFIXES) {
    describe(prefix, () => {
      for (const [index, probe] of AUTH_STATUS_MATRIX.entries()) {
        const label = `${probe.method.toUpperCase()} ${probe.path} → ${probe.status}`;
        it(`[${index}] ${label}`, async () => {
          const url = `${prefix}${probe.path}`;
          const headers = resolveProbeHeaders(probe);
          const agent = request(app)[probe.method](url);
          for (const [key, value] of Object.entries(headers)) {
            agent.set(key, value);
          }
          const res = await agent.send(probe.body ?? {});
          expect(res.statusCode).toBe(probe.status);
        });
      }
    });
  }
});
