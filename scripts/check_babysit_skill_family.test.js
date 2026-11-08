#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  validateBabysitSkillFamily,
  FAMILY_SKILL_FILES,
  POLICY_REL,
  RESOLVE_ALL_RE,
  GATE_SCRIPT_RE,
  copyFamilyFixturesToDir,
} = require('./lib/babysit_skill_family_policy');

const REPO_ROOT = path.resolve(__dirname, '..');

function withCopiedRepo(run) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'babysit-family-'));
  try {
    copyFamilyFixturesToDir(tmp, REPO_ROOT);
    return run(tmp);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

test('validateBabysitSkillFamily passes on the live repo', () => {
  const result = validateBabysitSkillFamily(REPO_ROOT);
  assert.equal(result.ok, true);
  assert.equal(result.filesChecked, FAMILY_SKILL_FILES.length + 1);
});

test('RESOLVE_ALL_RE does not match unresolved-thread prose alone', () => {
  assert.equal(RESOLVE_ALL_RE.test('triage every unresolved thread in the output'), false);
  assert.equal(RESOLVE_ALL_RE.test('reply on and **resolve** each thread'), true);
});

test('validateBabysitSkillFamily fails when policy section is removed', () => {
  withCopiedRepo((tmp) => {
    const policyPath = path.join(tmp, POLICY_REL);
    const stripped = fs
      .readFileSync(policyPath, 'utf8')
      .replace(/## Babysit skill family[\s\S]*?(?=\n---\n\n## Proactive base sync)/, '');
    fs.writeFileSync(policyPath, stripped);
    assert.throws(() => validateBabysitSkillFamily(tmp), /missing required marker/);
  });
});

test('validateBabysitSkillFamily fails when babysit-plus drops resolve-all wording', () => {
  withCopiedRepo((tmp) => {
    const skill = '.cursor/skills/babysit-plus/SKILL.md';
    const skillPath = path.join(tmp, skill);
    const text = fs
      .readFileSync(skillPath, 'utf8')
      .split('\n')
      .filter((line) => !RESOLVE_ALL_RE.test(line))
      .join('\n');
    fs.writeFileSync(skillPath, text);
    assert.throws(() => validateBabysitSkillFamily(tmp), new RegExp(skill.replace(/\./g, '\\.')));
  });
});

test('validateBabysitSkillFamily fails when light-plan drops gate script invocation', () => {
  withCopiedRepo((tmp) => {
    const skill = '.cursor/skills/light-plan/SKILL.md';
    const skillPath = path.join(tmp, skill);
    const text = fs
      .readFileSync(skillPath, 'utf8')
      .replace(/node scripts\/babysit_pr_reviews\.js gate --pr <url>/, 'node scripts/babysit_pr_reviews.js collect --pr <url>');
    fs.writeFileSync(skillPath, text);
    assert.throws(() => validateBabysitSkillFamily(tmp), /gate/);
  });
});

test('GATE_SCRIPT_RE requires babysit_pr_reviews.js gate subcommand', () => {
  assert.equal(GATE_SCRIPT_RE.test('babysit_pr_reviews.js gate --pr'), true);
  assert.equal(GATE_SCRIPT_RE.test('gate --pr <url> only'), false);
});
