#!/usr/bin/env node
/**
 * Tests for e2e_debug_status.mjs
 */
import assert from 'node:assert/strict';
import { evaluatePreflight, isRemedialBranch } from './e2e_debug_status.mjs';

assert.equal(isRemedialBranch('cursor/preuat-fix-abc12345-6bba'), true);
assert.equal(isRemedialBranch('cursor/preuat-fix-14c6c5b6-2600'), false);
assert.equal(isRemedialBranch('cursor/other-branch-6bba'), false);

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

console.log('e2e_debug_status tests passed');
