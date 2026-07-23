#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeStatusName } = require('./lib/execute_plan_project');

test('normalizeStatusName maps common aliases', () => {
  assert.equal(normalizeStatusName('in_progress'), 'In Progress');
  assert.equal(normalizeStatusName('backlog'), 'Backlog');
  assert.equal(normalizeStatusName('Done'), 'Done');
});
