'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { computeApprovalHash } = require('../lib/execute_plan_approval');

const PLANS_DIR = path.join(__dirname, '..', '..', '.agents', 'plans');

test('every on-main snapshot with approval_hash recomputes to its stored hash', () => {
  const files = fs.readdirSync(PLANS_DIR).filter((f) => f.endsWith('.snapshot.json'));
  const pinned = [];
  for (const file of files) {
    const snapshot = JSON.parse(fs.readFileSync(path.join(PLANS_DIR, file), 'utf8'));
    if (!snapshot.approval_hash) continue;
    pinned.push(file);
    assert.equal(
      computeApprovalHash(snapshot),
      snapshot.approval_hash,
      `${file} approval_hash must match canonical input`,
    );
  }
  assert.ok(pinned.length >= 6, `expected at least 6 pinned snapshots, found ${pinned.length}`);
});

test('approved_sensitive_paths allows forbidden migration globs when listed', () => {
  const { evaluateDiff } = require('../lib/execute_plan_scope');
  const snap = {
    plan_id: 'demo-plan-abc1',
    integration_branch: 'cursor/demo-plan-abc1-integration-abcd',
    phases: [{
      id: '1',
      allowed_paths: ['db/migrations/104_*'],
      approved_sensitive_paths: ['db/migrations/104_*'],
      forbidden_paths: [],
      allowed_exceptions: [],
      companions: [],
    }],
  };
  const r = evaluateDiff({
    files: ['db/migrations/104_care.sql'],
    snapshot: snap,
    category: 'phase',
    phaseId: '1',
    ownPlanFilesVerified: false,
    stopped: { stopped: false, reason: null },
    unchangedOnMain: new Set(),
  });
  assert.equal(r.title, 'ok');
});
