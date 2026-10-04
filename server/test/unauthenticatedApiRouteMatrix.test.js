import request from 'supertest';

import { createApp } from '../bin/server.js';
import {
  listExpressRoutes,
  materializeRoutePath,
} from './helpers/expressRouteInventory.js';

/** Routes that may respond without a Bearer token (still may return 4xx for bad input). */
const ANONYMOUS_ALLOWED = [
  { method: 'POST', pattern: /^\/api\/auth\/(signup|login|refresh|logout|forgot-password|reset-password)$/ },
  { method: 'GET', pattern: /^\/api\/organizations\/[^/]+\/public$/ },
];

const SHARE_PREVIEW_RESERVED = new Set(['hidden', 'links', 'access']);

function isSharePreviewGet(method, path) {
  if (method !== 'GET') return false;
  const match = path.match(/^\/api\/share\/([^/]+)$/);
  if (!match) return false;
  return !SHARE_PREVIEW_RESERVED.has(match[1]);
}

function isAnonymousAllowed(method, path) {
  if (isSharePreviewGet(method, path)) return true;
  return ANONYMOUS_ALLOWED.some(
    (rule) => rule.method === method && rule.pattern.test(path),
  );
}

function buildAnonymousProbePool() {
  const handler = async (sql) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    return { rows: [] };
  };
  return {
    query: handler,
    connect: async () => ({
      query: handler,
      release: () => {},
    }),
    end: async () => {},
  };
}

function dedupeRoutes(routes) {
  const seen = new Set();
  return routes.filter((route) => {
    const key = `${route.method} ${route.path}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

describe('unauthenticated /api route matrix', () => {
  let app;
  let apiRoutes;

  beforeAll(() => {
    process.env.PUBLIC_ACCESS_MODE = 'open';
    app = createApp(buildAnonymousProbePool());
    apiRoutes = dedupeRoutes(listExpressRoutes(app)).filter(
      (route) => route.path.startsWith('/api/'),
    );
    expect(apiRoutes.length).toBeGreaterThan(10);
  });

  for (const method of ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']) {
    it(`rejects anonymous ${method} on protected /api routes`, async () => {
      const candidates = apiRoutes.filter((r) => r.method === method);
      const failures = [];

      for (const route of candidates) {
        const path = materializeRoutePath(route.path);
        if (path.includes('*')) continue;

        const res = await request(app)[method.toLowerCase()](path).send({});

        if (isAnonymousAllowed(method, path)) {
          if (res.statusCode === 401) {
            failures.push(`${method} ${path} returned 401 but is allow-listed`);
          }
          continue;
        }

        if ([200, 201, 204].includes(res.statusCode)) {
          failures.push(`${method} ${path} returned ${res.statusCode} without auth`);
        }
        if (res.statusCode >= 500) {
          failures.push(`${method} ${path} returned ${res.statusCode} (server error)`);
        }
      }

      expect(failures).toEqual([]);
    });
  }

  it('documents share preview route', () => {
    const paths = apiRoutes.map((r) => `${r.method} ${r.path}`);
    expect(paths).toContain('GET /api/share/:code');
  });
});
