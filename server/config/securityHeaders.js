/**
 * Security headers (F-15) — Helmet with Flutter-web-tolerant CSP.
 */
import helmet from 'helmet';

const isProduction = () => process.env.NODE_ENV === 'production';

/** Playwright localhost E2E uses plain HTTP; Helmet defaults add upgrade-insecure-requests. */
const isLocalE2E = () => process.env.E2E === '1';

export function securityHeadersMiddleware() {
  const cspDirectives = {
    'default-src': ["'self'"],
    // Inline scripts in flutter_app/web/index.html (native login + SW cleanup).
    'script-src': [
      "'self'",
      "'unsafe-inline'",
      "'unsafe-eval'",
      "'wasm-unsafe-eval'",
      'blob:',
    ],
    'style-src': ["'self'", "'unsafe-inline'"],
    'img-src': ["'self'", 'data:', 'blob:'],
    'connect-src': ["'self'"],
    'font-src': ["'self'", 'data:'],
    'worker-src': ["'self'", 'blob:'],
    'child-src': ["'self'", 'blob:'],
    'object-src': ["'none'"],
    'base-uri': ["'self'"],
    'frame-ancestors': ["'self'"],
    // Helmet defaults include upgrade-insecure-requests, which breaks http://localhost E2E.
    'upgrade-insecure-requests': isProduction() && !isLocalE2E() ? [] : null,
  };

  return helmet({
    contentSecurityPolicy: {
      useDefaults: true,
      directives: cspDirectives,
    },
    crossOriginEmbedderPolicy: false,
    hsts: isProduction()
      ? { maxAge: 31536000, includeSubDomains: true, preload: false }
      : false,
  });
}
