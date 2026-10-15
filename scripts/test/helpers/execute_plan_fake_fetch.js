'use strict';

/**
 * Offline `fetch` replacement for execute-plan v2 tests.
 *
 * Route keys: '<METHOD> <path>?<query sorted by key>' (path without the API base URL) or
 * 'POST /graphql'. Values: `{ status = 200, headers = {}, body }`, or `(request) => response`.
 * An array value is consumed one response per call (the last one repeats).
 * Unmatched requests throw `Error('Unrecorded request: <key>')`; every request lands in
 * `fake.calls` as `{ key, method, url, headers, body }`.
 */

function routeKey(method, rawUrl) {
  const url = new URL(rawUrl);
  const params = [...url.searchParams.entries()].sort((a, b) =>
    a[0] === b[0] ? 0 : a[0] < b[0] ? -1 : 1,
  );
  let path = url.pathname;
  const apiPrefix = '/api/v3';
  if (path.startsWith(apiPrefix)) path = path.slice(apiPrefix.length);
  const query = params.map(([k, v]) => `${k}=${v}`).join('&');
  return `${method.toUpperCase()} ${path}${query ? `?${query}` : ''}`;
}

function toResponse(spec) {
  const status = spec.status ?? 200;
  const headers = new Headers(spec.headers || {});
  let text = '';
  if (spec.body !== undefined && spec.body !== null) {
    if (typeof spec.body === 'string') {
      text = spec.body;
    } else {
      text = JSON.stringify(spec.body);
      if (!headers.has('content-type')) headers.set('content-type', 'application/json');
    }
  }
  const noBody = status === 204 || status === 304;
  return new Response(noBody ? null : text, { status, headers });
}

function createFakeFetch(routes) {
  const counters = new Map();
  const calls = [];

  async function fake(input, init = {}) {
    const url = typeof input === 'string' ? input : input.url;
    const method = (init.method || 'GET').toUpperCase();
    const key = routeKey(method, url);
    const headers = Object.fromEntries(new Headers(init.headers || {}).entries());
    let body = init.body;
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch {
        // keep raw text
      }
    }
    const request = { key, method, url, headers, body };
    calls.push(request);

    if (!Object.prototype.hasOwnProperty.call(routes, key)) {
      throw new Error(`Unrecorded request: ${key}`);
    }
    let spec = routes[key];
    if (Array.isArray(spec)) {
      const i = counters.get(key) || 0;
      counters.set(key, i + 1);
      spec = spec[Math.min(i, spec.length - 1)];
    }
    if (typeof spec === 'function') spec = await spec(request);
    if (spec instanceof Response) return spec;
    return toResponse(spec || {});
  }

  fake.calls = calls;
  return fake;
}

module.exports = { createFakeFetch, routeKey };
