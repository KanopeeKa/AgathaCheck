#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const {
  computeHash,
  computeNextAction,
  parseRuntimeBlock,
  renderControlIssueBody,
  renderControlIssueTitle,
  renderCompletePlanComment,
  renderHaltComment,
  renderRuntimeBlock,
  setAutonomyHalted,
  setAutonomyCompleted,
  setPhasePaused,
  resumeFromUatPause,
  setPhaseStatus,
  validateSnapshot,
  loadSnapshotFromPath,
  REPO_ROOT,
} = require('./lib/execute_plan_lib');
const { normalizeStatusName } = require('./lib/execute_plan_project');

const exampleV2Snapshot = path.join(REPO_ROOT, '.agents/plans/_example.v2.snapshot.json');
const examplePlan = path.join(REPO_ROOT, '.agents/plans/_example.md');

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

test('renderControlIssueTitle uses plan id', () => {
  assert.equal(renderControlIssueTitle('example-plan'), '[execute-plan] example-plan');
});

test('renderHaltComment for expired uses re-approve and resume-plan only', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  const body = renderHaltComment(snapshot, { reason: 'expired', detail: 'grant ended' });
  assert.match(body, /approve-autonomous/);
  assert.match(body, /resume-plan/);
  assert.match(body, /do not re-select phases/i);
});

test('setAutonomyHalted marks in-progress phase halted', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  snapshot.phases[0].status = 'in_progress';
  setAutonomyHalted(snapshot, { autonomy: 'halted', reason: 'session_limit' });
  assert.equal(snapshot.autonomy, 'halted');
  assert.equal(snapshot.phases[0].status, 'halted');
  assert.equal(snapshot.phases[0].status_reason, 'session_limit');
});

test('setPhaseStatus clears status_reason for in_progress', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  setPhaseStatus(snapshot, '1', 'in_progress');
  assert.equal(snapshot.phases[0].status, 'in_progress');
  assert.equal(snapshot.phases[0].status_reason, null);
});

test('setPhasePaused keeps autonomy active and halts in_progress phase', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  snapshot.phases[0].status = 'in_progress';
  setPhasePaused(snapshot, { reason: 'uat_paused', detail: 'smoke failed' });
  assert.equal(snapshot.autonomy, 'active');
  assert.equal(snapshot.phases[0].status, 'halted');
  assert.equal(snapshot.phases[0].status_reason, 'uat_paused');
});

test('resumeFromUatPause restores in_progress without human resume', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  snapshot.phases[0].status = 'halted';
  snapshot.phases[0].status_reason = 'uat_paused';
  const { phase } = resumeFromUatPause(snapshot);
  assert.equal(phase.status, 'in_progress');
  assert.equal(phase.status_reason, null);
  assert.equal(snapshot.autonomy, 'active');
});

test('parseRuntimeBlock reads example plan runtime yaml', () => {
  const markdown = fs.readFileSync(examplePlan, 'utf8');
  const state = parseRuntimeBlock(markdown);
  assert.equal(state.autonomy, 'halted');
  assert.equal(state.current_phase, null);
});

test('renderRuntimeBlock quotes strings with special characters', () => {
  const yaml = renderRuntimeBlock({
    autonomy: 'active',
    current_phase: 'path\\to\\phase',
    last_completed_phase: null,
    halt_reason: 'say "hello"',
    next_action: null,
    artifact_ref: {
      branch: null,
      plan_path: null,
      plan_commit: null,
      snapshot_path: null,
      snapshot_commit: null,
    },
    open_prs: [],
    merge_commits: {},
    debt_issue_refs: [],
  });
  assert.match(yaml, /current_phase: "path\\\\to\\\\phase"/);
  assert.match(yaml, /halt_reason: "say \\"hello\\""/);
});

test('setAutonomyCompleted requires all phases merged', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  snapshot.plan_kind = undefined;
  snapshot.child_plans = undefined;
  snapshot.phases[0].status = 'pending';
  assert.throws(() => setAutonomyCompleted(snapshot), /phases not merged/);
  snapshot.phases.forEach((p) => {
    p.status = 'merged';
  });
  setAutonomyCompleted(snapshot);
  assert.equal(snapshot.autonomy, 'completed');
});

test('renderCompletePlanComment summarizes merged phases', () => {
  const snapshot = legacyRoadmapSnapshot();
  snapshot.plan_id = 'example-plan';
  snapshot.phases.forEach((p) => {
    p.status = 'merged';
    p.pr_url = 'https://github.com/o/r/pull/1';
  });
  const body = renderCompletePlanComment(snapshot, 'example-plan');
  assert.match(body, /Plan complete/);
  assert.match(body, /example-plan/);
});

test('normalizeStatusName maps common aliases', () => {
  assert.equal(normalizeStatusName('backlog'), 'Backlog');
  assert.equal(normalizeStatusName('in_progress'), 'In Progress');
  assert.equal(normalizeStatusName('done'), 'Done');
});

test('roadmap snapshots track child plan progression', () => {
  const {
    findNextPendingChild,
    roadmapStatus,
    setRoadmapChildStatus,
  } = require('./lib/execute_plan_roadmap');
  const snapshot = legacyRoadmapSnapshot();
  snapshot.content_hash = computeHash(snapshot);
  validateSnapshot(snapshot);

  let status = roadmapStatus(snapshot);
  assert.equal(status.next_child_plan_id, 'child-b');
  assert.equal(status.complete, false);

  setRoadmapChildStatus(snapshot, 'child-b', 'in_progress');
  assert.equal(snapshot.current_child_plan_id, 'child-b');
  assert.match(computeNextAction(snapshot), /continue child plan child-b/);

  setRoadmapChildStatus(snapshot, 'child-b', 'merged', {
    merge_commit: 'bbb',
    pr_url: 'https://github.com/o/r/pull/2',
  });
  status = roadmapStatus(snapshot);
  assert.equal(status.complete, true);
  assert.equal(findNextPendingChild(snapshot), null);
  assert.equal(computeNextAction(snapshot), 'roadmap complete');
});

test('v2 example snapshot validates via CLI helper path', () => {
  const snapshot = loadSnapshotFromPath(exampleV2Snapshot);
  assert.equal(snapshot.schema_version, 2);
  assert.ok(snapshot.plan_id);
});
