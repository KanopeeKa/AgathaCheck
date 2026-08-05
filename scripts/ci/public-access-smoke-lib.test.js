#!/usr/bin/env node
'use strict';

/**
 * Unit tests for public-access smoke classifiers.
 * Mirrors shell contract in public-access-smoke-lib.sh and probes the bash lib.
 */

const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const path = require('node:path');

const lib = path.join(__dirname, 'public-access-smoke-lib.sh');

/** Pure JS mirrors of shell helpers (keep in sync with .sh). */
function pasIsTeaserHtml(body) {
  return (
    String(body).includes('data-site-mode="coming-soon"') ||
    String(body).includes("data-site-mode='coming-soon'")
  );
}

function pasIsFlutterAssetPath(p) {
  return /main\.dart\.js|flutter\.js|flutter_bootstrap\.js|flutter_service_worker\.js/.test(
    String(p),
  );
}

function pasBodyMentionsFlutterMain(body) {
  return String(body).includes('main.dart.js');
}

function pasClassifyHttpCode(code) {
  return String(code) === '401' ? 'basic_auth' : '';
}

function pasClassifyTeaserBody(mode, body) {
  if (mode === 'coming_soon') {
    if (!pasIsTeaserHtml(body)) return 'teaser_mismatch';
    if (pasBodyMentionsFlutterMain(body)) return 'flutter_served_in_teaser_mode';
  }
  return 'ok';
}

function probe(fn, ...args) {
  return execFileSync('bash', [lib, ...args], {
    env: { ...process.env, PAS_SMOKE_LIB_PROBE: fn },
    encoding: 'utf8',
  }).trim();
}

test('JS: pasIsTeaserHtml detects data-site-mode marker', () => {
  assert.equal(pasIsTeaserHtml('<html data-site-mode="coming-soon">'), true);
  assert.equal(pasIsTeaserHtml("<body data-site-mode='coming-soon'>"), true);
  assert.equal(pasIsTeaserHtml('<html lang="en">'), false);
});

test('JS: pasIsFlutterAssetPath / main.dart.js detection', () => {
  assert.equal(pasIsFlutterAssetPath('/main.dart.js'), true);
  assert.equal(pasIsFlutterAssetPath('/flutter.js'), true);
  assert.equal(pasIsFlutterAssetPath('/assets/logo.png'), false);
  assert.equal(pasBodyMentionsFlutterMain('src="main.dart.js"'), true);
});

test('JS: pasClassifyHttpCode maps 401 → basic_auth', () => {
  assert.equal(pasClassifyHttpCode(401), 'basic_auth');
  assert.equal(pasClassifyHttpCode('401'), 'basic_auth');
  assert.equal(pasClassifyHttpCode(403), '');
  assert.equal(pasClassifyHttpCode(200), '');
});

test('JS: pasClassifyTeaserBody failure kinds', () => {
  assert.equal(
    pasClassifyTeaserBody('coming_soon', '<html data-site-mode="coming-soon">'),
    'ok',
  );
  assert.equal(pasClassifyTeaserBody('coming_soon', '<html>'), 'teaser_mismatch');
  assert.equal(
    pasClassifyTeaserBody(
      'coming_soon',
      '<html data-site-mode="coming-soon"><script src="main.dart.js"></script>',
    ),
    'flutter_served_in_teaser_mode',
  );
  assert.equal(pasClassifyTeaserBody('app', '<html>'), 'ok');
});

test('bash probe: pas_is_teaser_html', () => {
  assert.equal(probe('pas_is_teaser_html', '<html data-site-mode="coming-soon">'), 'true');
  assert.equal(probe('pas_is_teaser_html', '<html>'), 'false');
});

test('bash probe: pas_is_flutter_asset_path', () => {
  assert.equal(probe('pas_is_flutter_asset_path', '/main.dart.js'), 'true');
  assert.equal(probe('pas_is_flutter_asset_path', '/logo.png'), 'false');
});

test('bash probe: pas_classify_http_code', () => {
  assert.equal(probe('pas_classify_http_code', '401'), 'basic_auth');
  assert.equal(probe('pas_classify_http_code', '200'), '');
});

test('bash probe: pas_classify_teaser_body', () => {
  assert.equal(
    probe('pas_classify_teaser_body', 'coming_soon', '<html data-site-mode="coming-soon">'),
    'ok',
  );
  assert.equal(probe('pas_classify_teaser_body', 'coming_soon', '<html>'), 'teaser_mismatch');
  assert.equal(
    probe(
      'pas_classify_teaser_body',
      'coming_soon',
      '<html data-site-mode="coming-soon">main.dart.js',
    ),
    'flutter_served_in_teaser_mode',
  );
});
