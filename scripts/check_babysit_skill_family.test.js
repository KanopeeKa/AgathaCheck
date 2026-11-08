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
} = require('./lib/babysit_skill_family_policy');

const REPO_ROOT = path.resolve(__dirname, '..');

test('validateBabysitSkillFamily passes on the live repo', () => {
  const result = validateBabysitSkillFamily(REPO_ROOT);
  assert.equal(result.ok, true);
  assert.equal(result.filesChecked, FAMILY_SKILL_FILES.length + 1);
});

test('validateBabysitSkillFamily fails when policy section is removed', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'babysit-family-'));
  try {
    for (const rel of [POLICY_REL, ...FAMILY_SKILL_FILES]) {
      const src = path.join(REPO_ROOT, rel);
      const dest = path.join(tmp, rel);
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(src, dest);
    }
    const policyPath = path.join(tmp, POLICY_REL);
    const stripped = fs
      .readFileSync(policyPath, 'utf8')
      .replace(/## Babysit skill family[\s\S]*?(?=\n## )/, '');
    fs.writeFileSync(policyPath, stripped);
    assert.throws(() => validateBabysitSkillFamily(tmp), /missing required marker/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
