'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ACK_RE, formatAck, formatIgnoredNote, formatStoppedNote, parseAckBody, acceptedAuthorizationIds,
} = require('../lib/execute_plan_ack');
const { VALID_ACK_RUN } = require('./helpers/execute_plan_wp12');

test('ACK_RE and formatters', () => {
  assert.ok(ACK_RE.test(formatAck(42, 999)));
  assert.deepEqual(parseAckBody(formatAck(42, 999)), { commentId: 42, runId: 999 });
  assert.match(formatIgnoredNote('resume', 1, 'bc-x', '2026-01-01T00:00:00Z'), /resume-autonomous comment 1 not accepted/);
  assert.match(formatStoppedNote('approve', 2, 'bc-y'), /plan stopped \(needs-owner\)/);
});

test('acceptedAuthorizationIds accepts valid ack from github-actions[bot]', async () => {
  const comments = [
    { id: 1, user: { login: 'github-actions[bot]' }, body: formatAck(9001, 555) },
  ];
  const client = {
    getWorkflowRun: async (id) => {
      assert.equal(id, 555);
      return VALID_ACK_RUN;
    },
  };
  const accepted = await acceptedAuthorizationIds(client, comments);
  assert.deepEqual([...accepted], [9001]);
});

test('acceptedAuthorizationIds ignores wrong author and malformed body', async () => {
  const client = { getWorkflowRun: async () => { throw new Error('should not run'); } };
  const comments = [
    { id: 1, user: { login: 'pawpet-bot' }, body: formatAck(1, 1) },
    { id: 2, user: { login: 'github-actions[bot]' }, body: 'execute-plan: authorization accepted — comment x — run 1' },
  ];
  assert.equal((await acceptedAuthorizationIds(client, comments)).size, 0);
});

test('acceptedAuthorizationIds rejects runs with wrong workflow metadata', async () => {
  const bad = [
    { path: '.github/workflows/ci.yml', head_branch: 'main', event: 'issue_comment' },
    { path: '.github/workflows/execute-plan-approve.yml', head_branch: 'dev', event: 'issue_comment' },
    { path: '.github/workflows/execute-plan-approve.yml', head_branch: 'main', event: 'workflow_dispatch' },
  ];
  let i = 0;
  const client = { getWorkflowRun: async () => bad[i++] };
  const comments = bad.map((_, j) => ({
    id: j,
    user: { login: 'github-actions[bot]' },
    body: formatAck(100 + j, j + 1),
  }));
  assert.equal((await acceptedAuthorizationIds(client, comments)).size, 0);
  assert.equal(i, 3);
});

test('acceptedAuthorizationIds fetches each run id once for multiple acks', async () => {
  const calls = [];
  const client = {
    getWorkflowRun: async (id) => {
      calls.push(id);
      return VALID_ACK_RUN;
    },
  };
  const comments = [
    { id: 1, user: { login: 'github-actions[bot]' }, body: formatAck(10, 777) },
    { id: 2, user: { login: 'github-actions[bot]' }, body: formatAck(11, 777) },
  ];
  const accepted = await acceptedAuthorizationIds(client, comments);
  assert.deepEqual([...accepted].sort(), [10, 11]);
  assert.deepEqual(calls, [777]);
});
