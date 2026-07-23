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
  const body = renderIssueBody(313);
  assert.match(body, /UAT_COORDINATION_ISSUE=313/);
  assert.match(body, /uat-coordinator-bootstrap\.md/);
  assert.match(body, /Pin this issue/);
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
