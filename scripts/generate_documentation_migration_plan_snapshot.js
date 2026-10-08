#!/usr/bin/env node
'use strict';

/**
 * One-off generator for documentation-migration-514a.snapshot.json
 * Run: node scripts/generate_documentation_migration_plan_snapshot.js
 */

const fs = require('fs');
const path = require('path');
const { computeHash, atomicWriteFile } = require('./lib/execute_plan_lib');

const REPO = path.resolve(__dirname, '..');
const OUT = path.join(REPO, '.agents/plans/documentation-migration-514a.snapshot.json');

const INTEGRATION = 'cursor/documentation-migration-wave13-integration-514a';

const DOC_PHASE_PATHS = [
  'docs/**',
  'scripts/docs-legacy-baseline.json',
  'scripts/docs-memory-backlog.json',
  '.agents/memory/**',
  '.agents/plans/documentation-migration-514a.md',
  '.agents/plans/documentation-migration-514a.snapshot.json',
  'docs/architecture/**',
  '.cursor/**',
  'AGENTS.md',
  'e2e/**',
];

const FORBIDDEN = ['server/**', 'flutter_app/**', '.github/workflows/**'];
const EXCEPTIONS = ['docs', 'governance-allowlist', 'tests'];

function phase(id, title, branch, extraAllowed = [], status = 'pending', extras = {}) {
  return {
    id,
    title,
    branch,
    allowed_paths: [...new Set([...DOC_PHASE_PATHS, ...extraAllowed])],
    forbidden_paths: FORBIDDEN,
    allowed_exceptions: EXCEPTIONS,
    spawn_allowed: false,
    spawn_config: null,
    merge_mode: 'auto',
    merge_method: 'squash',
    exit_checklist: 'default',
    status,
    status_reason: status === 'skipped' ? 'po_frozen_domain' : null,
    status_detail: extras.status_detail ?? null,
    debt_issue_refs: [],
    pr_url: extras.pr_url ?? null,
    pr_head_sha: extras.pr_head_sha ?? null,
  };
}

const merged = [
  ['1', 'Phase A — docs gate warn on integration', 'cursor/documentation-migration-gate-warn-514a', {
    pr_url: 'https://github.com/KanopeeKa/AgathaCheck/pull/1768',
    pr_head_sha: '37024b8114ddd57e4a4666c20ee6eb953758e039',
  }],
  ['2', 'Wave 1.1 — care-schedule-management', 'cursor/documentation-migration-csm-514a', {}],
  ['3', 'Wave 1.2 — care-item', 'cursor/documentation-migration-care-item-514a', {
    pr_url: 'https://github.com/KanopeeKa/AgathaCheck/pull/1775',
    pr_head_sha: '6af0b467926ee98f5983c661add8794905a49561',
  }],
  ['4', 'Phase B — restore docs gate block + stragglers', 'cursor/documentation-migration-integration-harden-514a', {}],
  ['5', 'Batch merge integration → main (Wave 1.1–1.2)', 'cursor/documentation-migration-integration-main-514a', {
    pr_url: 'https://github.com/KanopeeKa/AgathaCheck/pull/1780',
    pr_head_sha: '7d5a5229f031747d8ef71983293d9861b39edfcf',
  }],
  ['6', 'Wave 1.3a — care-context', 'cursor/documentation-migration-care-context-514a', {
    pr_url: 'https://github.com/KanopeeKa/AgathaCheck/pull/1782',
    pr_head_sha: 'c0331308bd1f1ef17e1db404a3408c91fe34657a',
  }],
  ['7', 'Wave 1.3b — away-planning-carer-model', 'cursor/documentation-migration-carer-model-514a', {
    pr_url: 'https://github.com/KanopeeKa/AgathaCheck/pull/1784',
    pr_head_sha: '7beb2e2aa8463c5983585a6486b2c0c46a6758a5',
  }],
];

const pending = [
  ['8', 'Wave 1.4a — care-progression', 'cursor/documentation-migration-care-progression-514a', ['docs/domains/pet_care/**'], {}],
  ['9', 'Wave 1.4b — care-intelligence', 'cursor/documentation-migration-care-intelligence-514a', ['docs/domains/pet_care/**'], {}],
  ['10', 'Wave 1.5 — pet_care domain index', 'cursor/documentation-migration-pet-care-index-514a', ['docs/domains/pet_care/**'], {}],
  ['11', 'Wave 2.1 — people-care-team + vocabulary', 'cursor/documentation-migration-people-514a', ['docs/domains/people/**'], {}],
  ['12', 'Wave 2.2 — notifications', 'cursor/documentation-migration-notifications-514a', ['docs/domains/notifications/**'], {}],
  ['13', 'Wave 2.3 — weight tracking', 'cursor/documentation-migration-weight-514a', ['docs/domains/weight_tracking/**'], {}],
  ['14', 'Wave 3.1 — pet profile cluster', 'cursor/documentation-migration-pet-profile-514a', ['docs/domains/pet_profile/**', 'docs/architecture/pet-activity-model.md'], {}],
  ['15', 'Wave 3.2 — guardian dashboard / today', 'cursor/documentation-migration-guardian-today-514a', ['docs/domains/pet_profile/**'], {}],
  ['16', 'Wave 3.3 — navigation shell', 'cursor/documentation-migration-navigation-514a', ['docs/domains/navigation/**'], {}],
  ['17', 'Wave 3.4 — health_tracking remainder', 'cursor/documentation-migration-health-tracking-514a', ['docs/domains/health_tracking/**'], {}],
  ['18', 'Wave 4 — auth', 'cursor/documentation-migration-auth-514a', ['docs/domains/auth/**'], {}],
  ['19', 'Wave 4 — sharing', 'cursor/documentation-migration-sharing-514a', ['docs/domains/sharing/**'], {}],
  ['20', 'Wave 4 — subscription', 'cursor/documentation-migration-subscription-514a', ['docs/domains/subscription/**'], {}],
  ['21', 'Wave 4 — help_about', 'cursor/documentation-migration-help-about-514a', ['docs/domains/help_about/**'], {}],
  ['22', 'Wave 4 — vet (PO: separate vs People)', 'cursor/documentation-migration-vet-514a', ['docs/domains/vet/**', 'docs/domains/people/**'], {}],
  ['23', 'Wave 5.1 — cross-domain changes', 'cursor/documentation-migration-cross-domain-514a', ['docs/domains/cross-domain/**', 'docs/design/terminology.md'], {}],
  ['24', 'Wave 5.2 — root indexes and debt stubs', 'cursor/documentation-migration-indexes-514a', ['docs/README.md', 'docs/debt/**', 'CONTRIBUTING.md'], {}],
  ['25', 'Wave 5.3 — memory → terminology', 'cursor/documentation-migration-memory-514a', ['.agents/memory/**', 'docs/design/terminology.md'], {}],
  [
    '26',
    'Final — integration → main (/babysit-uat)',
    INTEGRATION,
    ['docs/**', 'scripts/docs-legacy-baseline.json', 'scripts/docs-memory-backlog.json', '.agents/plans/documentation-migration-514a.md', '.agents/plans/documentation-migration-514a.snapshot.json'],
    {
      status_detail: 'Open PR integration → main; ./scripts/pre-push.sh; /babysit-uat on merge SHA',
    },
  ],
];

const phases = [
  ...merged.map(([id, title, branch, ex]) => phase(id, title, branch, [], 'merged', ex)),
  ...pending.map(([id, title, branch, allowed, ex]) => phase(id, title, branch, allowed, 'pending', ex)),
];

const snapshot = {
  schema_version: 1,
  plan_id: 'documentation-migration-514a',
  programme_ref: 'docs/domains/documentation/changes/documentation-migration-handover.md',
  approved_at: '2026-10-08T09:00:00Z',
  approved_by: 'Pending — comment approve-autonomous documentation-migration-514a on control issue',
  approved_until: '2026-10-10T09:00:00Z',
  autonomy: 'halted',
  default_merge_mode: 'auto',
  base_branch: INTEGRATION,
  control_issue: 1787,
  artifact_branch_policy: 'phase-branch',
  phases,
};

snapshot.content_hash = computeHash(snapshot);
atomicWriteFile(OUT, `${JSON.stringify(snapshot, null, 2)}\n`);
console.log(`Wrote ${OUT}`);
