'use strict';

/**
 * Invariants for the babysit skill family: every entry path must require triage,
 * reply, and resolve of all GitHub PR review conversations (reviewThreads) before merge.
 * @module scripts/lib/babysit_skill_family_policy
 */

const fs = require('fs');
const path = require('path');

const POLICY_REL = 'docs/agent-efficiency/autonomous-pr-policy.md';

/** Skills and rules that participate in PR review / merge loops (see policy §Babysit skill family). */
const FAMILY_SKILL_FILES = [
  '.cursor/skills/babysit/SKILL.md',
  '.cursor/skills/babysit-plus/SKILL.md',
  '.cursor/skills/babysit-uat/SKILL.md',
  '.cursor/skills/light-plan/SKILL.md',
  '.cursor/skills/execute-plan/SKILL.md',
  '.cursor/rules/pr-hygiene.mdc',
  '.claude/skills/steward/SKILL.md',
];

const POLICY_SECTION_HEADING = '## Babysit skill family';

/** Canonical policy must name conversations, the gate script, and the resolve-all invariant. */
const POLICY_MARKERS = [
  POLICY_SECTION_HEADING,
  /review conversations/i,
  /babysit_pr_reviews\.js/,
  /resolve.*every|every.*resolved|all review conversations/i,
];

/**
 * Each family file must wire agents to the gate script and explicit resolve-all language.
 * execute-plan workers triage via `wait`; driver / babysit+ run `gate` before merge (policy).
 */
const SKILL_MARKERS = [
  /babysit_pr_reviews\.js/,
  /\bgate\b[^\n]*--pr|gate --pr/i,
  /resolve.*thread|reply.*resolve|Close every thread|reply\+resolve|unresolved thread/i,
];

const SKILL_MARKERS_EXECUTE_PLAN = [
  /babysit_pr_reviews\.js/,
  /§Babysit skill family|§Automatic reviews/,
  /resolve.*thread|reply.*resolve|handle every thread/i,
];

function readRepoFile(root, relPath) {
  const full = path.join(root, relPath);
  if (!fs.existsSync(full)) {
    throw new Error(`missing file: ${relPath}`);
  }
  return fs.readFileSync(full, 'utf8');
}

function assertMarkers(text, markers, label) {
  const missing = [];
  for (const marker of markers) {
    if (typeof marker === 'string') {
      if (!text.includes(marker)) missing.push(`literal:${marker}`);
    } else if (!marker.test(text)) {
      missing.push(`/${marker.source}/i`);
    }
  }
  if (missing.length > 0) {
    throw new Error(`${label}: missing required marker(s): ${missing.join(', ')}`);
  }
}

/**
 * @param {string} [repoRoot]
 * @returns {{ ok: true, filesChecked: number }}
 */
function validateBabysitSkillFamily(repoRoot = path.resolve(__dirname, '../..')) {
  const policyText = readRepoFile(repoRoot, POLICY_REL);
  assertMarkers(policyText, POLICY_MARKERS, POLICY_REL);

  for (const rel of FAMILY_SKILL_FILES) {
    const text = readRepoFile(repoRoot, rel);
    const markers =
      rel === '.cursor/skills/execute-plan/SKILL.md' ? SKILL_MARKERS_EXECUTE_PLAN : SKILL_MARKERS;
    assertMarkers(text, markers, rel);
  }

  return { ok: true, filesChecked: FAMILY_SKILL_FILES.length + 1 };
}

module.exports = {
  POLICY_REL,
  FAMILY_SKILL_FILES,
  POLICY_SECTION_HEADING,
  validateBabysitSkillFamily,
};
