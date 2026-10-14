'use strict';

const { buildSafetyConstraints } = require('../../.github/scripts/agent-safety-lib');

const SKILL_PATH = '.cursor/skills/dependabot-batch/SKILL.md';
const REQUIRED_MODEL = 'composer-2.5';

/**
 * Structured payload for weekly dependabot-batch Cloud Agent dispatch.
 * @param {{ repository: string, dispatchedAt?: string, trigger?: string }} context
 */
function buildDependabotBatchPayload(context) {
  const dispatchedAt = context.dispatchedAt || new Date().toISOString();
  const dateSlug = dispatchedAt.slice(0, 10);
  const safety = buildSafetyConstraints();

  return {
    task: 'dependabot-batch',
    skill: SKILL_PATH,
    trigger: context.trigger || 'schedule',
    repository: context.repository,
    dispatched_at: dispatchedAt,
    constraints: {
      ...safety,
      model: REQUIRED_MODEL,
      baseBranch: 'main',
      suggestedBranch: `cursor/deps-batch-${dateSlug}-6409`,
      branchPrefix: 'cursor/deps-batch-',
    },
    policy: {
      ci_gate_before_dispatch: false,
      note:
        'Inventory may include red CI; classify Drop/Include/Defer per skill — do not skip dispatch waiting for green Dependabot checks.',
    },
    verification: {
      commands: ['./scripts/pre-push-changed.sh', './scripts/pre-push.sh'],
    },
    handoff: {
      onSuccess:
        'Batch PR merged to main, pre-UAT green, superseded Dependabot PRs closed per skill Phase 6.',
      onBlocked: 'Stop with a clear summary; leave Dependabot PRs open unless skill Phase 1 closes Drops.',
    },
  };
}

function buildDependabotBatchPrompt(payload) {
  const lines = [
    '# Weekly dependabot batch',
    '',
    `Read and follow **${payload.skill}** end-to-end (all phases).`,
    '',
    '## Dispatch policy',
    '',
    '- **No pre-dispatch CI gate** — open Dependabot PRs may be red; use Phase 0 classification (Drop / Include / Defer).',
    `- **Model:** \`${payload.constraints.model}\` only.`,
    `- **Base branch:** \`${payload.constraints.baseBranch}\``,
    `- **Suggested batch branch:** \`${payload.constraints.suggestedBranch}\``,
    '',
    '## Required flow',
    '',
    '1. Phase 0–1: inventory and close Drop PRs (with `dependabot.yml` ignore when needed).',
    '2. Phase 2: assemble one batch branch and open PR to `main`.',
    '3. Phase 3–5: `/babysit-plus` PR CI, mandatory preventive E2E (Phase 4), `/babysit-uat` merge + pre-UAT watch.',
    '4. Phase 6: close superseded Dependabot PRs after batch merge.',
    '',
    'If there are zero open Dependabot PRs to batch, comment in your final message and stop without opening an empty deps PR.',
    '',
    '## Sanitized payload',
    '',
    '```json',
    JSON.stringify(payload, null, 2),
    '```',
    '',
  ];

  return lines.join('\n');
}

module.exports = {
  SKILL_PATH,
  REQUIRED_MODEL,
  buildDependabotBatchPayload,
  buildDependabotBatchPrompt,
};
