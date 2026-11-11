'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  parseLinkedIssues,
  isPlanControlIssue,
  uatTagName,
  parseUatTag,
  handleMergedPr,
  handleUatWorkflowResult,
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

test('isPlanControlIssue matches plan titles only', () => {
  const planTitles = [
    'light-plan: truthful-outcomes release debt (Plan B)',
    'Light-plan: Health Issues UI — care-desk alignment',
    'execute-plan: All care by care item (all-care-by-item-c455)',
    'Execute-plan: documentation-migration-csm-514a',
    'execute-plan v2: drill-2 cancel path for API-launched workers',
    '[execute-plan] away-plan-care-review-ux',
  ];
  for (const title of planTitles) {
    assert.equal(isPlanControlIssue({ title }), true, title);
  }
  assert.equal(
    isPlanControlIssue({
      title: 'Single agent-PR safety gate in execute-plan-scope (owner override)',
    }),
    false,
  );
  assert.equal(isPlanControlIssue({ title: 'Bell stays wrong after mark-all-read' }), false);
});

function recordingIo(issue, prBody) {
  const calls = [];
  const io = {
    fetchPullRequest: async () => ({ body: prBody }),
    fetchIssue: async () => issue,
    setLabels: async () => {
      calls.push('labels');
    },
    reopenIssue: async () => {
      calls.push('reopen');
    },
    updateProjectStatus: async () => {
      calls.push('status');
    },
    upsertMarkerComment: async () => {
      calls.push('comment');
    },
    assignIssue: async () => {
      calls.push('assign');
    },
  };
  return { calls, io };
}

function stubQueue(t, method) {
  const mod = require('../../scripts/lib/uat_queue_apply');
  const original = mod[method];
  mod[method] = async () => ({ skipped: true, reason: 'test' });
  t.after(() => {
    mod[method] = original;
  });
}

test('handleMergedPr reopens a plan issue without UAT status', async (t) => {
  stubQueue(t, 'syncEnqueueAfterMerge');
  const { calls, io } = recordingIo(
    { title: 'light-plan: truthful-outcomes release debt (Plan B)', state: 'CLOSED' },
    'Closes #2258',
  );

  const result = await handleMergedPr({
    owner: 'KanopeeKa',
    repo: 'AgathaCheck',
    prNumber: 2280,
    prBody: 'Release\n\nCloses #2258',
    mergeSha: '639cb48148a47a6edfcde28d880a3f582f772e46',
    token: 'test-token',
    projectsPat: 'projects-pat',
    projectId: 'project',
    statusFieldId: 'status-field',
    io,
  });

  assert.deepEqual(calls, ['labels', 'reopen']);
  assert.equal(result.results[0].status, 'reopened-plan-control');
  assert.equal(result.results[0].issueNumber, 2258);
});

test('handleUatWorkflowResult does not reopen a closed plan issue', async (t) => {
  stubQueue(t, 'syncDeployResult');
  const { calls, io } = recordingIo(
    { title: 'light-plan: truthful-outcomes release debt (Plan B)', state: 'CLOSED' },
    'Closes #2258',
  );

  const result = await handleUatWorkflowResult({
    owner: 'KanopeeKa',
    repo: 'AgathaCheck',
    deployRef: 'uat-261111-2280',
    conclusion: 'success',
    workflowUrl: 'https://github.com/KanopeeKa/AgathaCheck/actions/runs/43084042911',
    token: 'test-token',
    projectsPat: 'projects-pat',
    projectId: 'project',
    statusFieldId: 'status-field',
    io,
  });

  assert.deepEqual(calls, []);
  assert.equal(result.results[0].status, 'skipped-plan-control');
  assert.equal(result.results[0].issueNumber, 2258);
});

test('handleUatWorkflowResult still reopens a closed product issue', async (t) => {
  stubQueue(t, 'syncDeployResult');
  const { calls, io } = recordingIo(
    { title: 'Bell stays wrong after mark-all-read', state: 'CLOSED' },
    'Fixes #122',
  );

  const result = await handleUatWorkflowResult({
    owner: 'KanopeeKa',
    repo: 'AgathaCheck',
    deployRef: 'uat-261111-2280',
    conclusion: 'success',
    workflowUrl: 'https://github.com/KanopeeKa/AgathaCheck/actions/runs/1',
    token: 'test-token',
    projectsPat: null,
    projectId: null,
    statusFieldId: null,
    io,
  });

  assert.deepEqual(calls, ['reopen', 'comment']);
  assert.equal(result.results[0].status, 'In UAT');
  assert.equal(result.results[0].issueNumber, 122);
});
