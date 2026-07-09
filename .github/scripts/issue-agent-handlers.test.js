'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { parseLinkedIssues, uatBranchName } = require('./issue-agent-handlers');

test('parseLinkedIssues accepts refs fixes closes resolves', () => {
  const body = 'Summary\n\nRefs #122\nAlso related to Fixes #99';
  assert.deepEqual(parseLinkedIssues(body), [122, 99]);
});

test('parseLinkedIssues deduplicates issue numbers', () => {
  const body = 'Refs #5 and refs #5';
  assert.deepEqual(parseLinkedIssues(body), [5]);
});

test('uatBranchName uses YYMMDD and issue number', () => {
  const branch = uatBranchName(122);
  assert.match(branch, /^release\/uat-\d{6}-issue-122$/);
});
