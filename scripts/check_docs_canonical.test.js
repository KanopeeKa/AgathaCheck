'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const SCRIPT = path.join(__dirname, 'check_docs_canonical.js');
const FIX = path.join(__dirname, 'test/fixtures/docs-canonical');

function run(env, args = []) {
  const res = spawnSync(process.execPath, [SCRIPT, ...args], {
    encoding: 'utf8',
    env: { ...process.env, ...env },
  });
  return { code: res.status, out: `${res.stdout}${res.stderr}` };
}

function initRepo(files, { baseline } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'docs-gate-'));
  fs.mkdirSync(path.join(root, 'scripts'), { recursive: true });
  fs.writeFileSync(path.join(root, '.gitkeep'), '');
  if (baseline) {
    fs.writeFileSync(
      path.join(root, 'scripts/docs-legacy-baseline.json'),
      JSON.stringify(baseline, null, 2),
    );
  }
  spawnSync('git', ['init'], { cwd: root });
  spawnSync('git', ['config', 'user.email', 't@test.com'], { cwd: root });
  spawnSync('git', ['config', 'user.name', 'test'], { cwd: root });
  spawnSync('git', ['add', '-A'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'base'], { cwd: root });
  const base = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  for (const [rel, content] of Object.entries(files)) {
    const full = path.join(root, rel);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, content);
  }
  spawnSync('git', ['add', '-A'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'changes'], { cwd: root });
  return { root, base };
}

test('R-A1 missing Docs section', () => {
  const { root, base } = initRepo({
    'server/routes/x.js': 'module.exports = {};\n',
  });
  fs.writeFileSync(path.join(root, 'empty.md'), '# PR\n');
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: base },
    ['--pr-body', '--body-file', path.join(root, 'empty.md')],
  );
  assert.equal(res.code, 1);
  assert.match(res.out, /R-A1/);
});

test('R-A1 test-only exempt', () => {
  const { root, base } = initRepo({
    'flutter_app/test/foo_test.dart': 'void main() {}\n',
  });
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: base },
    ['--pr-body', '--body-file', '/dev/null'],
  );
  assert.equal(res.code, 0);
  assert.doesNotMatch(res.out, /R-A1/);
});

test('R-A2 reason length', () => {
  const { root, base } = initRepo({ 'server/lib/a.js': 'x\n' });
  const body = '## Docs\n\nN/A — n/a\n';
  fs.writeFileSync(path.join(root, 'body.md'), body);
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: base },
    ['--pr-body', '--body-file', path.join(root, 'body.md')],
  );
  assert.equal(res.code, 1);
  assert.match(res.out, /R-A2/);
});

test('R-A3 multi-doc', () => {
  const { root } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/features/b.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'server/routes/r.js': 'x\n',
  });
  const preTouch = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  fs.appendFileSync(path.join(root, 'docs/domains/x/features/a.md'), '\n');
  spawnSync('git', ['add', 'docs/domains/x/features/a.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'touch a only'], { cwd: root });
  const body = '## Docs\n\ndocs/domains/x/features/a.md\ndocs/domains/x/features/b.md\n';
  fs.writeFileSync(path.join(root, 'body.md'), body);
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: preTouch },
    ['--pr-body', '--body-file', path.join(root, 'body.md')],
  );
  assert.match(res.out, /R-A3/);
});

test('R-A4 fold before delete', () => {
  const change = `---
status: proposed
status_since: 2026-01-01
folds_into: docs/domains/x/features/a.md
---
# change
`;
  const { root } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/changes/c.md': change,
  });
  const preDeleteBase = spawnSync('git', ['rev-parse', 'HEAD'], {
    cwd: root,
    encoding: 'utf8',
  }).stdout.trim();
  fs.unlinkSync(path.join(root, 'docs/domains/x/changes/c.md'));
  spawnSync('git', ['add', '-A'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'delete change'], { cwd: root });
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: preDeleteBase },
    ['--pr-body', '--body-file', '/dev/null'],
  );
  assert.match(res.out, /R-A4/);
});

test('R-A4b delete legacy change requires domain feature touch', () => {
  const change = `---
status: proposed
status_since: 2026-01-01
---
# legacy
`;
  const { root } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/changes/legacy.md': change,
  });
  const preDeleteBase = spawnSync('git', ['rev-parse', 'HEAD'], {
    cwd: root,
    encoding: 'utf8',
  }).stdout.trim();
  fs.unlinkSync(path.join(root, 'docs/domains/x/changes/legacy.md'));
  spawnSync('git', ['add', '-A'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'delete legacy'], { cwd: root });
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: preDeleteBase },
    ['--pr-body', '--body-file', '/dev/null'],
  );
  assert.match(res.out, /R-A4b/);
});

test('R-B1 invalid change status', () => {
  const bad = `---
status: completed
status_since: 2026-01-01
folds_into: docs/domains/x/features/a.md
---
# x
`;
  const { root, base } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/changes/new.md': bad,
  });
  spawnSync('git', ['add', 'docs/domains/x/changes/new.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'add change'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--changes']);
  assert.match(res.out, /R-B1/);
});

test('R-B4 decisions filename', () => {
  const ch = `---
status: proposed
status_since: 2026-01-01
folds_into: docs/domains/x/features/a.md
---
`;
  const { root, base } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/changes/foo-decisions.md': ch,
  });
  spawnSync('git', ['add', 'docs/domains/x/changes/foo-decisions.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'add'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--changes']);
  assert.match(res.out, /R-B4/);
});

test('R-B5 injected clock', () => {
  const ch = `---
status: proposed
status_since: 2020-01-01
folds_into: docs/domains/x/features/a.md
---
`;
  const { root, base } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/changes/stale.md': ch,
  });
  spawnSync('git', ['add', 'docs/domains/x/changes/stale.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'stale'], { cwd: root });
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: base, DOCS_GATE_NOW: '2026-10-06T00:00:00Z' },
    ['--changes'],
  );
  assert.match(res.out, /R-B5/);
});

test('R-C1 missing Decision log', () => {
  const doc = `---
title: T
domain: x
feature_id: x_cap
---
# T
## Requirements
| ID | Rule | Status |
|----|------|--------|
| X-CAP-R-001 | r | Live |
## Acceptance criteria
| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| G | X-CAP-R-001 | none — #1 |
`;
  const { root, base } = initRepo({ 'docs/domains/x/features/bad.md': doc });
  spawnSync('git', ['add', 'docs/domains/x/features/bad.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'bad'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--shape']);
  assert.match(res.out, /R-C1/);
});

test('R-C3 prefix mismatch', () => {
  const doc = fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8').replace(
    'EXAMPLE-CAP-R-001',
    'CARE-TEAM-R-001',
  );
  const { root, base } = initRepo({ 'docs/domains/x/features/bad.md': doc });
  spawnSync('git', ['add', 'docs/domains/x/features/bad.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'bad prefix'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--shape']);
  assert.match(res.out, /R-C3/);
});

test('R-C4 decision status Agreed', () => {
  let doc = fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8');
  doc = doc.replace('| Live | 2026-10-06 |', '| Agreed | 2026-10-06 |');
  const { root, base } = initRepo({ 'docs/domains/x/features/bad.md': doc });
  spawnSync('git', ['add', 'docs/domains/x/features/bad.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'agreed'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--shape']);
  assert.match(res.out, /R-C4/);
});

test('R-C6 phase shipped row', () => {
  const doc = `${fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8')}\n| CSM-7 | Shipped |\n`;
  const { root, base } = initRepo({ 'docs/domains/x/features/noisy.md': doc });
  spawnSync('git', ['add', 'docs/domains/x/features/noisy.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'noise'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--shape']);
  assert.match(res.out, /R-C6/);
});

test('R-D1 retired requirement', () => {
  const baseDoc = fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8');
  const { root } = initRepo({ 'docs/domains/x/features/a.md': baseDoc });
  const baseAfterAdd = spawnSync('git', ['rev-parse', 'HEAD'], {
    cwd: root,
    encoding: 'utf8',
  }).stdout.trim();
  const headDoc = baseDoc.replace('| Live |', '| Retired |');
  fs.writeFileSync(path.join(root, 'docs/domains/x/features/a.md'), headDoc);
  spawnSync('git', ['add', 'docs/domains/x/features/a.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'retire'], { cwd: root });
  const ok = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: baseAfterAdd }, ['--ids']);
  assert.doesNotMatch(ok.out, /R-D1/);
  const stripped = baseDoc.replace('| EXAMPLE-CAP-R-001 | Rule one | Live |\n', '');
  fs.writeFileSync(path.join(root, 'docs/domains/x/features/a.md'), stripped);
  spawnSync('git', ['add', 'docs/domains/x/features/a.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'delete row'], { cwd: root });
  const bad = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: baseAfterAdd }, ['--ids']);
  assert.match(bad.out, /R-D1/);
});

test('R-T1 legacy coverage on touched row', () => {
  const doc = fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8').replace(
    'none — #1',
    '`away.feature` — Scenario: Example scenario',
  );
  const { root, base } = initRepo({ 'docs/domains/x/features/a.md': doc });
  spawnSync('git', ['add', 'docs/domains/x/features/a.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'legacy cov'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--trace']);
  assert.match(res.out, /R-T1/);
});

test('R-T2 TBD on new row', () => {
  const doc = fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8').replace(
    'none — #1',
    'TBD — consolidate',
  );
  const { root, base } = initRepo({ 'docs/domains/x/features/a.md': doc });
  spawnSync('git', ['add', 'docs/domains/x/features/a.md'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'tbd'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--trace']);
  assert.match(res.out, /R-T2/);
});

test('R-L1 baseline add', () => {
  const { root, base } = initRepo(
    { 'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8') },
    { baseline: { features: [], changes: [] } },
  );
  const bl = JSON.parse(fs.readFileSync(path.join(root, 'scripts/docs-legacy-baseline.json'), 'utf8'));
  bl.features.push('docs/domains/x/features/a.md');
  fs.writeFileSync(path.join(root, 'scripts/docs-legacy-baseline.json'), JSON.stringify(bl, null, 2));
  spawnSync('git', ['add', 'scripts/docs-legacy-baseline.json'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'expand baseline'], { cwd: root });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--changes']);
  assert.match(res.out, /R-L1/);
});

test('mode warn exits 0 on BLOCK', () => {
  const { root, base } = initRepo({ 'server/routes/x.js': 'x\n' });
  const res = run(
    {
      DOCS_CANONICAL_ROOT: root,
      DOCS_BASE: base,
      DOCS_GATE_MODE: 'warn',
    },
    ['--pr-body', '--body-file', '/dev/null'],
  );
  assert.equal(res.code, 0);
  assert.match(res.out, /R-A1/);
});

test('diff-scope unrelated stale change doc', () => {
  const stale = `---
status: proposed
status_since: 2020-01-01
folds_into: docs/domains/x/features/a.md
---
`;
  const { root } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
    'docs/domains/x/changes/stale.md': stale,
    'scripts/foo.js': 'x\n',
  });
  const prBase = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  fs.writeFileSync(path.join(root, 'scripts/foo.js'), 'y\n');
  spawnSync('git', ['add', 'scripts/foo.js'], { cwd: root });
  spawnSync('git', ['commit', '-m', 'script only'], { cwd: root });
  const res = run(
    { DOCS_CANONICAL_ROOT: root, DOCS_BASE: prBase, DOCS_GATE_NOW: '2026-10-06' },
    ['--changes'],
  );
  assert.doesNotMatch(res.out, /R-B5/);
});

test('report json', () => {
  const { root, base } = initRepo({
    'docs/domains/x/features/a.md': fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8'),
  });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--report', '--json']);
  assert.equal(res.code, 0);
  assert.match(res.out, /"domains"/);
});

// --- Decision IDs and memory guards ---------------------------------------------

function fixtureDoc() {
  return fs.readFileSync(path.join(FIX, 'minimal-feature.md'), 'utf8');
}

function commitAll(root, message) {
  spawnSync('git', ['add', '-A'], { cwd: root });
  spawnSync('git', ['commit', '-m', message], { cwd: root });
  return spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
}

function withDecisionId(id) {
  return fixtureDoc().replace('| EXAMPLE-CAP-D-001 |', `| ${id} |`);
}

test('R-C7 accepts feature prefix, kept D-XXX-### and registered legacy prefixes', () => {
  for (const id of ['EXAMPLE-CAP-D-002', 'D-CSM-019', 'NAV-D1', 'PEOPLE-D12', 'SHELTER-D31']) {
    const { root, base } = initRepo({ 'docs/domains/x/features/a.md': withDecisionId(id) });
    const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--shape']);
    assert.doesNotMatch(res.out, /R-C7/, id);
  }
});

test('R-C7 rejects unregistered legacy-style and bare decision IDs', () => {
  for (const id of ['FOO-D3', 'D1', 'EXAMPLE-D-001', 'NAVIGATION-D1']) {
    const { root, base } = initRepo({ 'docs/domains/x/features/a.md': withDecisionId(id) });
    const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--shape']);
    assert.match(res.out, /R-C7/, id);
  }
});

test('R-D3 decision ID introduced by a new doc already exists elsewhere', () => {
  const { root } = initRepo({ 'docs/domains/x/features/a.md': fixtureDoc() });
  const base = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  const other = fixtureDoc()
    .replace('feature_id: example_cap', 'feature_id: other_cap')
    .replace('EXAMPLE-CAP-R-001', 'OTHER-CAP-R-001');
  fs.writeFileSync(path.join(root, 'docs/domains/x/features/b.md'), other);
  commitAll(root, 'add b');
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--ids']);
  assert.equal(res.code, 1);
  assert.match(res.out, /R-D3.*Decision ID EXAMPLE-CAP-D-001 already defined/);
  assert.doesNotMatch(res.out, /Requirement ID/);
});

test('R-D3 requirement ID collision is also caught on a new doc', () => {
  const { root } = initRepo({ 'docs/domains/x/features/a.md': fixtureDoc() });
  const base = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  fs.writeFileSync(
    path.join(root, 'docs/domains/x/features/b.md'),
    fixtureDoc().replace('| EXAMPLE-CAP-D-001 |', '| EXAMPLE-CAP-D-009 |'),
  );
  commitAll(root, 'add b');
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--ids']);
  assert.match(res.out, /R-D3.*Requirement ID EXAMPLE-CAP-R-001 already defined/);
});

test('R-D3 not raised for an unrelated edit or a rename that keeps its IDs', () => {
  const { root } = initRepo({ 'docs/domains/x/features/a.md': fixtureDoc() });
  const base = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  fs.mkdirSync(path.join(root, 'docs/domains/y/features'), { recursive: true });
  spawnSync('git', ['mv', 'docs/domains/x/features/a.md', 'docs/domains/y/features/a.md'], {
    cwd: root,
  });
  commitAll(root, 'move');
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--ids']);
  assert.doesNotMatch(res.out, /R-D[123]/);
  assert.equal(res.code, 0);
});

test('R-D3 duplicates are printed (not swallowed) by --report-duplicates', () => {
  const { root, base } = initRepo({
    'docs/domains/x/features/a.md': fixtureDoc(),
    'docs/domains/x/features/b.md': fixtureDoc(),
  });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--ids', '--report-duplicates']);
  assert.equal(res.code, 0);
  assert.match(res.out, /\[R-D3\] Duplicate decision ID EXAMPLE-CAP-D-001/);
  assert.match(res.out, /\[R-D3\] Duplicate requirement ID EXAMPLE-CAP-R-001/);
});

test('R-M1 memory file citing a decision ID warns; plain lessons and MEMORY.md do not', () => {
  const { root, base } = initRepo({
    '.agents/memory/rule.md': 'Every care item has an open occurrence (D-CSM-019).\n',
    '.agents/memory/lesson.md': 'Run flutter pub get before analyze.\n',
    '.agents/memory/MEMORY.md': 'See NAV-D1 and D-CSM-019.\n',
  });
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--memory']);
  assert.equal(res.code, 0, 'R-M1 is a warning, never blocking');
  assert.match(res.out, /\[R-M1\].*D-CSM-019/);
  assert.doesNotMatch(res.out, /lesson\.md/);
  assert.doesNotMatch(res.out, /MEMORY\.md/);
});

test('R-M2 canonical doc gaining a memory source warns; an existing link does not', () => {
  const linked = `${fixtureDoc()}\nSource: .agents/memory/old-rule.md\n`;
  const { root } = initRepo({ 'docs/domains/x/features/a.md': linked });
  const base = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  fs.writeFileSync(
    path.join(root, 'docs/domains/x/features/a.md'),
    `${linked}\nAlso: .agents/memory/new-rule.md\n`,
  );
  commitAll(root, 'link');
  const res = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--memory']);
  assert.equal(res.code, 0);
  assert.match(res.out, /\[R-M2\].*new-rule\.md/);
  assert.doesNotMatch(res.out, /old-rule\.md/);
});

test('R-M3 stale backlog entry warns; R-M4 lists live entries only with --all', () => {
  const backlog = JSON.stringify({
    entries: [
      { file: '.agents/memory/gone.md', capability: 'x/y', target: 'docs/x.md' },
      { file: '.agents/memory/here.md', capability: 'x/z', target: 'docs/z.md' },
    ],
  });
  const { root, base } = initRepo({
    'scripts/docs-memory-backlog.json': backlog,
    '.agents/memory/here.md': 'A product rule.\n',
  });
  const pr = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--memory']);
  assert.match(pr.out, /\[R-M3\].*gone\.md/);
  assert.doesNotMatch(pr.out, /R-M4/);
  const weekly = run({ DOCS_CANONICAL_ROOT: root, DOCS_BASE: base }, ['--memory', '--all']);
  assert.match(weekly.out, /\[R-M4\].*docs\/z\.md/);
  assert.equal(weekly.code, 0);
});
