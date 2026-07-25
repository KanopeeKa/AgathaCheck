import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bodyShowsWafChallenge } from './waf-markers';

test('bodyShowsWafChallenge detects English and French Tiger Protect markers', () => {
  assert.equal(bodyShowsWafChallenge('<div class="o2s-browser-check"></div>'), true);
  assert.equal(bodyShowsWafChallenge('<title>Security check</title>'), true);
  assert.equal(bodyShowsWafChallenge('Test de sécurité'), true);
  assert.equal(bodyShowsWafChallenge('{"status":"OK"}'), false);
  assert.equal(bodyShowsWafChallenge('{"error":"Email and password are required."}'), false);
});
