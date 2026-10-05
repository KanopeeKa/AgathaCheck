import { publicError, errorDetails } from '../../config/security.js';
import { logger } from '../logger.js';
import { asPeopleError } from '../people/errors.js';
import { PetNotFoundError } from '../petDataLifecycle.js';
import { TagNotFoundError } from '../petTags.js';
import { isHttpError } from './errors.js';

const API_PREFIXES = ['/api/', '/backend/api/', '/server/api/'];

function isApiRequest(path) {
  return API_PREFIXES.some((prefix) => path.startsWith(prefix));
}

function requestIdFrom(req, res) {
  return req.requestId || res.locals?.requestId || undefined;
}

function mapDomainError(err) {
  const people = asPeopleError(err);
  if (people) {
    return { status: people.status, body: people.toJson() };
  }
  if (err instanceof PetNotFoundError) {
    return { status: 404, body: { error: 'Pet not found' } };
  }
  if (err instanceof TagNotFoundError) {
    return { status: 404, body: { error: err.message } };
  }
  return null;
}

function responseBodyFor500(err) {
  const prodMessage = err.exposeProdMessage || 'Internal server error';
  const devMessage = err.exposeDevMessage;
  const error = publicError(err, prodMessage, devMessage);
  return { error, ...errorDetails(err) };
}

/**
 * Terminal Express error middleware for API routes.
 */
export function createApiErrorMiddleware() {
  return function apiErrorMiddleware(err, req, res, next) {
    if (!isApiRequest(req.path)) {
      return next(err);
    }
    if (res.headersSent) {
      return next(err);
    }

    const requestId = requestIdFrom(req, res);

    if (err.status && err.body && typeof err.body === 'object') {
      logger.error({ err, requestId, path: req.path, method: req.method });
      return res.status(err.status).json({ ...err.body, request_id: requestId });
    }

    const domain = mapDomainError(err);
    if (domain) {
      return res.status(domain.status).json({ ...domain.body, request_id: requestId });
    }

    if (isHttpError(err)) {
      if (err.statusCode >= 500) {
        logger.error({ err, requestId, path: req.path, method: req.method });
      }
      return res.status(err.statusCode).json({ error: err.message, request_id: requestId });
    }

    logger.error({ err, requestId, path: req.path, method: req.method });
    return res.status(500).json({ ...responseBodyFor500(err), request_id: requestId });
  };
}
