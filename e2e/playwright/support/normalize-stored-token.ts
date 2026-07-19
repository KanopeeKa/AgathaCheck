/** JWT-shaped token: three base64url segments separated by dots. */
const JWT_SHAPE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;

/**
 * Normalize an auth token read from browser localStorage.
 *
 * `shared_preferences_web` JSON-encodes string values before storing them, so
 * raw reads often look like `"eyJhbGci..."` instead of `eyJhbGci...`.
 */
export function normalizeStoredToken(raw: string | null | undefined): string {
  if (raw == null || raw === '') {
    throw new Error('auth_access_token missing from localStorage');
  }

  let candidate = raw.trim();
  if (candidate === '') {
    throw new Error('auth_access_token missing from localStorage');
  }

  try {
    const parsed = JSON.parse(candidate);
    if (typeof parsed === 'string') {
      candidate = parsed.trim();
    }
  } catch {
    // Not JSON — use the raw string (legacy/plain storage).
  }

  if (!candidate) {
    throw new Error('auth_access_token missing from localStorage');
  }

  if (!JWT_SHAPE.test(candidate)) {
    throw new Error(
      `auth_access_token in localStorage failed JWT-shape validation after normalization (length=${candidate.length})`,
    );
  }

  return candidate;
}
