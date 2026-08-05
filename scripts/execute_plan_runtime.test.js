#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const {
  checkAutonomyGate,
  checkResume,
  computeHash,
  computeNextAction,
  parseRuntimeBlock,
  renderControlIssueBody,
  renderControlIssueTitle,
  renderCompletePlanComment,
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

const exampleSnapshot = path.join(REPO_ROOT, '.agents/plans/_example.snapshot.json');
const examplePlan = path.join(REPO_ROOT, '.agents/plans/_example.md');

test('validateSnapshot accepts example snapshot', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  validateSnapshot(snapshot);
});

test('mutated snapshot fails validation until content_hash is recomputed', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  assert.throws(
    () => validateSnapshot(snapshot, { checkHash: true }),
    /content_hash mismatch/
  );
  snapshot.content_hash = computeHash(snapshot);
  validateSnapshot(snapshot, { checkHash: true });
});

test('renderControlIssueTitle uses plan id', () => {
  assert.equal(renderControlIssueTitle('example-plan'), '[execute-plan] example-plan');
});

test('renderControlIssueBody includes phases table', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  const body = renderControlIssueBody(snapshot);
  assert.match(body, /\| 1 \| Extract FosterCard widgets \| auto \| pending \|/);
  assert.match(body, /example-plan/);
});

test('checkAutonomyGate rejects revoked label', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  const result = checkAutonomyGate(snapshot, {
    labels: ['autonomous-approved', 'autonomous-revoked'],
    now: new Date('2026-07-17T12:00:00Z'),
  });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'revoked');
});

test('checkAutonomyGate rejects expired approval window', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  const result = checkAutonomyGate(snapshot, {
    labels: ['autonomous-approved'],
    now: new Date('2026-07-19T00:00:00Z'),
  });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'expired');
});

test('checkAutonomyGate passes when active and approved', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  const result = checkAutonomyGate(snapshot, {
    labels: ['autonomous-approved'],
    now: new Date('2026-07-17T12:00:00Z'),
  });
  assert.equal(result.ok, true);
});

test('checkResume detects pr head mismatch', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  snapshot.phases[0].status = 'in_progress';
  snapshot.phases[0].pr_head_sha = 'abc123';
  const result = checkResume(snapshot, '1', {
    labels: ['autonomous-approved'],
    prHeadOid: 'def456',
    now: new Date('2026-07-17T12:00:00Z'),
  });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'resume_mismatch');
});

test('checkResume allows mismatch with accept-head', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  snapshot.phases[0].status = 'in_progress';
  snapshot.phases[0].pr_head_sha = 'abc123';
  const result = checkResume(snapshot, '1', {
    labels: ['autonomous-approved'],
    prHeadOid: 'def456',
    acceptHead: true,
    now: new Date('2026-07-17T12:00:00Z'),
  });
  assert.equal(result.ok, true);
});

test('setAutonomyHalted marks in-progress phase halted', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  snapshot.phases[0].status = 'in_progress';
  setAutonomyHalted(snapshot, { autonomy: 'halted', reason: 'session_limit' });
  assert.equal(snapshot.autonomy, 'halted');
  assert.equal(snapshot.phases[0].status, 'halted');
  assert.equal(snapshot.phases[0].status_reason, 'session_limit');
});

test('setPhaseStatus clears status_reason for in_progress', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  setPhaseStatus(snapshot, '1', 'in_progress');
  assert.equal(snapshot.phases[0].status, 'in_progress');
  assert.equal(snapshot.phases[0].status_reason, null);
});

test('setPhasePaused keeps autonomy active and halts in_progress phase', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  snapshot.phases[0].status = 'in_progress';
  setPhasePaused(snapshot, { reason: 'uat_paused', detail: 'smoke failed' });
  assert.equal(snapshot.autonomy, 'active');
  assert.equal(snapshot.phases[0].status, 'halted');
  assert.equal(snapshot.phases[0].status_reason, 'uat_paused');
  assert.equal(snapshot.phases[0].status_detail, 'smoke failed');
});

test('resumeFromUatPause restores in_progress without human resume', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  snapshot.phases[0].status = 'halted';
  snapshot.phases[0].status_reason = 'uat_paused';
  const { phase } = resumeFromUatPause(snapshot);
  assert.equal(phase.status, 'in_progress');
  assert.equal(phase.status_reason, null);
  assert.equal(snapshot.autonomy, 'active');
});

test('computeNextAction suggests start for pending plan', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  assert.match(computeNextAction(snapshot), /start phase 1/);
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
test('renderRuntimeBlock round-trips core fields', () => {
  const state = {
    autonomy: 'active',
    current_phase: '1',
    last_completed_phase: null,
    halt_reason: null,
    next_action: 'start phase 1',
    artifact_ref: {
      branch: 'cursor/example-aec1',
      plan_path: '.agents/plans/example-plan.md',
      plan_commit: 'abc',
      snapshot_path: '.agents/plans/example-plan.snapshot.json',
      snapshot_commit: 'def',
    },
    open_prs: [],
    merge_commits: {},
    debt_issue_refs: [],
  };
  const yaml = renderRuntimeBlock(state);
  assert.match(yaml, /autonomy: active/);
  assert.match(yaml, /current_phase: 1/);
});

test('setAutonomyCompleted requires all phases merged', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.autonomy = 'active';
  assert.throws(() => setAutonomyCompleted(snapshot), /phases not merged/);
  snapshot.phases.forEach((p) => {
    p.status = 'merged';
  });
  setAutonomyCompleted(snapshot);
  assert.equal(snapshot.autonomy, 'completed');
});

test('renderCompletePlanComment summarizes merged phases', () => {
  const snapshot = loadSnapshotFromPath(exampleSnapshot);
  snapshot.phases.forEach((p) => {
    p.status = 'merged';
    p.pr_url = 'https://github.com/o/r/pull/1';
  });
  const body = renderCompletePlanComment(snapshot, 'example-plan');
  assert.match(body, /Plan complete/);
  assert.match(body, /Done/);
  assert.match(body, /example-plan/);
});

test('normalizeStatusName maps common aliases', () => {
  assert.equal(normalizeStatusName('backlog'), 'Backlog');
  assert.equal(normalizeStatusName('in_progress'), 'In Progress');
  assert.equal(normalizeStatusName('done'), 'Done');
  assert.equal(normalizeStatusName('  Ready  '), 'Ready');
  assert.equal(normalizeStatusName(42), '42');
});
