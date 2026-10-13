'use strict';

/** Gate I — agent instruction files (docs/agent-efficiency/agent-instructions.md). */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const SCRIPT = path.join(__dirname, 'check_docs_canonical.js');

const AGENTS = '# AGENTS\n\n- **Forbidden closers** while in-loop: "next session", "let me know".\n';

function commitAll(root, msg) {
  spawnSync('git', ['add', '-A'], { cwd: root });
  spawnSync('git', ['commit', '-q', '-m', msg], { cwd: root });
}

function initRepo(files, baseFiles = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'instr-gate-'));
  spawnSync('git', ['init', '-q'], { cwd: root });
  spawnSync('git', ['config', 'user.email', 't@test.com'], { cwd: root });
  spawnSync('git', ['config', 'user.name', 'test'], { cwd: root });
  const write = (entries) => {
    for (const [rel, content] of Object.entries(entries)) {
      fs.mkdirSync(path.dirname(path.join(root, rel)), { recursive: true });
      fs.writeFileSync(path.join(root, rel), content);
    }
  };
  write({ 'scripts/.gitkeep': '', 'AGENTS.md': AGENTS, ...baseFiles });
  commitAll(root, 'base');
  const base = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
  write(files);
  commitAll(root, 'changes');
  return { root, base };
}

function run(root, base, args) {
  const res = spawnSync(process.execPath, [SCRIPT, ...args], {
    encoding: 'utf8',
    env: { ...process.env, DOCS_CANONICAL_ROOT: root, DOCS_BASE: base },
  });
  return { code: res.status, out: `${res.stdout}${res.stderr}` };
}

test('R-I2 glob filename and missing applyTo', () => {
  const { root, base } = initRepo({ '.github/instructions/*.instructions.md': 'Review format.\n' });
  const res = run(root, base, ['--instructions']);
  assert.match(res.out, /\[R-I2\] Filename contains glob characters/);
  assert.match(res.out, /\[R-I2\] Missing `applyTo:`/);
  assert.equal(res.code, 0);
});

test('R-I3 Claude rule without paths and with a missing source', () => {
  const { root, base } = initRepo({ '.claude/rules/x.md': 'Read `.cursor/rules/gone.mdc` first.\n' });
  const res = run(root, base, ['--instructions']);
  assert.match(res.out, /\[R-I3\] Missing `paths:`/);
  assert.match(res.out, /\[R-I3\] Points at missing \.cursor\/rules\/gone\.mdc/);
});

test('R-I4 cited path in an entry file must exist', () => {
  const { root, base } = initRepo({
    'CLAUDE.md': 'See `docs/real.md` and `docs/missing.md`; run `bin/start.js` in server.\n',
    'docs/real.md': '# real\n',
  });
  const res = run(root, base, ['--instructions']);
  assert.match(res.out, /\[R-I4\] Cited path does not exist: docs\/missing\.md/);
  assert.doesNotMatch(res.out, /docs\/real\.md|bin\/start\.js/);
});

test('R-I5 closer restated, R-I6 retired terms', () => {
  const { root, base } = initRepo({
    '.cursor/skills/x/SKILL.md': 'Never say "let me know" mid-plan.\nUse composer-2.5 here.\n',
    'replit.md': 'Babysit on composer-2.5.\nBugbot reviews automatically.\nBugbot is retired.\n',
  });
  const res = run(root, base, ['--instructions']);
  assert.match(res.out, /SKILL\.md,line=1.*\[R-I5\].*let me know/);
  assert.doesNotMatch(res.out, /SKILL\.md.*R-I6/);
  assert.match(res.out, /replit\.md,line=1.*\[R-I6\].*composer-2\.5/);
  assert.match(res.out, /replit\.md,line=2.*\[R-I6\].*Bugbot/);
  assert.doesNotMatch(res.out, /replit\.md,line=3/);
});

test('R-I1 budget exceeded', () => {
  const { root, base } = initRepo({ '.github/copilot-instructions.md': `${'word '.repeat(400)}\n` });
  const res = run(root, base, ['--instructions']);
  assert.match(res.out, /\[R-I1\] \.github\/copilot-instructions\.md: 400 words > budget 350/);
});

test('default run skips gate I when no instruction file changed', () => {
  const { root, base } = initRepo(
    { 'src/app.js': 'x\n' },
    { '.github/instructions/*.instructions.md': 'no frontmatter\n' },
  );
  assert.doesNotMatch(run(root, base, []).out, /R-I/);
  const touched = initRepo({ 'replit.md': 'Bugbot reviews.\n' });
  assert.match(run(touched.root, touched.base, []).out, /\[R-I6\]/);
});
