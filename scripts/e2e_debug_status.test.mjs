#!/usr/bin/env node
/**
 * Tests for e2e_debug_status.mjs
 */
import assert from 'node:assert/strict';
import {
  evaluatePreflight,
  isMainPreUatGateBlocking,
  isRemedialBranch,
  issueMatchesE2eDebugSession,
  mergeBlockingPrs,
  prTouchesE2eFiles,
  SESSION_START_MARKER,
} from './e2e_debug_status.mjs';

assert.equal(isRemedialBranch('cursor/preuat-fix-abc12345-6bba'), true);
assert.equal(isRemedialBranch('cursor/preuat-fix-e959f6d6-49c7'), true);
assert.equal(isRemedialBranch('cursor/preuat-fix-14c6c5b6-2600'), true);
assert.equal(isRemedialBranch('cursor/preuat-fix-ab-2600'), false);
assert.equal(isRemedialBranch('cursor/other-branch-6bba'), false);

assert.equal(prTouchesE2eFiles([{ path: 'e2e/playwright/tests/foo.spec.ts' }]), true);
assert.equal(prTouchesE2eFiles([{ path: 'flutter_app/lib/main.dart' }]), false);

assert.equal(isMainPreUatGateBlocking({ status: 'completed', conclusion: 'success' }), false);
assert.equal(isMainPreUatGateBlocking({ status: 'completed', conclusion: 'failure' }), true);
assert.equal(isMainPreUatGateBlocking({ status: 'in_progress', conclusion: null }), true);

{
  const result = evaluatePreflight({
    remedialPrs: [],
    busyIssues: [],
    join: false,
    force: false,
    remedialBranch: null,
  });
  assert.equal(result.safe_to_start, true);
  assert.equal(result.reason, 'clear');
}

{
  const pr = {
    number: 42,
    url: 'https://github.com/example/pr/42',
    headRefName: 'cursor/preuat-fix-deadbeef-6bba',
    updatedAt: '2026-08-23T00:00:00Z',
  };
  const result = evaluatePreflight({
    remedialPrs: [pr],
    busyIssues: [],
    join: false,
    force: false,
    remedialBranch: null,
  });
  assert.equal(result.safe_to_start, false);
  assert.equal(result.reason, 'open_remedial_pr');
  assert.equal(result.recommended_action, 'join_existing_pr');
}

{
  const e2ePr = {
    number: 55,
    url: 'https://github.com/example/pr/55',
    headRefName: 'cursor/workspace-nav-e2e-8c14',
    updatedAt: '2026-08-23T00:00:00Z',
    title: 'fix(e2e): shard drift',
  };
  const result = evaluatePreflight({
    remedialPrs: [],
    e2eTouchingPrs: [e2ePr],
    mainPreUatBlocking: true,
    busyIssues: [],
    join: false,
    force: false,
    remedialBranch: null,
  });
  assert.equal(result.safe_to_start, false);
  assert.equal(result.reason, 'open_e2e_pr_while_main_red');
  assert.equal(result.blockers[0].type, 'open_e2e_pr_while_main_red');
}

{
  const e2ePr = {
    number: 55,
    url: 'https://github.com/example/pr/55',
    headRefName: 'cursor/workspace-nav-e2e-8c14',
    updatedAt: '2026-08-23T00:00:00Z',
    title: 'fix(e2e): shard drift',
  };
  const result = evaluatePreflight({
    remedialPrs: [],
    e2eTouchingPrs: [e2ePr],
    mainPreUatBlocking: false,
    busyIssues: [],
    join: false,
    force: false,
    remedialBranch: null,
  });
  assert.equal(result.safe_to_start, true);
  assert.equal(result.reason, 'clear');
}

{
  const merged = mergeBlockingPrs(
    [{ number: 1, headRefName: 'cursor/preuat-fix-deadbeef-6bba' }],
    [{ number: 2, headRefName: 'cursor/foo-e2e-8c14' }],
  );
  assert.equal(merged.length, 2);
  assert.equal(merged.find((pr) => pr.number === 1)?.blocker_kind, 'remedial_branch');
}

{
  const pr = {
    number: 42,
    url: 'https://github.com/example/pr/42',
    headRefName: 'cursor/preuat-fix-deadbeef-6bba',
    updatedAt: '2026-08-23T00:00:00Z',
  };
  const result = evaluatePreflight({
    remedialPrs: [pr],
    busyIssues: [],
    join: true,
    force: false,
    remedialBranch: 'cursor/preuat-fix-deadbeef-6bba',
  });
  assert.equal(result.safe_to_start, true);
  assert.equal(result.reason, 'join_existing_remedial_pr');
}

{
  const issue = {
    number: 99,
    url: 'https://github.com/example/issues/99',
    title: '[e2e-debug] pre-UAT remedial',
    updatedAt: '2026-08-23T00:00:00Z',
  };
  const result = evaluatePreflight({
    remedialPrs: [],
    busyIssues: [issue],
    join: false,
    force: false,
    remedialBranch: null,
  });
  assert.equal(result.safe_to_start, false);
  assert.equal(result.reason, 'e2e_debug_in_progress');
}

{
  const issue = {
    number: 99,
    url: 'https://github.com/example/issues/99',
    title: '[e2e-debug] pre-UAT remedial',
    updatedAt: '2026-08-23T00:00:00Z',
  };
  const result = evaluatePreflight({
    remedialPrs: [],
    busyIssues: [issue],
    join: false,
    force: true,
    remedialBranch: null,
  });
  assert.equal(result.safe_to_start, true);
  assert.equal(result.reason, 'clear');
}

{
  assert.equal(
    issueMatchesE2eDebugSession({ labels: [{ name: 'e2e-debug' }], title: '[execute-plan] foo' }),
    true,
  );
  assert.equal(
    issueMatchesE2eDebugSession({ labels: [{ name: 'busy' }], title: '[execute-plan] foo' }, true),
    true,
  );
  assert.equal(
    issueMatchesE2eDebugSession({ labels: [{ name: 'busy' }], title: '[execute-plan] foo' }, false),
    false,
  );
  assert.equal(SESSION_START_MARKER, '/e2e-debug session start');
}

console.log('e2e_debug_status tests passed');
