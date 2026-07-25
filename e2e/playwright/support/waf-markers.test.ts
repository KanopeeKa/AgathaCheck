import { test } from 'node:test';
import assert from 'node:assert/strict';
import { authSignupProbeReachable, bodyShowsWafChallenge } from './waf-markers';

test('bodyShowsWafChallenge detects English and French Tiger Protect markers', () => {
  assert.equal(bodyShowsWafChallenge('<div class="o2s-browser-check"></div>'), true);
  assert.equal(bodyShowsWafChallenge('<title>Security check</title>'), true);
  assert.equal(bodyShowsWafChallenge('Test de sécurité'), true);
  assert.equal(bodyShowsWafChallenge('{"status":"OK"}'), false);
  assert.equal(bodyShowsWafChallenge('{"error":"Email and password are required."}'), false);
});

test('authSignupProbeReachable accepts JSON validation errors and rejects HTML outages', () => {
  assert.equal(
    authSignupProbeReachable(400, '{"error":"Email and password are required."}'),
    'ok',
  );
  assert.equal(
    authSignupProbeReachable(503, '<div class="o2s-browser-check"></div>'),
    'waf',
  );
  assert.equal(
    authSignupProbeReachable(500, '<html><body>Internal Server Error</body></html>'),
    'down',
  );
});
