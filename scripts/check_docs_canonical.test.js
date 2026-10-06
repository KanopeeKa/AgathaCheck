'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const REPO_ROOT = path.resolve(__dirname, '..');
const SCRIPT = path.join(__dirname, 'check_docs_canonical.js');
const FIXTURES = path.join(__dirname, 'test/fixtures/docs-canonical');

function copyChecker(root) {
  fs.mkdirSync(path.join(root, 'scripts/lib'), { recursive: true });
  fs.cpSync(path.join(__dirname, 'lib/docs-canonical'), path.join(root, 'scripts/lib/docs-canonical'), {
    recursive: true,
  });
  fs.copyFileSync(SCRIPT, path.join(root, 'scripts/check_docs_canonical.js'));
  fs.mkdirSync(path.join(root, 'server/node_modules'), { recursive: true });
  fs.cpSync(
    path.join(REPO_ROOT, 'server/node_modules/js-yaml'),
    path.join(root, 'server/node_modules/js-yaml'),
    { recursive: true },
  );
  const baseline = {
    version: 1,
    features: [],
    changes: [],
  };
  fs.writeFileSync(
    path.join(root, 'scripts/docs-legacy-baseline.json'),
    JSON.stringify(baseline, null, 2),
  );
}

function git(repo, args) {
  const res = spawnSync('git', args, { cwd: repo, encoding: 'utf8' });
  if (res.status !== 0) {
    throw new Error(`git ${args.join(' ')}: ${res.stderr}`);
  }
  return (res.stdout || '').trim();
}

function initRepo(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'docs-canonical-'));
  copyChecker(root);
  for (const [rel, content] of Object.entries(files)) {
    const full = path.join(root, rel);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, content);
  }
  git(root, ['init', '-b', 'main']);
  git(root, ['config', 'user.email', 'test@test.com']);
  git(root, ['config', 'user.name', 'test']);
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'base']);
  return root;
}

function run(root, extraEnv = {}, args = []) {
  const res = spawnSync(process.execPath, [path.join(root, 'scripts/check_docs_canonical.js'), ...args], {
    cwd: root,
    encoding: 'utf8',
    env: { ...process.env, ...extraEnv },
  });
  return { code: res.status, out: `${res.stdout}${res.stderr}` };
}

function featureDoc(domain, name, bodyExtra = '') {
  return `---
title: Test
domain: ${domain}
feature_id: test_feature
status: active
related_prs: []
related_bdd: []
last_updated: 2026-10-06
---

# Test

## Requirements

| ID | Rule | Status |
|----|------|--------|
| TEST-FEATURE-R-001 | rule | Live |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| Given x When y Then z | TEST-FEATURE-R-001 | bdd: away_care_planning.feature#Guest can view away plan |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| TEST-FEATURE-D-001 | d | r | Live | 2026-10-06 | #1 |
${bodyExtra}`;
}

test('R-A1 blocks behaviour PR without ## Docs', () => {
  const root = initRepo({
    'server/routes/foo.js': 'module.exports = {};\n',
  });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'server/routes/foo.js'), 'exports.x=1;\n');
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'behaviour']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head, DOCS_PR_BODY: '' }, ['--pr-body']);
  assert.equal(res.code, 1);
  assert.match(res.out, /R-A1/);
});

test('R-A2 passes N/A with reason >= 10 chars', () => {
  const root = initRepo({
    'server/routes/foo.js': 'a\n',
  });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'server/routes/foo.js'), 'b\n');
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'behaviour']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const body = '## Docs\n\nN/A — refactor, no contract change\n';
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head, DOCS_PR_BODY: body }, ['--pr-body']);
  assert.equal(res.code, 0);
});

test('R-A3 fails when listed doc not in diff', () => {
  const root = initRepo({
    'server/routes/foo.js': 'a\n',
    'docs/domains/pet_care/features/care-item-evolution.md': '# x\n',
  });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'server/routes/foo.js'), 'b\n');
  git(root, ['add', 'server/routes/foo.js']);
  git(root, ['commit', '-m', 'behaviour']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const body =
    '## Docs\n\ndocs/domains/pet_care/features/care-item-evolution.md\n';
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head, DOCS_PR_BODY: body }, ['--pr-body']);
  assert.equal(res.code, 1);
  assert.match(res.out, /R-A3/);
});

test('behaviour exclusions: flutter_app/test only does not require ## Docs', () => {
  const root = initRepo({
    'flutter_app/test/widget_test.dart': 'void main() {}\n',
  });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'flutter_app/test/widget_test.dart'), 'void main() { assert(true); }\n');
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'test only']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--pr-body']);
  assert.equal(res.code, 0);
  assert.doesNotMatch(res.out, /R-A1/);
});

test('bot author exemption for R-A1', () => {
  const root = initRepo({ 'server/routes/foo.js': 'a\n' });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'server/routes/foo.js'), 'b\n');
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'behaviour']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(
    root,
    { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head, DOCS_PR_AUTHOR: 'dependabot[bot]' },
    ['--pr-body'],
  );
  assert.equal(res.code, 0);
});

test('DOCS_GATE_MODE=warn exits 0 on R-A1', () => {
  const root = initRepo({ 'server/routes/foo.js': 'a\n' });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'server/routes/foo.js'), 'b\n');
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'behaviour']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(
    root,
    { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head, DOCS_GATE_MODE: 'warn' },
    ['--pr-body'],
  );
  assert.equal(res.code, 0);
  assert.match(res.out, /R-A1/);
});

test('R-B1 blocks new change doc with status completed', () => {
  const root = initRepo({});
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.mkdirSync(path.join(root, 'docs/domains/pet_care/changes'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs/domains/pet_care/changes/new.md'),
    `---
title: x
status: completed
---
# x\n`,
  );
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'change']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--changes']);
  assert.equal(res.code, 1);
  assert.match(res.out, /R-B1/);
});

test('R-B4 blocks new *-decisions.md in changes/', () => {
  const root = initRepo({});
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.mkdirSync(path.join(root, 'docs/domains/pet_care/changes'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs/domains/pet_care/changes/foo-decisions.md'),
    `---
title: x
status: proposed
---
# x\n`,
  );
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'change']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--changes']);
  assert.match(res.out, /R-B4/);
});

test('R-C1 blocks new feature doc without decision log', () => {
  const root = initRepo({});
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.mkdirSync(path.join(root, 'docs/domains/documentation/features'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs/domains/documentation/features/new-cap.md'),
    `---
title: x
domain: documentation
feature_id: new_cap
---
# x

## Requirements

| ID | Rule | Status |
|----|------|--------|
| NEW-CAP-R-001 | r | Live |
`,
  );
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'doc']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--shape']);
  assert.match(res.out, /R-C1/);
});

test('R-C3 blocks wrong requirement prefix', () => {
  const root = initRepo({});
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.mkdirSync(path.join(root, 'docs/domains/people/features'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs/domains/people/features/people-care-team.md'),
    `---
title: x
domain: people
feature_id: people_care_team
---
# x

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-TEAM-R-001 | bad prefix | Live |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| PEOPLE-CARE-TEAM-D-001 | d | r | Live | 2026-10-06 | #1 |
`,
  );
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'doc']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--shape']);
  assert.match(res.out, /R-C3/);
});

test('R-C6 fixtures: phase shipped, phasing h2, amendment banner block', () => {
  for (const name of ['r-c6-phase-shipped.md', 'r-c6-phasing-h2.md', 'r-c6-amendment-banner.md']) {
    const root = initRepo({});
    const base = git(root, ['rev-parse', 'HEAD']);
    const rel = 'docs/domains/documentation/features/fixture.md';
    fs.mkdirSync(path.dirname(path.join(root, rel)), { recursive: true });
    fs.copyFileSync(path.join(FIXTURES, name), path.join(root, rel));
    git(root, ['add', '-A']);
    git(root, ['commit', '-m', 'doc']);
    const head = git(root, ['rev-parse', 'HEAD']);
    const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--shape']);
    assert.match(res.out, /R-C6/);
  }
});

test('R-C6 fixture: In delivery requirement is not flagged', () => {
  const root = initRepo({});
  const base = git(root, ['rev-parse', 'HEAD']);
  const rel = 'docs/domains/documentation/features/fixture.md';
  fs.mkdirSync(path.dirname(path.join(root, rel)), { recursive: true });
  fs.copyFileSync(path.join(FIXTURES, 'r-c6-in-delivery.md'), path.join(root, rel));
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'doc']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--shape']);
  assert.doesNotMatch(res.out, /R-C6/);
});

test('R-D1 blocks removed requirement row', () => {
  const root = initRepo({
    'docs/domains/documentation/features/x.md': featureDoc('documentation'),
  });
  const baseline = JSON.parse(
    fs.readFileSync(path.join(root, 'scripts/docs-legacy-baseline.json'), 'utf8'),
  );
  baseline.features.push('docs/domains/documentation/features/x.md');
  fs.writeFileSync(path.join(root, 'scripts/docs-legacy-baseline.json'), JSON.stringify(baseline));
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'baseline']);
  const base = git(root, ['rev-parse', 'HEAD']);
  const doc = featureDoc('documentation').replace('TEST-FEATURE-R-001', 'TEST-FEATURE-R-002');
  fs.writeFileSync(path.join(root, 'docs/domains/documentation/features/x.md'), doc.replace('| TEST-FEATURE-R-002 |', '| TEST-FEATURE-R-001 |\n').replace('TEST-FEATURE-R-001', 'TEST-FEATURE-R-002'));
  // simpler: remove row
  const without = featureDoc('documentation').replace(/\| TEST-FEATURE-R-001 \| rule \| Live \|\n/, '');
  fs.writeFileSync(path.join(root, 'docs/domains/documentation/features/x.md'), without);
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'edit']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--ids']);
  assert.match(res.out, /R-D1/);
});

test('R-T2 blocks new TBD coverage', () => {
  const good = featureDoc('documentation');
  const root = initRepo({
    'docs/domains/documentation/features/x.md': good,
  });
  const base = git(root, ['rev-parse', 'HEAD']);
  const bad = good.replace(
    'bdd: away_care_planning.feature#Guest can view away plan',
    'TBD — consolidate',
  );
  fs.writeFileSync(path.join(root, 'docs/domains/documentation/features/x.md'), bad);
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'ac']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const res = run(root, { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head }, ['--trace']);
  assert.match(res.out, /R-T2/);
});

test('--report --json emits valid JSON', () => {
  const res = spawnSync(process.execPath, [SCRIPT, '--report', '--json'], {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  });
  assert.equal(res.status, 0);
  const data = JSON.parse(res.stdout);
  assert.ok(data.domains);
  assert.ok(data.totals);
});

test('--pr-body --body-file matches env body', () => {
  const root = initRepo({ 'server/routes/foo.js': 'a\n' });
  const base = git(root, ['rev-parse', 'HEAD']);
  fs.writeFileSync(path.join(root, 'server/routes/foo.js'), 'b\n');
  git(root, ['add', '-A']);
  git(root, ['commit', '-m', 'behaviour']);
  const head = git(root, ['rev-parse', 'HEAD']);
  const bodyFile = path.join(root, 'body.md');
  fs.writeFileSync(bodyFile, '## Docs\n\nN/A — refactor, no contract change\n');
  const res = run(
    root,
    { DOCS_BASE_SHA: base, DOCS_HEAD_SHA: head },
    ['--pr-body', '--body-file', bodyFile],
  );
  assert.equal(res.code, 0);
});
