#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { yymmddFromIso } = require('./lib/uat_deploy_run_resolve');

test('yymmddFromIso extracts UTC date from ISO timestamp', () => {
  assert.equal(yymmddFromIso('2026-07-24T13:50:20Z'), '260724');
  assert.equal(yymmddFromIso(''), null);
});
