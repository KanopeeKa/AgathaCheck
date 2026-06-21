/**
 * Shared HTTP security helpers (CORS policy + error-detail redaction) used by
 * the Express server and its route modules. Mirrors the Dart server's
 * `lib/http_security.dart`; keep the two in lockstep.
 */

const isProduction = () => process.env.NODE_ENV === 'production';

/**
 * Returns a client-safe error string. In production the raw error message is
 * suppressed (it can leak DB/internal details) and `prodMessage` is returned;
 * outside production the detailed message is returned so developers and the
 * test suite keep full diagnostics. Pass `devMessage` to preserve a custom
 * dev-only string (e.g. a contextual prefix) while still redacting in prod.
 */
export function publicError(err, prodMessage = 'Internal server error', devMessage) {
  if (isProduction()) return prodMessage;
  if (devMessage !== undefined) return devMessage;
  return err && err.message ? err.message : String(err);
}

/**
 * Spread into a JSON error body to attach `{ details }` only outside
 * production, e.g. `res.json({ error: 'X failed', ...errorDetails(err) })`.
 */
export function errorDetails(err) {
  if (isProduction()) return {};
  return { details: err && err.message ? err.message : String(err) };
}

/**
 * CORS options for the `cors` middleware. When `CORS_ALLOWED_ORIGINS` is set
 * (comma-separated), only those origins are allowed. In production with no
 * allowlist, cross-origin requests are denied (the API serves its own
 * same-origin Flutter frontend, so it needs no cross-origin access by default).
 * Outside production CORS stays permissive for local development.
 */
export function corsOptions() {
  const raw = process.env.CORS_ALLOWED_ORIGINS;
  if (raw && raw.trim()) {
    const list = raw.split(',').map((s) => s.trim()).filter(Boolean);
    return { origin: list };
  }
  if (isProduction()) {
    return { origin: false };
  }
  return {};
}
