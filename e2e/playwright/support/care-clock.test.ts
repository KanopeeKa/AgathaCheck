import assert from 'node:assert/strict';
import { test } from 'node:test';
import type { Page, Route } from '@playwright/test';
import { setPageCareClock } from './care-clock';

type Registration = {
  matches: (url: URL) => boolean;
  handle: (route: Route) => Promise<void>;
};

function pageHarness() {
  const registrations: Registration[] = [];
  let closed = false;
  const page = {
    isClosed: () => closed,
    async route(matches: Registration['matches'], handle: Registration['handle']) {
      registrations.push({ matches, handle });
    },
    async unroute(matches: Registration['matches'], handle: Registration['handle']) {
      assert.equal(closed, false, 'Closed pages cannot remove routes');
      const index = registrations.findIndex((r) => r.matches === matches && r.handle === handle);
      assert.notEqual(index, -1);
      registrations.splice(index, 1);
    },
    async setExtraHTTPHeaders() {
      assert.fail('Clock must not modify global page headers');
    },
  } as unknown as Page;
  return { page, registrations, close: () => { closed = true; } };
}

const apiBase = 'http://localhost:3000/backend/api';

test('clock targets only the configured same-origin API, not Flutter/CDN resources', async () => {
  const { page, registrations } = pageHarness();
  await setPageCareClock(page, '2030-06-05T12:00', apiBase);
  const { matches } = registrations[0];
  assert.equal(matches(new URL(`${apiBase}/health-entries?pet_id=one`)), true);
  assert.equal(matches(new URL(apiBase)), true);
  for (const url of [
    'https://www.gstatic.com/flutter-canvaskit/canvaskit.wasm',
    'https://fonts.gstatic.com/font.woff2',
    'http://localhost:3000/main.dart.js',
    'http://localhost:3000/backend/api-other/items',
    'http://localhost:3001/backend/api/health-entries',
    'https://external.example/backend/api/health-entries',
  ]) assert.equal(matches(new URL(url)), false, url);
});

test('clock preserves request headers and allows other route handlers to run', async () => {
  const { page, registrations } = pageHarness();
  await setPageCareClock(page, '2030-06-05T12:00', apiBase);
  let forwarded: unknown;
  await registrations[0].handle({
    request: () => ({ allHeaders: async () => ({
      authorization: 'test-auth', 'x-existing': 'keep', 'x-care-as-of': 'old',
    }) }),
    fallback: async (options: unknown) => { forwarded = options; },
  } as unknown as Route);
  assert.deepEqual(forwarded, { headers: {
    authorization: 'test-auth', 'x-existing': 'keep', 'x-care-as-of': '2030-06-05T12:00',
  } });
});

test('updating and clearing the clock removes only its own route', async () => {
  const { page, registrations } = pageHarness();
  await page.route(() => false, async () => {});
  const unrelated = registrations[0];
  await setPageCareClock(page, '2030-06-05T12:00', apiBase);
  const initial = registrations[1];
  await setPageCareClock(page, '2030-06-06T12:00', apiBase);
  assert.equal(registrations.length, 2);
  assert.notEqual(registrations[1], initial);
  await setPageCareClock(page, null, apiBase);
  await setPageCareClock(page, null, apiBase);
  assert.deepEqual(registrations, [unrelated]);
});

test('clock cleanup after a timed-out page closes does not mask the test failure', async () => {
  const { page, close } = pageHarness();
  await setPageCareClock(page, '2030-06-05T12:00', apiBase);
  close();
  await setPageCareClock(page, null, apiBase);
  await setPageCareClock(page, null, apiBase);
});