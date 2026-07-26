'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { isUatPromoteTagJobSkipped } = require('./uat-promote-tag-job-skipped');

test('isUatPromoteTagJobSkipped: merge promote skipped', () => {
  assert.equal(
    isUatPromoteTagJobSkipped([
      { name: 'Evaluate UAT deploy cadence', conclusion: 'success' },
      { name: 'Create UAT tag', conclusion: 'skipped' },
    ]),
    true,
  );
});

test('isUatPromoteTagJobSkipped: catch-up promote skipped', () => {
  assert.equal(
    isUatPromoteTagJobSkipped([
      { name: 'Create UAT tag (catch-up)', conclusion: 'skipped' },
    ]),
    true,
  );
});

test('isUatPromoteTagJobSkipped: tag created', () => {
  assert.equal(
    isUatPromoteTagJobSkipped([
      { name: 'Create UAT tag (catch-up)', conclusion: 'success' },
    ]),
    false,
  );
});
