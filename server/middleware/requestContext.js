import { randomUUID } from 'crypto';

import { logger } from '../lib/logger.js';

const API_PREFIXES = ['/api/', '/backend/api/', '/server/api/'];

function isApiRequest(path) {
  return API_PREFIXES.some((prefix) => path.startsWith(prefix));
}

export function requestContextMiddleware(req, res, next) {
  const requestId = req.headers['x-request-id'] || randomUUID();
  req.requestId = requestId;
  res.locals.requestId = requestId;
  res.setHeader('X-Request-Id', requestId);

  if (!isApiRequest(req.path)) {
    return next();
  }

  const startedAt = Date.now();
  res.on('finish', () => {
    logger.info({
      requestId,
      method: req.method,
      path: req.path,
      status: res.statusCode,
      durationMs: Date.now() - startedAt,
    });
  });

  next();
}
