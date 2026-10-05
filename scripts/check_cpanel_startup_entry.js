#!/usr/bin/env node
/**
 * cPanel / CloudLinux Passenger loads bin/start.js via node-loader require(), not
 * `node bin/start.js`. ESM modules with top-level await throw ERR_REQUIRE_ASYNC_MODULE.
 *
 * @see DEPLOYMENT_CPANEL_NODEJS.md
 */
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const START_REL = path.join('server', 'bin', 'start.js');
const START_PATH = path.join(ROOT, START_REL);
const SERVER_DIR = path.join(ROOT, 'server');

export function assertPassengerRequireSafe(startPath = START_PATH) {
  if (!fs.existsSync(startPath)) {
    throw new Error(`check_cpanel_startup_entry: missing ${path.relative(ROOT, startPath)}`);
  }

  // require() runs module evaluation synchronously until the first await in the graph.
  // process.exit(0) immediately after require() avoids leaving a listening server or
  // waiting on verifyPgDateParser (async). PORT/PG* are set so a future sync listen
  // cannot bind production port 3000 during the probe.
  const probe = `
const { createRequire } = require('node:module');
const startPath = ${JSON.stringify(startPath)};
const req = createRequire(startPath);
try {
  req(startPath);
} catch (err) {
  if (err && err.code === 'ERR_REQUIRE_ASYNC_MODULE') {
    console.error(
      'bin/start.js or a module it imports uses top-level await; cPanel Passenger require() cannot load it.',
    );
    if (err.message) console.error(err.message);
    process.exit(2);
  }
  console.error(err && err.stack ? err.stack : err);
  process.exit(1);
}
process.exit(0);
`;

  const result = spawnSync(
    process.execPath,
    ['--experimental-print-required-tla', '-e', probe],
    {
      cwd: SERVER_DIR,
      env: {
        ...process.env,
        NODE_ENV: 'test',
        PORT: '0',
        PGCONNECT_TIMEOUT: '1',
        PGHOST: '127.0.0.1',
        PGPORT: '1',
      },
      encoding: 'utf8',
      timeout: 15_000,
    },
  );

  if (result.status === 2) {
    const detail = (result.stderr || result.stdout || '').trim();
    throw new Error(detail || 'ERR_REQUIRE_ASYNC_MODULE');
  }
  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || '').trim();
    throw new Error(
      `check_cpanel_startup_entry: unexpected failure loading start.js (exit ${result.status})${detail ? `: ${detail}` : ''}`,
    );
  }
}

const invoked = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  try {
    assertPassengerRequireSafe();
    console.log('check_cpanel_startup_entry: OK');
  } catch (err) {
    console.error(`check_cpanel_startup_entry: ${err.message}`);
    process.exit(1);
  }
}
