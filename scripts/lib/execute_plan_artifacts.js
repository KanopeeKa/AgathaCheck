'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const {
  AUTONOMY,
  ExecutePlanError,
  PHASE_STATUS,
  STATUS_REASON,
} = require('./execute_plan_constants');
const {
  REPO_ROOT,
  atomicWriteFile,
  getPhase,
  loadSnapshot,
  planPaths,
} = require('./execute_plan_schema');
const {
  assertRoadmapCanComplete,
  computeRoadmapNextAction,
  isRoadmap,
  roadmapStatus,
} = require('./execute_plan_roadmap');

const RUNTIME_BLOCK_RE = /```yaml\r?\n([\s\S]*?)\r?\n```/;

function findCurrentPhase(snapshot) {
  return (
    snapshot.phases.find((p) => p.status === 'in_progress') ||
    snapshot.phases.find((p) => p.status === 'blocked') ||
    snapshot.phases.find((p) => p.status === 'halted') ||
    null
  );
}

function findNextPendingPhase(snapshot) {
  return snapshot.phases.find((p) => p.status === 'pending') || null;
}

function effectiveMergeMode(snapshot, phase) {
  return phase.merge_mode || snapshot.default_merge_mode;
}

function parseRuntimeBlock(markdown) {
  const match = markdown.match(RUNTIME_BLOCK_RE);
  if (!match) return null;
  const state = {};
  let key = null;
  const nested = {};

  for (const line of match[1].split('\n')) {
    if (!line.trim() || line.trim().startsWith('#')) continue;
    const top = line.match(/^([a-z_]+):\s*(.*)$/);
    if (top && !line.startsWith('  ')) {
      key = top[1];
      const val = top[2].trim();
      if (val === '' || val === 'null') {
        state[key] = null;
        nested[key] = {};
      } else if (val === '[]' || val === '{}') {
        state[key] = val === '[]' ? [] : {};
      } else if (val.startsWith('"')) {
        state[key] = JSON.parse(val);
      } else {
        state[key] = val;
      }
      continue;
    }
    const sub = line.match(/^  ([a-z_]+):\s*(.*)$/);
    if (sub && key) {
      const val = sub[2].trim();
      if (!nested[key]) nested[key] = {};
      nested[key][sub[1]] =
        val === 'null' ? null : val.startsWith('"') ? JSON.parse(val) : val;
      state[key] = nested[key];
    }
  }
  return state;
}

function yamlScalar(value) {
  if (value === null || value === undefined) return 'null';
  if (typeof value === 'string') {
    if (/^[a-z0-9_./:+-]+$/i.test(value)) return value;
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
  }
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}

function renderRuntimeBlock(state) {
  const artifact = state.artifact_ref || {};
  return [
    'autonomy: ' + yamlScalar(state.autonomy ?? null),
    'current_phase: ' + yamlScalar(state.current_phase ?? null),
    'last_completed_phase: ' + yamlScalar(state.last_completed_phase ?? null),
    'halt_reason: ' + yamlScalar(state.halt_reason ?? null),
    'next_action: ' + yamlScalar(state.next_action ?? null),
    'artifact_ref:',
    '  branch: ' + yamlScalar(artifact.branch ?? null),
    '  plan_path: ' + yamlScalar(artifact.plan_path ?? null),
    '  plan_commit: ' + yamlScalar(artifact.plan_commit ?? null),
    '  snapshot_path: ' + yamlScalar(artifact.snapshot_path ?? null),
    '  snapshot_commit: ' + yamlScalar(artifact.snapshot_commit ?? null),
    'open_prs: ' + yamlScalar(state.open_prs ?? []),
    'merge_commits: ' + yamlScalar(state.merge_commits ?? {}),
    'debt_issue_refs: ' + yamlScalar(state.debt_issue_refs ?? []),
  ].join('\n');
}

function updatePlanRuntimeBlock(planMdPath, partial) {
  const markdown = fs.readFileSync(planMdPath, 'utf8');
  const existing = parseRuntimeBlock(markdown) || {};
  const merged = {
    ...existing,
    ...partial,
    artifact_ref: {
      ...(existing.artifact_ref || {}),
      ...(partial.artifact_ref || {}),
    },
  };
  const block = '```yaml\n' + renderRuntimeBlock(merged) + '\n```';
  if (!RUNTIME_BLOCK_RE.test(markdown)) {
    throw new ExecutePlanError(`runtime yaml block not found in ${planMdPath}`);
  }
  atomicWriteFile(planMdPath, markdown.replace(RUNTIME_BLOCK_RE, block));
  return merged;
}

function renderControlIssueTitle(planId) {
  return `[execute-plan] ${planId}`;
}

function renderControlIssueBody(snapshot) {
  const rows = snapshot.phases
    .map((p) => {
      const mode = effectiveMergeMode(snapshot, p);
      return `| ${p.id} | ${p.title} | ${mode} | ${p.status} |`;
    })
    .join('\n');
  const childRows =
    isRoadmap(snapshot) && snapshot.child_plans
      ? snapshot.child_plans
          .map((c) => {
            const pr = c.pr_url ? `[link](${c.pr_url})` : '—';
            return `| ${c.plan_id} | ${c.status} | ${pr} |`;
          })
          .join('\n')
      : null;
  const childSection = childRows
    ? [
        '',
        '## Child plans (roadmap)',
        '| plan_id | Status | PR |',
        '|---------|--------|-----|',
        childRows,
      ]
    : [];
  return [
    '## Plan',
    `- **ID:** ${snapshot.plan_id}`,
    `- **Snapshot:** \`.agents/plans/${snapshot.plan_id}.snapshot.json\``,
    `- **Content hash:** ${snapshot.content_hash}`,
    `- **Approved until:** ${snapshot.approved_until} (48h default)`,
    ...(isRoadmap(snapshot) ? [`- **Kind:** roadmap`] : []),
    '',
    '## Phases',
    '| ID | Title | Merge mode | Status |',
    '|----|-------|------------|--------|',
    rows,
    ...childSection,
    '',
    '## Revoke',
    'Add label `autonomous-revoked` (halt only — does not close PRs).',
    '',
    '## Resume',
    `Remove revoke label; comment \`resume-plan ${snapshot.plan_id}\`.`,
    '',
  ].join('\n');
}

function controlIssueLabels(planId) {
  return ['execute-plan', `plan:${planId}`, 'autonomous-approved'];
}

function renderHaltComment(snapshot, { reason, detail }) {
  const phase = findCurrentPhase(snapshot);
  const lines = [
    '## Execute-plan halt',
    '',
    `- **plan_id:** ${snapshot.plan_id}`,
    `- **autonomy:** ${snapshot.autonomy}`,
    `- **reason:** ${reason}`,
  ];
  if (detail) lines.push(`- **detail:** ${detail}`);
  if (phase) {
    lines.push(`- **phase:** ${phase.id} (${phase.title})`);
    if (phase.pr_url) lines.push(`- **pr:** ${phase.pr_url}`);
  }
  lines.push('', 'Resume: remove `autonomous-revoked`, comment `resume-plan ' + snapshot.plan_id + '`.');
  return lines.join('\n');
}

function findUatPausedPhase(snapshot) {
  return snapshot.phases.find(
    (p) => p.status === 'halted' && p.status_reason === 'uat_paused'
  );
}

/** Pause in-progress work for UAT remedial — keeps snapshot autonomy active. */
function setPhasePaused(snapshot, { reason, detail, phaseId }) {
  if (!STATUS_REASON.has(reason)) {
    throw new ExecutePlanError(`invalid pause reason: ${reason}`);
  }
  const target =
    (phaseId && getPhase(snapshot, phaseId)) ||
    snapshot.phases.find((p) => p.status === 'in_progress') ||
    findNextPendingPhase(snapshot);
  if (!target) {
    throw new ExecutePlanError('no in_progress or pending phase to pause');
  }
  target.status = 'halted';
  target.status_reason = reason;
  target.status_detail = detail || null;
  return { snapshot, phase: target };
}

/** Auto-resume after UAT prod-ready green — no human resume-plan required. */
function resumeFromUatPause(snapshot, { phaseId } = {}) {
  const target =
    (phaseId && getPhase(snapshot, phaseId)) ||
    findUatPausedPhase(snapshot);
  if (!target) {
    throw new ExecutePlanError('no phase paused with uat_paused');
  }
  if (target.status_reason !== 'uat_paused') {
    throw new ExecutePlanError(
      `phase ${target.id} is ${target.status_reason}, not uat_paused`
    );
  }
  target.status = 'in_progress';
  target.status_reason = null;
  target.status_detail = null;
  return { snapshot, phase: target };
}

function renderPauseComment(snapshot, { reason, detail }) {
  const phase = findCurrentPhase(snapshot);
  const lines = [
    '## Execute-plan pause (UAT remedial)',
    '',
    `- **plan_id:** ${snapshot.plan_id}`,
    `- **reason:** ${reason}`,
  ];
  if (detail) lines.push(`- **detail:** ${detail}`);
  if (phase) {
    lines.push(`- **phase:** ${phase.id} (${phase.title})`);
    if (phase.pr_url) lines.push(`- **pr:** ${phase.pr_url}`);
  }
  lines.push(
    '',
    'Main work is paused at the next safe checkpoint. The UAT babysit sub-agent owns remedial work.',
    '**Auto-resume:** when prod-ready is green, the sub-agent calls `resume-uat` — no manual `resume-plan` needed.'
  );
  return lines.join('\n');
}

function renderUatResumeComment(snapshot, { phase }) {
  return [
    '## Execute-plan resume (UAT prod-ready green)',
    '',
    `- **plan_id:** ${snapshot.plan_id}`,
    `- **phase:** ${phase.id} (${phase.title})`,
    '',
    'UAT prod-ready passed after remedial work. Main agent may continue from checkpoint.',
  ].join('\n');
}

function normalizeLabels(labels) {
  if (!labels) return [];
  if (Array.isArray(labels)) return labels.map(String);
  return String(labels)
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

function checkAutonomyGate(snapshot, { now = new Date(), labels = [] } = {}) {
  const labelSet = new Set(normalizeLabels(labels));
  if (labelSet.has('autonomous-revoked')) {
    return { ok: false, code: 'revoked', message: 'control issue has autonomous-revoked' };
  }
  if (!labelSet.has('autonomous-approved')) {
    return {
      ok: false,
      code: 'not_approved',
      message: 'control issue missing autonomous-approved label',
    };
  }
  if (snapshot.autonomy === 'revoked' || snapshot.autonomy === 'halted') {
    return {
      ok: false,
      code: snapshot.autonomy,
      message: `snapshot autonomy is ${snapshot.autonomy}`,
    };
  }
  if (snapshot.autonomy === 'completed') {
    return { ok: false, code: 'completed', message: 'plan already completed' };
  }
  if (snapshot.autonomy !== 'active') {
    return { ok: false, code: 'inactive', message: `snapshot autonomy is ${snapshot.autonomy}` };
  }
  if (new Date(snapshot.approved_until) <= now) {
    return {
      ok: false,
      code: 'expired',
      message: `approved_until ${snapshot.approved_until} is in the past`,
    };
  }
  return { ok: true };
}

function checkResume(snapshot, phaseId, options = {}) {
  const gate = checkAutonomyGate(snapshot, options);
  if (!gate.ok) return { ok: false, code: gate.code, message: gate.message };

  const phase = getPhase(snapshot, phaseId);
  if (phase.status === 'merged') {
    return { ok: false, code: 'phase_merged', message: `phase ${phaseId} already merged` };
  }

  const { prHeadOid, acceptHead = false } = options;
  if (
    phase.pr_head_sha &&
    prHeadOid &&
    phase.pr_head_sha !== prHeadOid &&
    !acceptHead
  ) {
    return {
      ok: false,
      code: 'resume_mismatch',
      message: `PR head ${prHeadOid} != recorded ${phase.pr_head_sha}; comment accept-head to override`,
    };
  }
  return { ok: true, phase };
}

function computeNextAction(snapshot) {
  if (isRoadmap(snapshot)) {
    const roadmapAction = computeRoadmapNextAction(snapshot);
    if (roadmapAction) return roadmapAction;
  }
  const blocked = snapshot.phases.find((p) => p.status === 'blocked');
  if (blocked) return `unblock phase ${blocked.id}: ${blocked.status_reason}`;
  const active = findCurrentPhase(snapshot);
  if (active) {
    if (active.status === 'in_progress') {
      return `continue phase ${active.id} on branch ${active.branch}`;
    }
    return `resume phase ${active.id} (${active.status_reason})`;
  }
  const next = findNextPendingPhase(snapshot);
  if (next) return `start phase ${next.id}: checkout ${next.branch}`;
  if (snapshot.phases.every((p) => p.status === 'merged')) return 'plan complete';
  return null;
}

function setAutonomyCompleted(snapshot) {
  if (isRoadmap(snapshot)) {
    assertRoadmapCanComplete(snapshot);
    snapshot.autonomy = 'completed';
    return snapshot;
  }
  const pending = snapshot.phases.filter((p) => p.status !== 'merged');
  if (pending.length > 0) {
    throw new ExecutePlanError(
      `cannot complete plan: phases not merged: ${pending.map((p) => p.id).join(', ')}`
    );
  }
  snapshot.autonomy = 'completed';
  return snapshot;
}

function renderCompletePlanComment(snapshot, planId) {
  const merged = snapshot.phases.filter((p) => p.status === 'merged');
  const rows = merged
    .map((p) => {
      const pr = p.pr_url ? `[link](${p.pr_url})` : '—';
      return `| ${p.id} | ${p.title || '—'} | ${p.branch || '—'} | ${pr} |`;
    })
    .join('\n');
  return `## Plan complete

All ${merged.length} phase(s) merged for **${planId}**.

| Phase | Title | Branch | PR |
|-------|-------|--------|-----|
${rows}

- **autonomy:** completed
- Project status: **Done**
`;
}

function setAutonomyHalted(snapshot, { autonomy, reason, detail, phaseId }) {
  if (!AUTONOMY.has(autonomy) || (autonomy !== 'halted' && autonomy !== 'revoked')) {
    throw new ExecutePlanError('halt autonomy must be halted or revoked');
  }
  if (!STATUS_REASON.has(reason)) {
    throw new ExecutePlanError(`invalid halt reason: ${reason}`);
  }
  snapshot.autonomy = autonomy;
  const target =
    (phaseId && getPhase(snapshot, phaseId)) ||
    findCurrentPhase(snapshot) ||
    findNextPendingPhase(snapshot);
  if (target && target.status === 'in_progress') {
    target.status = 'halted';
    target.status_reason = reason;
    target.status_detail = detail || null;
  }
  return snapshot;
}

function setPhaseStatus(snapshot, phaseId, status, fields = {}) {
  if (!PHASE_STATUS.has(status)) throw new ExecutePlanError(`invalid phase status: ${status}`);
  const phase = getPhase(snapshot, phaseId);
  phase.status = status;
  if (status === 'halted' || status === 'blocked') {
    if (!fields.statusReason || !STATUS_REASON.has(fields.statusReason)) {
      throw new ExecutePlanError(`status_reason required for status=${status}`);
    }
    phase.status_reason = fields.statusReason;
    phase.status_detail = fields.statusDetail ?? null;
  } else {
    phase.status_reason = null;
    phase.status_detail = fields.statusDetail ?? null;
  }
  if ('prUrl' in fields) phase.pr_url = fields.prUrl;
  if ('prHeadSha' in fields) phase.pr_head_sha = fields.prHeadSha;
  if ('mergeCommit' in fields) phase.merge_commit = fields.mergeCommit;
  if (fields.debtIssueRefs) phase.debt_issue_refs = fields.debtIssueRefs;
  return phase;
}

function gitRevParse(ref = 'HEAD') {
  return execSync(`git rev-parse ${ref}`, { cwd: REPO_ROOT, encoding: 'utf8' }).trim();
}

function gitBranchName() {
  return execSync('git rev-parse --abbrev-ref HEAD', {
    cwd: REPO_ROOT,
    encoding: 'utf8',
  }).trim();
}

function buildArtifactRef(planId, overrides = {}) {
  const paths = planPaths(planId);
  return {
    branch: overrides.branch ?? gitBranchName(),
    plan_path: path.relative(REPO_ROOT, paths.planMd),
    plan_commit: overrides.planCommit ?? gitRevParse('HEAD'),
    snapshot_path: path.relative(REPO_ROOT, paths.snapshotJson),
    snapshot_commit: overrides.snapshotCommit ?? gitRevParse('HEAD'),
  };
}

function syncRuntimeState(planId, overrides = {}) {
  const snapshot = loadSnapshot(planId);
  const paths = planPaths(planId);
  const current = findCurrentPhase(snapshot) || findNextPendingPhase(snapshot);
  const lastMerged = [...snapshot.phases].reverse().find((p) => p.status === 'merged');
  const runtime = {
    autonomy: snapshot.autonomy,
    current_phase: current ? current.id : null,
    last_completed_phase: lastMerged ? lastMerged.id : null,
    halt_reason:
      snapshot.autonomy === 'halted' || snapshot.autonomy === 'revoked'
        ? current?.status_reason || snapshot.autonomy
        : null,
    next_action: computeNextAction(snapshot),
    artifact_ref: buildArtifactRef(planId, overrides),
    open_prs: snapshot.phases
      .filter((p) => p.pr_url && p.status !== 'merged')
      .map((p) => p.pr_url),
    merge_commits: Object.fromEntries(
      snapshot.phases.filter((p) => p.merge_commit).map((p) => [p.id, p.merge_commit])
    ),
    debt_issue_refs: [...new Set(snapshot.phases.flatMap((p) => p.debt_issue_refs || []))],
  };
  updatePlanRuntimeBlock(paths.planMd, runtime);
  return runtime;
}

module.exports = {
  buildArtifactRef,
  checkAutonomyGate,
  checkResume,
  computeNextAction,
  controlIssueLabels,
  effectiveMergeMode,
  findCurrentPhase,
  findNextPendingPhase,
  findUatPausedPhase,
  gitBranchName,
  gitRevParse,
  normalizeLabels,
  parseRuntimeBlock,
  renderCompletePlanComment,
  renderControlIssueBody,
  roadmapStatus,
  renderControlIssueTitle,
  renderHaltComment,
  renderPauseComment,
  renderRuntimeBlock,
  renderUatResumeComment,
  resumeFromUatPause,
  setAutonomyCompleted,
  setAutonomyHalted,
  setPhasePaused,
  setPhaseStatus,
  syncRuntimeState,
  updatePlanRuntimeBlock,
};
