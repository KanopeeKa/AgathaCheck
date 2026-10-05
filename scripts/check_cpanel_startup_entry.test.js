import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { assertPassengerRequireSafe } from './check_cpanel_startup_entry.js';

test('bin/start.js is loadable via Passenger-style require()', () => {
  assertPassengerRequireSafe();
});

test('detects top-level await in startup entry', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cpanel-start-'));
  fs.writeFileSync(path.join(dir, 'package.json'), '{"type":"module"}', 'utf8');
  const bad = path.join(dir, 'start.js');
  fs.writeFileSync(
    bad,
    `await Promise.resolve();
export default {};
`,
    'utf8',
  );
  assert.throws(
    () => assertPassengerRequireSafe(bad),
    /top-level await|ERR_REQUIRE_ASYNC_MODULE/i,
  );
});
