import { isPublicAccessClosed } from '../config/publicAccess.js';

const ALLOWED_WHEN_CLOSED = new Set([
  '/health',
  '/backend/health',
  '/backend/',
  '/backend',
]);

function isApiPath(pathname) {
  return (
    pathname === '/api' ||
    pathname.startsWith('/api/') ||
    pathname === '/backend/api' ||
    pathname.startsWith('/backend/api/') ||
    pathname === '/server/api' ||
    pathname.startsWith('/server/api/')
  );
}

/**
 * When PUBLIC_ACCESS_MODE=coming_soon, block API routes with 403.
 * Health and backend root stay reachable for deploy/smoke.
 */
export function publicAccessGate(req, res, next) {
  if (!isPublicAccessClosed()) {
    return next();
  }

  const pathname = req.path;
  if (ALLOWED_WHEN_CLOSED.has(pathname)) {
    return next();
  }

  if (isApiPath(pathname)) {
    return res.status(403).json({
      error: 'Public access is closed.',
      code: 'public_access_closed',
    });
  }

  return next();
}
