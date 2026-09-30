#!/usr/bin/env node
/**
 * UAT in-host smoke — loopback HTTP only (bypasses Tiger Protect WAF).
 *
 * Usage:
 *   node scripts/uat-inhost-smoke.mjs --base-url http://127.0.0.1:PORT
 *   node scripts/uat-inhost-smoke.mjs --local   # start ephemeral server (dev/CI)
 *
 * On UAT SSH: remote wrapper sets --base-url after starting bin/start.js on 127.0.0.1.
 */
import { spawn } from 'node:child_process';
import { createServer } from 'node:net';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

import {
  parseMigrationStatusOutput,
  runInhostApiSmoke,
} from './uat-inhost-smoke-lib.js';

const execFileAsync = promisify(execFile);
const __dirname = dirname(fileURLToPath(import.meta.url));
const serverRoot = resolve(__dirname, '..');

function parseArgs(argv) {
  const opts = {
    baseUrl: null,
    local: false,
    skipMigrations: false,
  };
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--local') {
      opts.local = true;
    } else if (arg === '--skip-migrations') {
      opts.skipMigrations = true;
    } else if (arg === '--base-url' && argv[i + 1]) {
      opts.baseUrl = argv[++i];
    } else if (arg === '--help' || arg === '-h') {
      console.log(`Usage: node scripts/uat-inhost-smoke.mjs [--base-url URL] [--local] [--skip-migrations]`);
      process.exit(0);
    } else {
      console.error(`Unknown argument: ${arg}`);
      process.exit(2);
    }
  }
  if (!opts.baseUrl && !opts.local) {
    console.error('Provide --base-url or --local');
    process.exit(2);
  }
  return opts;
}

function freePort() {
  return new Promise((resolvePort, reject) => {
    const s = createServer();
    s.listen(0, '127.0.0.1', () => {
      const { port } = s.address();
      s.close((err) => (err ? reject(err) : resolvePort(port)));
    });
    s.on('error', reject);
  });
}

async function waitForHealth(baseUrl, timeoutMs = 60_000) {
  const deadline = Date.now() + timeoutMs;
  const url = `${baseUrl.replace(/\/$/, '')}/backend/health`;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.ok) {
        return;
      }
    } catch {
      // retry
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error(`Timed out waiting for ${url}`);
}

async function checkMigrations() {
  const { stdout, stderr } = await execFileAsync('node', ['scripts/migrate.js', 'status'], {
    cwd: serverRoot,
    env: process.env,
    maxBuffer: 10 * 1024 * 1024,
  });
  const output = `${stdout}\n${stderr}`;
  const { ok, pending } = parseMigrationStatusOutput(output);
  if (!ok) {
    console.error(output);
    throw new Error(`${pending} pending migration(s) — apply migrate.js up on UAT before smoke`);
  }
  console.log('OK: no pending migrations');
}

async function startLocalServer(port) {
  const child = spawn('node', ['bin/start.js'], {
    cwd: serverRoot,
    env: { ...process.env, PORT: String(port), HOST: '127.0.0.1' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stdout?.on('data', (d) => process.stdout.write(d));
  child.stderr?.on('data', (d) => process.stderr.write(d));
  const baseUrl = `http://127.0.0.1:${port}`;
  await waitForHealth(baseUrl);
  return { child, baseUrl };
}

async function main() {
  const opts = parseArgs(process.argv);
  let child = null;
  let baseUrl = opts.baseUrl;

  try {
    if (!opts.skipMigrations) {
      await checkMigrations();
    }

    if (opts.local) {
      const port = await freePort();
      const started = await startLocalServer(port);
      child = started.child;
      baseUrl = started.baseUrl;
      console.log(`Started local server at ${baseUrl}`);
    }

    await runInhostApiSmoke({ baseUrl });
    console.log('UAT in-host smoke: PASS');
  } finally {
    if (child && !child.killed) {
      child.kill('SIGTERM');
    }
  }
}

main().catch((err) => {
  console.error(`UAT in-host smoke: FAIL — ${err.message}`);
  process.exit(1);
});
