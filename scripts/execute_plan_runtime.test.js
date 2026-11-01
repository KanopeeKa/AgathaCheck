#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const {
  computeHash,
  validateSnapshot,
  loadSnapshotFromPath,
  REPO_ROOT,
} = require('./lib/execute_plan_lib');
const {
  findNextPendingChild,
  roadmapStatus,
  setRoadmapChildStatus,
  computeRoadmapNextAction,
} = require('./lib/execute_plan_roadmap');
const { normalizeStatusName } = require('./lib/execute_plan_project');

const exampleV2Snapshot = path.join(REPO_ROOT, '.agents/plans/_example.v2.snapshot.json');

const legacyRoadmapSnapshot = () => ({
  schema_version: 1,
  plan_id: 'roadmap-test-plan',
  approved_at: '2026-07-16T21:00:00Z',
  approved_by: 'test',
  approved_until: '2026-07-18T21:00:00Z',
  content_hash: 'sha256:0000000000000000000000000000000000000000000000000000000000000000',
  autonomy: 'active',
  default_merge_mode: 'auto',
  base_branch: 'cursor/roadmap-test-plan-integration-aec1',
  control_issue: 1,
  artifact_branch_policy: 'phase-branch',
  plan_kind: 'roadmap',
  child_plans: [
    { plan_id: 'child-a', status: 'merged', merge_commit: 'aaa' },
    { plan_id: 'child-b', status: 'pending' },
  ],
  current_child_plan_id: null,
  phases: [
    {
      id: '1',
      title: 'Orchestrator',
      branch: 'cursor/roadmap-test-plan-aec1',
      status: 'pending',
      status_reason: null,
      status_detail: null,
      allowed_paths: ['docs/**'],
      forbidden_paths: [],
      allowed_exceptions: ['docs'],
      exit_checklist: ['docs green'],
      spawn_allowed: false,
      spawn_config: null,
      merge_mode: null,
    },
  ],
});

test('normalizeStatusName maps common aliases', () => {
  assert.equal(normalizeStatusName('backlog'), 'Backlog');
  assert.equal(normalizeStatusName('in_progress'), 'In Progress');
  assert.equal(normalizeStatusName('done'), 'Done');
});

test('roadmap snapshots track child plan progression', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.content_hash = computeHash(snapshot);
  validateSnapshot(snapshot);

  let status = roadmapStatus(snapshot);
  assert.equal(status.next_child_plan_id, 'child-b');
  assert.equal(status.complete, false);

  setRoadmapChildStatus(snapshot, 'child-b', 'in_progress');
  assert.equal(snapshot.current_child_plan_id, 'child-b');
  assert.match(computeRoadmapNextAction(snapshot), /continue child plan child-b/);

  setRoadmapChildStatus(snapshot, 'child-b', 'merged', {
    merge_commit: 'bbb',
    pr_url: 'https://github.com/o/r/pull/2',
  });
  status = roadmapStatus(snapshot);
  assert.equal(status.complete, true);
  assert.equal(findNextPendingChild(snapshot), null);
  assert.equal(computeRoadmapNextAction(snapshot), 'roadmap complete');
});

test('v2 example snapshot validates via CLI helper path', () => {
  const snapshot = loadSnapshotFromPath(exampleV2Snapshot);
  assert.equal(snapshot.schema_version, 2);
  assert.ok(snapshot.plan_id);
});
