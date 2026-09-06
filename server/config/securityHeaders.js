/**
 * Security headers (F-15) — Helmet with Flutter-web-tolerant CSP.
 */
import helmet from 'helmet';

const isProduction = () => process.env.NODE_ENV === 'production';

export function securityHeadersMiddleware() {
  return helmet({
    contentSecurityPolicy: {
      useDefaults: true,
      directives: {
        'default-src': ["'self'"],
        'script-src': ["'self'", "'unsafe-eval'", "'wasm-unsafe-eval'"],
        'style-src': ["'self'", "'unsafe-inline'"],
        'img-src': ["'self'", 'data:', 'blob:'],
        'connect-src': ["'self'"],
        'font-src': ["'self'", 'data:'],
        'object-src': ["'none'"],
        'base-uri': ["'self'"],
        'frame-ancestors': ["'self'"],
      },
    },
    crossOriginEmbedderPolicy: false,
    hsts: isProduction()
      ? { maxAge: 31536000, includeSubDomains: true, preload: false }
      : false,
  });
}
