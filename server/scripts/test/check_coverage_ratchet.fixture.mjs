import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import { measureAreas } from '../check_coverage_ratchet.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(__dirname, '..', 'check_coverage_ratchet.js');

test('measureAreas aggregates lib, services, and routes', () => {
  const summary = {
    total: { lines: { total: 10, covered: 5, skipped: 0, pct: 50 } },
    '/tmp/server/lib/a.js': { lines: { total: 4, covered: 2, skipped: 0, pct: 50 } },
    '/tmp/server/services/b.js': { lines: { total: 3, covered: 2, skipped: 0, pct: 66.67 } },
    '/tmp/server/routes/c.js': { lines: { total: 3, covered: 1, skipped: 0, pct: 33.33 } },
  };
  const areas = measureAreas(summary);
  assert.equal(areas.lib.lines_percent, 50);
  assert.ok(Math.abs(areas.services.lines_percent - 200 / 3) < 0.01);
  assert.ok(areas.routes.lines_percent < 40);
});

test('check_coverage_ratchet.js fails when an area drops below its floor', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'cov-ratchet-'));
  const summaryPath = path.join(tmp, 'summary.json');
  const ratchetPath = path.join(tmp, 'ratchet.json');

  fs.writeFileSync(
    summaryPath,
    JSON.stringify({
      total: { lines: { total: 10, covered: 5, skipped: 0, pct: 50 } },
      [path.join(tmp, 'server', 'lib', 'a.js')]: {
        lines: { total: 10, covered: 5, skipped: 0, pct: 50 },
      },
    }),
  );
  fs.writeFileSync(
    ratchetPath,
    JSON.stringify({
      version: 1,
      areas: {
        lib: { lines_percent: 60 },
        services: { lines_percent: 0 },
        routes: { lines_percent: 0 },
      },
    }),
  );

  const res = spawnSync(
    process.execPath,
    [SCRIPT, '--summary', summaryPath, '--ratchet', ratchetPath],
    { encoding: 'utf8' },
  );
  assert.equal(res.status, 1);
  assert.match(res.stderr + res.stdout, /BELOW FLOOR|below ratchet/i);
});
