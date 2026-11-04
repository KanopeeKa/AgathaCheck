'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ownPlanFilePaths,
  extraInitBranchFiles,
  pathsFromCompareFiles,
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

test('pathsFromCompareFiles includes previous_filename on renames', () => {
  const planRel = `.agents/plans/${PLAN_ID}.md`;
  assert.deepEqual(
    pathsFromCompareFiles([{ filename: planRel, previous_filename: 'keep.yml' }]),
    [planRel, 'keep.yml'],
  );
});

test('formatInitBranchOnlyPlanFilesMessage names extras to move', () => {
  const planRel = `.agents/plans/${PLAN_ID}.md`;
  const msg = formatInitBranchOnlyPlanFilesMessage({
    planId: PLAN_ID,
    paths: [planRel, 'docs/foo.md'],
  });
  assert.match(msg, /docs\/foo\.md/);
  assert.match(msg, /separate PR against `main`/);
});

test('formatInitBranchOnlyPlanFilesMessage asks for missing snapshot, not separate PR', () => {
  const planRel = `.agents/plans/${PLAN_ID}.md`;
  const snapRel = `.agents/plans/${PLAN_ID}.snapshot.json`;
  const msg = formatInitBranchOnlyPlanFilesMessage({
    planId: PLAN_ID,
    paths: [planRel],
  });
  assert.match(msg, /missing file/);
  assert.match(msg, new RegExp(snapRel.replace(/\./g, '\\.')));
  assert.doesNotMatch(msg, /Move .* separate PR/);
});
