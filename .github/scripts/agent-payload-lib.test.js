'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  buildAgentPayload,
  buildAgentPrompt,
  parseRunMarker,
  buildRunMarker,
} = require('./agent-payload-lib');
const { preflightIssue, findForbiddenPaths } = require('./agent-safety-lib');

test('buildAgentPayload uses parsed sections not raw comments', () => {
  const body = `### Summary

Fix empty dashboard state.

### Problem to Solve

Users see a blank dashboard.

### Proposed Solution

Load org data after login.

### Acceptance Criteria

- [ ] Dashboard shows org summary

### Security or Sensitive Area

No`;

  const payload = buildAgentPayload(
    {
      number: 12,
      url: 'https://github.com/KanopeeKa/AgathaCheck/issues/12',
      title: '[FEATURE] Dashboard empty',
      body,
      labels: ['feature'],
    },
    'https://github.com/KanopeeKa/AgathaCheck',
  );

  assert.equal(payload.issue.number, 12);
  assert.equal(payload.issue.type, 'feature');
  assert.match(payload.constraints.suggestedBranch, /^cursor\/issue-12-/);
  assert.ok(payload.constraints.forbiddenPaths.includes('.github/workflows/'));
});

test('buildAgentPrompt includes Fixes directive and forbidden paths', () => {
  const payload = buildAgentPayload(
    {
      number: 7,
      url: 'https://github.com/o/r/issues/7',
      title: '[TASK] Docs tweak',
      body: '### Summary\n\nUpdate workflow docs.\n\n### Objective\n\nClarify labels.\n\n### Scope\n\ndocs only.\n\n### Definition of Done\n\n- [ ] docs updated\n\n### Security or Sensitive Area\n\nNo',
      labels: ['task'],
    },
    'https://github.com/o/r',
  );
  const prompt = buildAgentPrompt(payload);
  assert.match(prompt, /Fixes #7/);
  assert.match(prompt, /\.github\/workflows/);
  assert.match(prompt, /pre-push-changed/);
});

test('parseRunMarker round-trips metadata', () => {
  const metadata = { agentId: 'bc-1', runId: 'run-1', status: 'running' };
  const body = `${buildRunMarker(metadata)}\n\ncomment`;
  assert.deepEqual(parseRunMarker(body), metadata);
});

test('preflight rejects busy issues', () => {
  const result = preflightIssue({
    title: 'Test',
    body: 'body long enough for testing preflight checks here',
    labels: [{ name: 'agent-approved' }, { name: 'busy' }],
  });
  assert.equal(result.ok, false);
});

test('findForbiddenPaths flags workflow edits', () => {
  const forbidden = findForbiddenPaths([
    'flutter_app/lib/main.dart',
    '.github/workflows/agent-dispatch.yml',
  ]);
  assert.deepEqual(forbidden, ['.github/workflows/agent-dispatch.yml']);
});
