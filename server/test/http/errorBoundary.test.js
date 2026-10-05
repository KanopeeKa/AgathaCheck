import express from 'express';
import request from 'supertest';

import {
  ValidationError,
  UnauthenticatedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  TransientError,
} from '../../lib/http/errors.js';
import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { createApiErrorMiddleware } from '../../lib/http/errorMiddleware.js';
import { requestContextMiddleware } from '../../middleware/requestContext.js';

function createTestApp(handler) {
  const app = express();
  app.use(requestContextMiddleware);
  app.get('/api/test', asyncHandler(handler));
  app.use(createApiErrorMiddleware());
  return app;
}

describe('HTTP error boundary (H.3)', () => {
  it('maps typed errors to status and message with request_id', async () => {
    const cases = [
      [new ValidationError('bad input'), 400, 'bad input'],
      [new UnauthenticatedError(), 401, 'Unauthorized'],
      [new ForbiddenError('nope'), 403, 'nope'],
      [new NotFoundError('missing'), 404, 'missing'],
      [new ConflictError('dup'), 409, 'dup'],
      [new TransientError(), 503, 'Service temporarily unavailable'],
    ];
    for (const [err, status, message] of cases) {
      const app = createTestApp(async () => {
        throw err;
      });
      const res = await request(app).get('/api/test');
      expect(res.statusCode).toBe(status);
      expect(res.body.error).toBe(message);
      expect(res.body.request_id).toBeDefined();
      expect(res.headers['x-request-id']).toBe(res.body.request_id);
    }
  });

  it('returns 500 JSON with redacted error and request_id in production', async () => {
    const prev = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const app = createTestApp(async () => {
        throw new Error('secret internal failure');
      });
      const res = await request(app).get('/api/test');
      expect(res.statusCode).toBe(500);
      expect(res.body.error).toBe('Internal server error');
      expect(res.body.error).not.toContain('secret');
      expect(res.body.request_id).toBeDefined();
      expect(JSON.stringify(res.body)).not.toMatch(/secret internal/);
      expect(res.body.stack).toBeUndefined();
    } finally {
      process.env.NODE_ENV = prev;
    }
  });

  it('asyncHandler forwards rejections so the request does not hang', async () => {
    const app = createTestApp(async () => {
      await Promise.reject(new Error('boom'));
    });
    const res = await request(app).get('/api/test').timeout({ deadline: 3000 });
    expect(res.statusCode).toBe(500);
    expect(res.body.request_id).toBeDefined();
  });
});
