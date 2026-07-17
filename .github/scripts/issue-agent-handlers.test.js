'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  parseLinkedIssues,
  uatTagName,
  parseUatTag,
} = require('./issue-agent-handlers');

test('parseLinkedIssues accepts refs fixes closes resolves', () => {
  const body = 'Summary\n\nRefs #122\nAlso related to Fixes #99';
  assert.deepEqual(parseLinkedIssues(body), [122, 99]);
});

test('parseLinkedIssues deduplicates issue numbers', () => {
  const body = 'Refs #5 and refs #5';
  assert.deepEqual(parseLinkedIssues(body), [5]);
});

test('uatTagName uses YYMMDD and PR number', () => {
  const now = new Date('2026-07-16T15:00:00Z');
  assert.equal(uatTagName(193, now), 'uat-260716-193');
});

test('parseUatTag extracts PR number from tag', () => {
  assert.deepEqual(parseUatTag('uat-260716-193'), {
    yymmdd: '260716',
    prNumber: 193,
  });
});

test('parseUatTag rejects legacy release branch names', () => {
  assert.equal(parseUatTag('release/uat-260716-issue-122'), null);
});
