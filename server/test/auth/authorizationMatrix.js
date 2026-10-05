/**
 * Frozen HTTP status matrix for auth endpoints (Batch H.4).
 * Probes run against /api/auth and /backend/api/auth — statuses must not drift.
 */
import { makeExpiredToken, makeToken, userEmail } from './helpers.js';

export const AUTH_API_PREFIXES = ['/api/auth', '/backend/api/auth'];

/**
 * @typedef {{ method: string, path: string, setup?: (ctx: object) => void | Promise<void>, headers?: Record<string,string>, body?: object, status: number }} MatrixProbe
 */

/** @type {MatrixProbe[]} */
export const AUTH_STATUS_MATRIX = [
  { method: 'get', path: '/me', status: 401 },
  {
    method: 'get',
    path: '/me',
    headers: { Authorization: 'Bearer invalid' },
    status: 401,
  },
  {
    method: 'get',
    path: '/me',
    headers: () => ({ Authorization: `Bearer ${makeExpiredToken()}` }),
    status: 401,
  },
  {
    method: 'get',
    path: '/me/foster-contacts',
    status: 401,
  },
  {
    method: 'put',
    path: '/me',
    body: {},
    status: 401,
  },
  {
    method: 'patch',
    path: '/me',
    body: {},
    status: 401,
  },
  {
    method: 'post',
    path: '/me/photo',
    status: 401,
  },
  {
    method: 'delete',
    path: '/me',
    body: {},
    status: 401,
  },
  {
    method: 'get',
    path: '/me/export',
    status: 401,
  },
  {
    method: 'post',
    path: '/change-password',
    body: {},
    status: 401,
  },
  {
    method: 'post',
    path: '/forgot-password',
    body: {},
    status: 400,
  },
  {
    method: 'post',
    path: '/reset-password',
    body: {},
    status: 400,
  },
  {
    method: 'post',
    path: '/signup',
    body: {},
    status: 400,
  },
  {
    method: 'post',
    path: '/login',
    body: {},
    status: 400,
  },
  {
    method: 'post',
    path: '/refresh',
    body: {},
    status: 400,
  },
  {
    method: 'post',
    path: '/login',
    body: { email: userEmail, password: 'wrong' },
    status: 401,
  },
  {
    method: 'get',
    path: '/erasure/00000000-0000-4000-8000-000000000001',
    status: 404,
  },
  {
    method: 'put',
    path: '/me',
    headers: () => ({ Authorization: `Bearer ${makeToken()}` }),
    body: { pinned_organization_id: 'not-a-uuid' },
    status: 400,
  },
  {
    method: 'put',
    path: '/me',
    headers: () => ({ Authorization: `Bearer ${makeToken()}` }),
    body: { pinned_organization_id: '00000000-0000-4000-8000-000000000099' },
    status: 403,
  },
];

export function resolveProbeHeaders(probe) {
  if (!probe.headers) return {};
  if (typeof probe.headers === 'function') {
    return probe.headers();
  }
  return probe.headers;
}
