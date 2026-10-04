/**
 * Redact sensitive fragments from job error messages before persistence/logging.
 */

const ABSOLUTE_PATH = /(?:^|[\s('"=])(\/[\w./-]+)/g;
const WINDOWS_PATH = /(?:^|[\s('"=])([A-Za-z]:\\[\w.\\-]+)/g;
const EMAIL = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
const BEARER = /\bBearer\s+[A-Za-z0-9._~+/=-]+/gi;
const JWT_LIKE = /\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g;

export function redactJobError(message) {
  if (message == null) return null;
  const text = typeof message === 'string' ? message : String(message);
  return text
    .replace(ABSOLUTE_PATH, ' [path]')
    .replace(WINDOWS_PATH, ' [path]')
    .replace(EMAIL, '[email]')
    .replace(BEARER, 'Bearer [token]')
    .replace(JWT_LIKE, '[token]')
    .slice(0, 2000);
}
