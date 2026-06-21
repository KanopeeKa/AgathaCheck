/**
 * Single source of truth for the JWT signing secret, shared by every route
 * module so the resolution rules cannot drift between files.
 *
 * Resolves `JWT_SECRET`, falling back to `SESSION_SECRET`. In production
 * (`NODE_ENV === 'production'`) a missing secret throws immediately at startup
 * rather than silently signing tokens with a publicly-known default — which
 * would allow token forgery. The dev/test fallback below is intentionally kept
 * (so local runs and the Jest suite work without extra setup) but is
 * unreachable in production because of the throw above.
 *
 * Generate a strong secret with: openssl rand -hex 32
 */
const resolved = process.env.JWT_SECRET || process.env.SESSION_SECRET;

if (!resolved && process.env.NODE_ENV === 'production') {
  throw new Error(
    'JWT_SECRET (or SESSION_SECRET) is required in production. ' +
      'Generate one with: openssl rand -hex 32',
  );
}

export const JWT_SECRET = resolved || 'default_secret';
