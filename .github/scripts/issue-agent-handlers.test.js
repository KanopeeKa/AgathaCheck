'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  parseLinkedIssues,
  uatTagName,
  parseUatTag,
  handleMergedPr,
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

test('handleMergedPr enqueues UAT queue when PR has no linked issues', async (t) => {
  const originalEnv = process.env.UAT_COORDINATION_ISSUE;
  process.env.UAT_COORDINATION_ISSUE = '313';

  const saved = [];
  const mod = require('../../scripts/lib/uat_queue_apply');
  const original = mod.syncEnqueueAfterMerge;
  mod.syncEnqueueAfterMerge = async (input) => {
    saved.push(input);
    return { skipped: false, entry: { seq: 26 }, issueNumber: 313 };
  };
  t.after(() => {
    mod.syncEnqueueAfterMerge = original;
    if (originalEnv === undefined) {
      delete process.env.UAT_COORDINATION_ISSUE;
    } else {
      process.env.UAT_COORDINATION_ISSUE = originalEnv;
    }
  });

  const result = await handleMergedPr({
    owner: 'KanopeeKa',
    repo: 'AgathaCheck',
    prNumber: 361,
    prBody: 'Wave B integration merge — no Closes line',
    mergeSha: '4a9036584b7f4dc0ccb446b93022c8f4903d2067',
    token: 'test-token',
    projectsPat: null,
    projectId: null,
    statusFieldId: null,
  });

  assert.equal(result.skipped, true);
  assert.equal(result.reason, 'no linked issues');
  assert.equal(saved.length, 1);
  assert.equal(saved[0].enqueuedBy, 'pr-361');
  assert.equal(saved[0].prNumber, 361);
});
