/**
 * Security headers (F-15) — Helmet with Flutter-web-tolerant CSP.
 */
import helmet from 'helmet';

const isProduction = () => process.env.NODE_ENV === 'production';

/** Playwright localhost E2E uses plain HTTP; skip CSP so canary matches prod-less stack. */
const isLocalE2E = () => process.env.E2E === '1';

function flutterWebCspDirectives() {
  return {
    'default-src': ["'self'"],
    // Inline scripts in flutter_app/web/index.html (native login + SW cleanup).
    'script-src': [
      "'self'",
      "'unsafe-inline'",
      "'unsafe-eval'",
      "'wasm-unsafe-eval'",
      'blob:',
      'https://www.gstatic.com',
    ],
    'style-src': ["'self'", "'unsafe-inline'"],
    'img-src': ["'self'", 'data:', 'blob:'],
    'connect-src': ["'self'", 'https://www.gstatic.com'],
    'font-src': ["'self'", 'data:', 'https://fonts.gstatic.com'],
    'worker-src': ["'self'", 'blob:'],
    'child-src': ["'self'", 'blob:'],
    'object-src': ["'none'"],
    'base-uri': ["'self'"],
    'frame-ancestors': ["'self'"],
    // Helmet defaults include upgrade-insecure-requests, which breaks http://localhost E2E.
    'upgrade-insecure-requests': isProduction() && !isLocalE2E() ? [] : null,
  };
}

export function securityHeadersMiddleware() {
  const helmetOptions = {
    crossOriginEmbedderPolicy: false,
    crossOriginOpenerPolicy: false,
    crossOriginResourcePolicy: false,
    hsts: isProduction()
      ? { maxAge: 31536000, includeSubDomains: true, preload: false }
      : false,
  };

  if (!isLocalE2E()) {
    helmetOptions.contentSecurityPolicy = {
      useDefaults: true,
      directives: flutterWebCspDirectives(),
    };
  } else {
    helmetOptions.contentSecurityPolicy = false;
  }

  return helmet(helmetOptions);
}
