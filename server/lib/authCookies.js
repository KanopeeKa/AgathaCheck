import { isProduction } from '../routes/auth/shared.js';

export const REFRESH_COOKIE_NAME = 'refresh_token';

/** Primary path for direct `/api/auth` clients and Jest. */
export const REFRESH_COOKIE_PATH = '/api/auth';

/** Web Flutter calls `/backend/api/auth`; browsers only send cookies whose Path matches. */
export const REFRESH_COOKIE_PATH_WEB = '/backend/api/auth';

const REFRESH_COOKIE_PATHS = [REFRESH_COOKIE_PATH, REFRESH_COOKIE_PATH_WEB];
const REFRESH_MAX_AGE_SEC = 30 * 24 * 60 * 60;

function buildCookieHeader(name, value, { path, clear = false }) {
  const parts = [
    `${name}=${encodeURIComponent(value)}`,
    `Path=${path}`,
    'HttpOnly',
    'SameSite=Lax',
  ];
  if (isProduction()) {
    parts.push('Secure');
  }
  if (clear) {
    parts.push('Max-Age=0');
    parts.push('Expires=Thu, 01 Jan 1970 00:00:00 GMT');
  } else {
    parts.push(`Max-Age=${REFRESH_MAX_AGE_SEC}`);
  }
  return parts.join('; ');
}

export function setRefreshTokenCookie(res, token) {
  const headers = REFRESH_COOKIE_PATHS.map((path) =>
    buildCookieHeader(REFRESH_COOKIE_NAME, token, { path }),
  );
  res.setHeader('Set-Cookie', headers);
}

export function clearRefreshTokenCookie(res) {
  const headers = REFRESH_COOKIE_PATHS.map((path) =>
    buildCookieHeader(REFRESH_COOKIE_NAME, '', { path, clear: true }),
  );
  res.setHeader('Set-Cookie', headers);
}

/** Manual Cookie header parse — no extra npm dependency. */
export function parseCookieHeader(header) {
  const cookies = {};
  if (!header || typeof header !== 'string') return cookies;
  for (const segment of header.split(';')) {
    const trimmed = segment.trim();
    if (!trimmed) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const name = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1);
    try {
      cookies[name] = decodeURIComponent(value);
    } catch {
      cookies[name] = value;
    }
  }
  return cookies;
}

export function readRefreshTokenFromRequest(req) {
  const cookies = req.cookies ?? parseCookieHeader(req.headers?.cookie);
  const fromCookie = cookies[REFRESH_COOKIE_NAME];
  if (fromCookie) return fromCookie;
  const fromBody = req.body?.refresh_token;
  if (fromBody) return fromBody;
  return null;
}
