'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ownPlanFilePaths,
  extraInitBranchFiles,
  formatInitBranchOnlyPlanFilesMessage,
} = require('../lib/execute_plan_own_files');

const PLAN_ID = 'proof-build-label-7f3a';

test('ownPlanFilePaths returns plan md and snapshot json', () => {
  assert.deepEqual(ownPlanFilePaths(PLAN_ID), [
    `.agents/plans/${PLAN_ID}.md`,
    `.agents/plans/${PLAN_ID}.snapshot.json`,
  ]);
});

test('extraInitBranchFiles ignores plan md only', () => {
  const planRel = `.agents/plans/${PLAN_ID}.md`;
  assert.deepEqual(extraInitBranchFiles(PLAN_ID, [planRel]), []);
});

test('formatInitBranchOnlyPlanFilesMessage names extras to move', () => {
  const planRel = `.agents/plans/${PLAN_ID}.md`;
  const msg = formatInitBranchOnlyPlanFilesMessage({
    planId: PLAN_ID,
    files: [planRel, 'docs/foo.md'],
    committedFilenames: [planRel, 'docs/foo.md'],
  });
  assert.match(msg, /docs\/foo\.md/);
  assert.match(msg, /docs PR against `main`/);
});
