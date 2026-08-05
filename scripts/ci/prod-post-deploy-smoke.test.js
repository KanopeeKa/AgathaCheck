#!/usr/bin/env node
'use strict';

/**
 * Fixture tests for scripts/prod-post-deploy-smoke.sh
 * Spins a tiny local HTTP server for teaser vs Flutter responses.
 *
 * Important: do not use spawnSync while the fixture server runs in this process —
 * a sync spawn blocks the event loop and deadlocks curl against the local server.
 */

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { execFile, execFileSync } = require('node:child_process');
const { promisify } = require('node:util');
const path = require('node:path');

const execFileAsync = promisify(execFile);

const ROOT = path.join(__dirname, '..', '..');
const SCRIPT = path.join(ROOT, 'scripts', 'prod-post-deploy-smoke.sh');
const LIB = path.join(__dirname, 'public-access-smoke-lib.sh');

const TEASER_HTML =
  '<!DOCTYPE html><html lang="en" data-site-mode="coming-soon"><body>Coming soon</body></html>';
const FLUTTER_HTML =
  '<!DOCTYPE html><html><head><script src="main.dart.js"></script></head><body>flutter</body></html>';
const HEALTH_OK = '{"status":"OK"}';

function probe(fn, ...args) {
  return execFileSync('bash', [LIB, ...args], {
    env: { ...process.env, PAS_SMOKE_LIB_PROBE: fn },
    encoding: 'utf8',
  }).trim();
}

/**
 * @param {{ mode: 'teaser'|'flutter'; serveDartJs?: boolean }} opts
 * @returns {Promise<{ baseUrl: string, close: () => Promise<void> }>}
 */
function startFixtureServer(opts) {
  const serveDartJs = opts.serveDartJs === true;
  const server = http.createServer((req, res) => {
    const url = req.url || '/';
    if (url.startsWith('/backend/health')) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(HEALTH_OK);
      return;
    }
    if (url.startsWith('/main.dart.js')) {
      if (serveDartJs) {
        res.writeHead(200, { 'Content-Type': 'application/javascript' });
        res.end('// flutter');
      } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('not found');
      }
      return;
    }
    if (url.startsWith('/landing')) {
      if (opts.mode === 'flutter') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(FLUTTER_HTML);
      } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('not found');
      }
      return;
    }
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(opts.mode === 'teaser' ? TEASER_HTML : FLUTTER_HTML);
  });

  return new Promise((resolve, reject) => {
    server.listen(0, '127.0.0.1', () => {
      const addr = server.address();
      if (!addr || typeof addr === 'string') {
        reject(new Error('failed to bind fixture server'));
        return;
      }
      resolve({
        baseUrl: `http://127.0.0.1:${addr.port}`,
        close: () =>
          new Promise((resClose, rejClose) => {
            server.close((err) => (err ? rejClose(err) : resClose()));
          }),
      });
    });
    server.on('error', reject);
  });
}

/**
 * @returns {Promise<{ status: number|null, stdout: string, stderr: string }>}
 */
async function runSmoke(baseUrl, mode, extraEnv = {}) {
  try {
    const { stdout, stderr } = await execFileAsync('bash', [SCRIPT], {
      env: {
        ...process.env,
        PROD_BASE_URL: baseUrl,
        PROD_PUBLIC_MODE: mode,
        MAX_ATTEMPTS: '2',
        SLEEP_SECS: '0',
        ...extraEnv,
      },
      encoding: 'utf8',
      timeout: 15000,
    });
    return { status: 0, stdout, stderr };
  } catch (err) {
    return {
      status: typeof err.code === 'number' ? err.code : 1,
      stdout: err.stdout || '',
      stderr: err.stderr || String(err.message || err),
    };
  }
}

test('bash lib: teaser classification helpers', () => {
  assert.equal(probe('pas_is_teaser_html', TEASER_HTML), 'true');
  assert.equal(probe('pas_is_teaser_html', FLUTTER_HTML), 'false');
  assert.equal(probe('pas_classify_teaser_body', 'coming_soon', TEASER_HTML), 'ok');
  assert.equal(probe('pas_classify_teaser_body', 'coming_soon', FLUTTER_HTML), 'teaser_mismatch');
  assert.equal(
    probe(
      'pas_classify_teaser_body',
      'coming_soon',
      '<html data-site-mode="coming-soon">main.dart.js',
    ),
    'flutter_served_in_teaser_mode',
  );
});

test('coming_soon mode: teaser OK + health OK + dart.js not 200 → exit 0', async () => {
  const fx = await startFixtureServer({ mode: 'teaser', serveDartJs: false });
  try {
    const r = await runSmoke(fx.baseUrl, 'coming_soon');
    assert.equal(r.status, 0, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(r.stdout, /Teaser HTML OK/);
    assert.match(r.stdout, /Production post-deploy smoke passed/);
  } finally {
    await fx.close();
  }
});

test('coming_soon mode: flutter root → teaser_mismatch exit 1', async () => {
  const fx = await startFixtureServer({ mode: 'flutter', serveDartJs: false });
  try {
    const r = await runSmoke(fx.baseUrl, 'coming_soon');
    assert.equal(r.status, 1, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(`${r.stdout}\n${r.stderr}`, /teaser_mismatch/);
  } finally {
    await fx.close();
  }
});

test('coming_soon mode: main.dart.js still 200 → flutter_served_in_teaser_mode', async () => {
  const fx = await startFixtureServer({ mode: 'teaser', serveDartJs: true });
  try {
    const r = await runSmoke(fx.baseUrl, 'coming_soon');
    assert.equal(r.status, 1, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(`${r.stdout}\n${r.stderr}`, /flutter_served_in_teaser_mode/);
  } finally {
    await fx.close();
  }
});

test('app mode: health + landing → exit 0', async () => {
  const fx = await startFixtureServer({ mode: 'flutter', serveDartJs: true });
  try {
    const r = await runSmoke(fx.baseUrl, 'app');
    assert.equal(r.status, 0, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(r.stdout, /Landing page reachable|Root page reachable/);
  } finally {
    await fx.close();
  }
});

test('invalid PROD_PUBLIC_MODE → exit 1', async () => {
  const r = await runSmoke('http://127.0.0.1:9', 'open');
  assert.equal(r.status, 1);
  assert.match(`${r.stdout}\n${r.stderr}`, /invalid_prod_public_mode|must be 'coming_soon' or 'app'/);
});
