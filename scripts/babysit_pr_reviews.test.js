#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  classifyReviewer,
  detectBugbotUnavailableFromIssueComments,
  assessBugbotStatus,
  assessCopilotStatus,
  normalizeReviewThreads,
  buildCollectReport,
  parsePrRef,
} = require('./lib/babysit_pr_reviews_lib');

test('classifyReviewer maps cursor and copilot logins', () => {
  assert.equal(classifyReviewer('cursor'), 'bugbot');
  assert.equal(classifyReviewer('cursor[bot]'), 'bugbot');
  assert.equal(classifyReviewer('copilot-pull-request-reviewer'), 'copilot');
  assert.equal(classifyReviewer('copilot-pull-request-reviewer[bot]'), 'copilot');
  assert.equal(classifyReviewer('human-dev'), 'human');
});

test('detectBugbotUnavailableFromIssueComments finds usage limit comment', () => {
  const result = detectBugbotUnavailableFromIssueComments([
    {
      user: { login: 'cursor' },
      body: '<h3>Bugbot could not run - usage limit reached</h3>',
      html_url: 'https://example.com/comment',
    },
  ]);
  assert.equal(result.unavailable, true);
  assert.equal(result.reason, 'usage_limit');
});

test('assessBugbotStatus marks unavailable when cursor posts usage limit', () => {
  const status = assessBugbotStatus({
    reviews: [],
    issueComments: [
      { user: { login: 'cursor' }, body: 'Bugbot hit a usage limit' },
    ],
    checkRuns: [],
  });
  assert.equal(status.state, 'unavailable');
});

test('assessBugbotStatus pending when bugbot check is in progress', () => {
  const status = assessBugbotStatus({
    reviews: [],
    issueComments: [],
    checkRuns: [{ name: 'Cursor Bugbot', status: 'IN_PROGRESS', conclusion: null }],
  });
  assert.equal(status.state, 'pending');
});

test('assessCopilotStatus complete when copilot review exists', () => {
  const status = assessCopilotStatus({
    reviews: [{ user: { login: 'copilot-pull-request-reviewer[bot]' }, body: 'overview' }],
    reviewComments: [
      { user: { login: 'copilot-pull-request-reviewer[bot]' }, body: 'nit' },
    ],
    reviewRequests: [],
  });
  assert.equal(status.state, 'complete');
  assert.equal(status.inlineCommentCount, 1);
});

test('normalizeReviewThreads maps graphql nodes', () => {
  const threads = normalizeReviewThreads([
    {
      isResolved: false,
      comments: {
        nodes: [
          {
            author: { login: 'copilot-pull-request-reviewer' },
            body: 'Fix this',
            path: 'lib/a.dart',
            line: 12,
            url: 'https://example.com/thread',
          },
        ],
      },
    },
  ]);
  assert.equal(threads.length, 1);
  assert.equal(threads[0].reviewer, 'copilot');
  assert.equal(threads[0].path, 'lib/a.dart');
});

test('buildCollectReport warns when bugbot unavailable but copilot threads exist', () => {
  const report = buildCollectReport({
    prNumber: 531,
    bugbot: { state: 'unavailable', reason: 'usage_limit' },
    copilot: { state: 'complete', reason: 'review_submitted', inlineCommentCount: 4 },
    threads: [
      {
        isResolved: false,
        reviewer: 'copilot',
        author: 'copilot-pull-request-reviewer',
        path: 'a.dart',
        line: 1,
        body: 'issue',
        url: 'https://example.com',
        commentCount: 1,
      },
    ],
  });
  assert.equal(report.readyForTriage, true);
  assert.equal(report.summary.copilotCount, 1);
  assert.match(report.warnings[0], /Copilot/);
});

test('buildCollectReport halts on bugbot timeout', () => {
  const report = buildCollectReport({
    prNumber: 1,
    bugbot: { state: 'pending', reason: 'not_seen_yet' },
    copilot: { state: 'absent', reason: 'no_review' },
    threads: [],
    timedOut: true,
  });
  assert.equal(report.halt, true);
  assert.equal(report.haltReason, 'bugbot_timeout');
});

test('parsePrRef accepts url, slug, and number', () => {
  assert.deepEqual(parsePrRef('https://github.com/o/r/pull/12'), {
    owner: 'o',
    repo: 'r',
    number: 12,
  });
  assert.deepEqual(parsePrRef('o/r#12'), { owner: 'o', repo: 'r', number: 12 });
  assert.deepEqual(parsePrRef('12', 'o', 'r'), { owner: 'o', repo: 'r', number: 12 });
});
