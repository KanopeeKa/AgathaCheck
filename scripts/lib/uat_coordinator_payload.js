'use strict';

const { buildSafetyConstraints } = require('../../.github/scripts/agent-safety-lib');
const { parseUatTag } = require('./uat_queue_lib');

// Patterns match the GitHub Actions job `name:` field as it renders in the
// Jobs API (reusable-workflow jobs get a "<caller> / <called>" suffix) —
// verify against a real run's `jobs[].name` (e.g. `gh api .../jobs`) before
// editing; job names have drifted from these patterns before (see
// docs/agent-efficiency/uat-coordinator-plan.md "Infra vs code classification").
const GATE_CLASSIFIERS = [
  { gate: 'localhost_e2e', pattern: /playwright e2e \(localhost|full localhost e2e|e2e shard/i, remedial: 'yes' },
  { gate: 'pre_uat_e2e', pattern: /pre-uat e2e gate|pre-uat-e2e/i, remedial: 'yes' },
  { gate: 'http_smoke', pattern: /(^|\/)smoke\b|http smoke|post-deploy smoke/i, remedial: 'maybe_infra' },
  { gate: 'live_e2e', pattern: /uat-live-e2e|live uat smoke|@smoke-uat|live smoke/i, remedial: 'maybe_infra' },
  { gate: 'flutter_build', pattern: /build-web|flutter build|build flutter web/i, remedial: 'yes' },
  { gate: 'deploy', pattern: /(^|\/)deploy\b|deploy to uat/i, remedial: 'maybe_infra' },
  { gate: 'migrations', pattern: /migrate/i, remedial: 'escalate' },
];

// Aggregate/conclusion jobs that fail as a *symptom* of any other gate failing
// — never a root cause. Excluding them keeps isInfraOnlyFailure() accurate:
// without this, "Prod ready" would always show up as an extra failed job
// (classified 'unknown'/'escalate') and defeat the all-gates-are-infra check
// even when the one real failing gate was infra-only.
const AGGREGATE_JOB_NAMES = new Set(['Prod ready', 'UAT release conclusion']);

function classifyFailedJob(job) {
  const name = job.name || '';
  const match = GATE_CLASSIFIERS.find((row) => row.pattern.test(name));
  return {
    job_name: name,
    job_id: job.id,
    conclusion: job.conclusion,
    gate: match?.gate || 'unknown',
    remedial: match?.remedial || 'investigate',
    html_url: job.html_url,
  };
}

function classifyFailedJobs(jobs) {
  return (jobs || [])
    .filter((job) => job.conclusion === 'failure' && !AGGREGATE_JOB_NAMES.has(job.name))
    .map(classifyFailedJob);
}

function primaryFailedGate(failedGates) {
  const priority = [
    'migrations',
    'pre_uat_e2e',
    'http_smoke',
    'live_e2e',
    'localhost_e2e',
    'flutter_build',
    'deploy',
    'unknown',
  ];
  for (const gate of priority) {
    const hit = failedGates.find((row) => row.gate === gate);
    if (hit) {
      return hit;
    }
  }
  return failedGates[0] || null;
}

function shouldEscalate(primaryGate) {
  if (!primaryGate) {
    return false;
  }
  return primaryGate.remedial === 'escalate' || primaryGate.gate === 'http_smoke';
}

/**
 * True when every failed gate is host/network infra (WAF, SSH transport, deploy
 * transport) with no evidence of a code regression — e.g. localhost E2E or the
 * Flutter build did not fail. Used to keep infra-only deploy failures from
 * freezing promotion for unrelated merges (queueHeadHold only reacts to
 * `failed`/`remedial` entries, not `infra_failed`).
 */
function isInfraOnlyFailure(failedGates) {
  if (!failedGates || failedGates.length === 0) {
    return false;
  }
  return failedGates.every((row) => row.remedial === 'maybe_infra');
}

function buildUatCoordinatorPayload({
  coordinationIssueNumber,
  coordinationIssueUrl,
  entry,
  failedGates,
  workflowRunId,
  workflowUrl,
  repository,
}) {
  const primary = primaryFailedGate(failedGates);
  const parsedTag = entry?.uat_tag ? parseUatTag(entry.uat_tag) : null;
  const prNumber = entry?.pr_number || parsedTag?.prNumber || null;
  const safety = buildSafetyConstraints();

  return {
    role: 'uat-coordinator',
    coordination_issue: {
      number: coordinationIssueNumber,
      url: coordinationIssueUrl,
    },
    failure: {
      deploy_ref: entry?.uat_tag || null,
      merge_sha: entry?.merge_sha || null,
      pr_number: prNumber,
      workflow_run_id: workflowRunId,
      workflow_url: workflowUrl,
      queue_seq: entry?.seq || null,
      gate_summary_ref: entry?.gate_summary_ref || workflowUrl,
    },
    gates: {
      failed: failedGates,
      primary: primary,
      escalate: shouldEscalate(primary),
    },
    triage: {
      playbook: 'docs/agent-efficiency/uat-coordinator-plan.md §4',
      skill: '.cursor/skills/uat-coordinator/SKILL.md',
    },
    constraints: {
      ...safety,
      branchPrefix: 'cursor/uat-fix-',
      suggestedBranch: prNumber ? `cursor/uat-fix-${prNumber}-2b0b` : 'cursor/uat-fix-unknown-2b0b',
      baseBranch: 'main',
      repository,
      forbiddenActions: [
        ...safety.forbiddenActions,
        'weaken UAT gates or skip shards',
        'merge without green PR CI',
      ],
    },
    verification: {
      commands: ['./scripts/pre-push-changed.sh'],
      after_remedial_merge: [
        'node scripts/uat_queue_runtime.js set-barrier --sha <merge_sha> --write',
        'node scripts/uat_queue_runtime.js release-watcher --write',
      ],
    },
    handoff: {
      onCodeFix:
        'Open remedial PR with Refs #<linked-issue> + failed run URL + gate table. Use /babysit-plus merge_mode auto when CI green.',
      onInfra:
        'Comment on coordination issue — escalate per uat-coordinator-plan §9. Do not open code remedial PR for WAF/migration blockers.',
      onDone:
        'Release watcher, clear promote hold after barrier advanced.',
    },
  };
}

function buildUatCoordinatorPrompt(payload) {
  const lines = [
    '# UAT coordinator task',
    '',
    `Read and follow **${payload.triage.skill}** before acting.`,
    '',
    '## Failure context',
    '',
    `- Coordination issue: #${payload.coordination_issue.number}`,
    `- PR: #${payload.failure.pr_number ?? 'unknown'}`,
    `- UAT tag: \`${payload.failure.deploy_ref ?? 'unknown'}\``,
    `- Workflow: ${payload.failure.workflow_url}`,
    '',
    '## Failed gates',
    '',
  ];

  for (const gate of payload.gates.failed) {
    lines.push(`- **${gate.gate}** — ${gate.job_name} (${gate.remedial})`);
  }

  if (payload.gates.primary) {
    lines.push('');
    lines.push(`**Primary gate:** ${payload.gates.primary.gate}`);
  }

  if (payload.gates.escalate) {
    lines.push('');
    lines.push(
      '**Escalate** — likely infra (WAF/migrations). Do not weaken gates or open speculative code PRs.',
    );
  } else {
    lines.push('');
    lines.push(`**Remedial branch:** \`${payload.constraints.suggestedBranch}\``);
  }

  lines.push('');
  lines.push('## Sanitized payload');
  lines.push('');
  lines.push('```json');
  lines.push(JSON.stringify(payload, null, 2));
  lines.push('```');

  return lines.join('\n');
}

module.exports = {
  GATE_CLASSIFIERS,
  classifyFailedJob,
  classifyFailedJobs,
  primaryFailedGate,
  shouldEscalate,
  isInfraOnlyFailure,
  buildUatCoordinatorPayload,
  buildUatCoordinatorPrompt,
};
