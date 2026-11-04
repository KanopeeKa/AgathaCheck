'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const WORKFLOW = path.join(__dirname, '../../.github/workflows/execute-plan-driver.yml');

test('execute-plan-driver drive job uses one global concurrency group (issue #2005)', () => {
  const text = fs.readFileSync(WORKFLOW, 'utf8');
  const driveBlock = text.split('  drive:')[1] || '';
  assert.match(driveBlock, /concurrency:\s*\n\s+group:\s*execute-plan-driver\s*\n/m);
  assert.doesNotMatch(driveBlock, /group:\s*execute-plan-driver-\$\{\{/);
});
