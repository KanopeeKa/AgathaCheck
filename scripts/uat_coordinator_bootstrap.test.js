#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  COORDINATION_TITLE,
  renderIssueBody,
  parseArgs,
} = require('./uat_coordinator_bootstrap');

test('COORDINATION_TITLE is stable', () => {
  assert.equal(COORDINATION_TITLE, '[uat-coordinator] UAT deploy queue');
});

test('renderIssueBody includes issue number in checklist', () => {
  const body = renderIssueBody(313, 'KanopeeKa', 'AgathaCheck');
  assert.match(body, /UAT_COORDINATION_ISSUE=313/);
  assert.match(body, /uat-coordinator-bootstrap\.md/);
  assert.match(body, /github\.com\/KanopeeKa\/AgathaCheck/);
});

test('parseArgs rejects invalid --issue', () => {
  assert.throws(() => parseArgs(['--issue']), /--issue requires/);
  assert.throws(() => parseArgs(['--issue', '0']), /--issue must be a positive integer/);
  assert.throws(() => parseArgs(['--issue', 'abc']), /--issue must be a positive integer/);
});

test('parseArgs defaults', () => {
  const flags = parseArgs([]);
  assert.equal(flags.write, false);
  assert.equal(flags.pin, false);
  assert.equal(flags.issue, null);
});

test('parseArgs reads flags', () => {
  const flags = parseArgs(['--write', '--pin', '--issue', '313']);
  assert.equal(flags.write, true);
  assert.equal(flags.pin, true);
  assert.equal(flags.issue, 313);
});
