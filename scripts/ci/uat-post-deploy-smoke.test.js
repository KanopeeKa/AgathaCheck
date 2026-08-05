#!/usr/bin/env node
'use strict';

/**
 * Fixture tests for scripts/uat-post-deploy-smoke.sh
 * Spins a tiny local HTTP server (open vs Basic Auth).
 *
 * Important: do not use spawnSync while the fixture server runs in this process —
 * a sync spawn blocks the event loop and deadlocks curl against the local server.
 */

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const path = require('node:path');

const execFileAsync = promisify(execFile);

const ROOT = path.join(__dirname, '..', '..');
const SCRIPT = path.join(ROOT, 'scripts', 'uat-post-deploy-smoke.sh');

const HEALTH_OK = '{"status":"OK"}';
const BACKEND_ROOT = 'Backend alive';
const LANDING_HTML = '<!DOCTYPE html><html><body>landing</body></html>';
const AUTH_USER = 'uat-smoke';
const AUTH_PASS = 'uat-secret';

/**
 * @param {{ requireAuth?: boolean }} opts
 * @returns {Promise<{ baseUrl: string, close: () => Promise<void> }>}
 */
function startFixtureServer(opts = {}) {
  const requireAuth = opts.requireAuth === true;
  const server = http.createServer((req, res) => {
    const url = req.url || '/';
    const auth = req.headers.authorization || '';
    const expected =
      'Basic ' + Buffer.from(`${AUTH_USER}:${AUTH_PASS}`).toString('base64');

    if (requireAuth && auth !== expected) {
      res.writeHead(401, {
        'Content-Type': 'text/plain',
        'WWW-Authenticate': 'Basic realm="UAT"',
      });
      res.end('Unauthorized');
      return;
    }

    if (url.startsWith('/backend/health')) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(HEALTH_OK);
      return;
    }
    if (url === '/backend/' || url === '/backend') {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end(BACKEND_ROOT);
      return;
    }
    if (url.startsWith('/landing')) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(LANDING_HTML);
      return;
    }
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('not found');
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
async function runSmoke(baseUrl, extraEnv = {}) {
  try {
    const { stdout, stderr } = await execFileAsync('bash', [SCRIPT], {
      env: {
        ...process.env,
        UAT_BASE_URL: baseUrl,
        MAX_ATTEMPTS: '2',
        SLEEP_SECS: '0',
        CURL_TLS_FLAGS: '',
        ...extraEnv,
      },
      encoding: 'utf8',
      timeout: 20000,
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

test('flag off → health 200 without auth → exit 0', async () => {
  const fx = await startFixtureServer({ requireAuth: false });
  try {
    const r = await runSmoke(fx.baseUrl, { UAT_BASIC_AUTH_ENABLED: 'false' });
    assert.equal(r.status, 0, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(r.stdout, /Backend healthy/);
    assert.match(r.stdout, /Landing page reachable/);
  } finally {
    await fx.close();
  }
});

test('flag on + anonymous 200 → fail (lock missing)', async () => {
  const fx = await startFixtureServer({ requireAuth: false });
  try {
    const r = await runSmoke(fx.baseUrl, {
      UAT_BASIC_AUTH_ENABLED: 'true',
      UAT_BASIC_AUTH_USER: AUTH_USER,
      UAT_BASIC_AUTH_PASSWORD: AUTH_PASS,
    });
    assert.equal(r.status, 1, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(`${r.stdout}\n${r.stderr}`, /uat_basic_auth_lock_missing|lock is not present|basic_auth/);
  } finally {
    await fx.close();
  }
});

test('flag on + anonymous 401 + authed health/landing OK → exit 0', async () => {
  const fx = await startFixtureServer({ requireAuth: true });
  try {
    const r = await runSmoke(fx.baseUrl, {
      UAT_BASIC_AUTH_ENABLED: 'true',
      UAT_BASIC_AUTH_USER: AUTH_USER,
      UAT_BASIC_AUTH_PASSWORD: AUTH_PASS,
    });
    assert.equal(r.status, 0, `stderr=${r.stderr}\nstdout=${r.stdout}`);
    assert.match(r.stdout, /Anonymous Basic Auth proof OK/);
    assert.match(r.stdout, /Backend healthy/);
    assert.match(r.stdout, /Landing page reachable/);
  } finally {
    await fx.close();
  }
});

test('flag on + missing secrets → fail closed', async () => {
  const r = await runSmoke('http://127.0.0.1:9', {
    UAT_BASIC_AUTH_ENABLED: 'true',
    UAT_BASIC_AUTH_USER: '',
    UAT_BASIC_AUTH_PASSWORD: '',
  });
  assert.equal(r.status, 1);
  assert.match(
    `${r.stdout}\n${r.stderr}`,
    /uat_basic_auth_secrets_missing|UAT_BASIC_AUTH_USER|Fail closed/,
  );
});
