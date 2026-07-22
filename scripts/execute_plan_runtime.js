#!/usr/bin/env node
/**
 * Execute-plan control issue + plan artifact runtime.
 *
 * Usage:
 *   node scripts/execute_plan_runtime.js gate <plan_id> [--labels a,b]
 *   node scripts/execute_plan_runtime.js resume-check <plan_id> --phase <id> [--pr-head <sha>] [--labels a,b] [--accept-head]
 *   node scripts/execute_plan_runtime.js halt <plan_id> --reason <status_reason> [--autonomy halted|revoked] [--detail text] [--write]
 *   node scripts/execute_plan_runtime.js pause <plan_id> --reason <status_reason> [--phase <id>] [--detail text] [--write]
 *   node scripts/execute_plan_runtime.js resume-uat <plan_id> [--phase <id>] [--write]
 *   node scripts/execute_plan_runtime.js set-phase <plan_id> --phase <id> --status <status> [--reason r] [--pr-url u] [--pr-head sha] [--write]
 *   node scripts/execute_plan_runtime.js sync-runtime <plan_id> [--branch b] [--write]
 *   node scripts/execute_plan_runtime.js render-control-issue <plan_id> [--title]
 *   node scripts/execute_plan_runtime.js render-halt-comment <plan_id> --reason <status_reason> [--detail text]
 *   node scripts/execute_plan_runtime.js current-phase <plan_id>
 *   node scripts/execute_plan_runtime.js init-control-issue <plan_id>
 *   node scripts/execute_plan_runtime.js set-project-status <plan_id> --status <name> [--issue N]
 *   node scripts/execute_plan_runtime.js complete-plan <plan_id> [--write] [--skip-close]
 */

'use strict';

const {
  checkAutonomyGate,
  checkResume,
  computeNextAction,
  controlIssueLabels,
  findCurrentPhase,
  findNextPendingPhase,
  loadSnapshot,
  renderControlIssueBody,
  renderControlIssueTitle,
  renderHaltComment,
  renderCompletePlanComment,
  renderPauseComment,
  renderUatResumeComment,
  resumeFromUatPause,
  saveSnapshot,
  setAutonomyHalted,
  setAutonomyCompleted,
  setPhasePaused,
  setPhaseStatus,
  syncRuntimeState,
  validateSnapshot,
  ExecutePlanError,
} = require('./lib/execute_plan_lib');
const {
  closeIssueWithComment,
  updateIssueProjectStatus,
} = require('./lib/execute_plan_project');

function usage() {
  console.error(`Usage: node scripts/execute_plan_runtime.js <command> [options]

Commands:
  gate <plan_id> [--labels label1,label2]
  resume-check <plan_id> --phase <id> [--pr-head <sha>] [--labels ...] [--accept-head]
  halt <plan_id> --reason <status_reason> [--autonomy halted|revoked] [--detail text] [--write]
  pause <plan_id> --reason <status_reason> [--phase <id>] [--detail text] [--write]
  resume-uat <plan_id> [--phase <id>] [--write]
  set-phase <plan_id> --phase <id> --status <status> [--reason r] [--detail t] [--pr-url u] [--pr-head sha] [--write]
  sync-runtime <plan_id> [--branch b] [--write]
  render-control-issue <plan_id> [--title]
  render-halt-comment <plan_id> --reason <status_reason> [--detail text]
  current-phase <plan_id>
  init-control-issue <plan_id>
  set-project-status <plan_id> --status <name> [--issue N]
  complete-plan <plan_id> [--write] [--skip-close]
`);
  process.exit(1);
}

function fail(msg, code = 1) {
  console.error(`execute_plan_runtime: ${msg}`);
  process.exit(code);
}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        flags[key] = true;
      } else {
        flags[key] = next;
        i += 1;
      }
    } else {
      positional.push(arg);
    }
  }
  return { positional, flags };
}

function printJson(obj) {
  console.log(JSON.stringify(obj, null, 2));
}

function main() {
  const { positional, flags } = parseArgs(process.argv.slice(2));
  const cmd = positional[0];
  const planId = positional[1];
  if (!cmd) usage();

  const asyncCmds = new Set(['set-project-status', 'complete-plan']);
  if (asyncCmds.has(cmd)) {
    runAsync(cmd, planId, flags).catch((e) => {
      fail(e instanceof ExecutePlanError ? e.message : e.message);
    });
    return;
  }

  try {
    runSync(cmd, planId, flags);
  } catch (e) {
    fail(e instanceof ExecutePlanError ? e.message : e.message);
  }
}

function runSync(cmd, planId, flags) {
  switch (cmd) {
      case 'gate': {
        if (!planId) usage();
        const snapshot = loadSnapshot(planId);
        validateSnapshot(snapshot);
        const result = checkAutonomyGate(snapshot, { labels: flags.labels });
        printJson(result);
        process.exit(result.ok ? 0 : 2);
      }

      case 'resume-check': {
        if (!planId || !flags.phase) usage();
        const snapshot = loadSnapshot(planId);
        validateSnapshot(snapshot);
        const result = checkResume(snapshot, flags.phase, {
          labels: flags.labels,
          prHeadOid: flags['pr-head'],
          acceptHead: Boolean(flags['accept-head']),
        });
        printJson(result);
        process.exit(result.ok ? 0 : 2);
      }

      case 'halt': {
        if (!planId || !flags.reason) usage();
        const snapshot = loadSnapshot(planId);
        const autonomy = flags.autonomy || 'halted';
        setAutonomyHalted(snapshot, {
          autonomy,
          reason: flags.reason,
          detail: flags.detail,
          phaseId: flags.phase,
        });
        const comment = renderHaltComment(snapshot, {
          reason: flags.reason,
          detail: flags.detail,
        });
        if (flags.write) {
          saveSnapshot(planId, snapshot);
          syncRuntimeState(planId);
        }
        console.log(comment);
        if (!flags.write) {
          console.error('execute_plan_runtime: dry-run (pass --write to persist)');
        }
        break;
      }

      case 'pause': {
        if (!planId || !flags.reason) usage();
        const snapshot = loadSnapshot(planId);
        setPhasePaused(snapshot, {
          reason: flags.reason,
          detail: flags.detail,
          phaseId: flags.phase,
        });
        const comment = renderPauseComment(snapshot, {
          reason: flags.reason,
          detail: flags.detail,
        });
        if (flags.write) {
          saveSnapshot(planId, snapshot);
          syncRuntimeState(planId);
        }
        console.log(comment);
        if (!flags.write) {
          console.error('execute_plan_runtime: dry-run (pass --write to persist)');
        }
        break;
      }

      case 'resume-uat': {
        if (!planId) usage();
        const snapshot = loadSnapshot(planId);
        const { phase } = resumeFromUatPause(snapshot, { phaseId: flags.phase });
        const comment = renderUatResumeComment(snapshot, { phase });
        if (flags.write) {
          saveSnapshot(planId, snapshot);
          syncRuntimeState(planId);
        }
        printJson({
          ok: true,
          phase: { id: phase.id, status: phase.status, branch: phase.branch },
          next_action: computeNextAction(snapshot),
        });
        console.log(comment);
        if (!flags.write) {
          console.error('execute_plan_runtime: dry-run (pass --write to persist)');
        }
        break;
      }

      case 'set-phase': {
        if (!planId || !flags.phase || !flags.status) usage();
        const snapshot = loadSnapshot(planId);
        setPhaseStatus(snapshot, flags.phase, flags.status, {
          statusReason: flags.reason,
          statusDetail: flags.detail,
          prUrl: flags['pr-url'],
          prHeadSha: flags['pr-head'],
          mergeCommit: flags['merge-commit'],
        });
        if (snapshot.autonomy === 'active' && flags.status === 'in_progress') {
          snapshot.phases.forEach((p) => {
            if (p.id !== flags.phase && p.status === 'in_progress') {
              p.status = 'pending';
              p.status_reason = null;
              p.status_detail = null;
            }
          });
        }
        if (flags.write) {
          saveSnapshot(planId, snapshot);
          syncRuntimeState(planId);
        } else {
          printJson(getPhaseSummary(snapshot, flags.phase));
          console.error('execute_plan_runtime: dry-run (pass --write to persist)');
        }
        break;
      }

      case 'sync-runtime': {
        if (!planId) usage();
        loadSnapshot(planId);
        const runtime = syncRuntimeState(planId, {
          branch: flags.branch,
        });
        printJson(runtime);
        break;
      }

      case 'render-control-issue': {
        if (!planId) usage();
        const snapshot = loadSnapshot(planId);
        if (flags.title) {
          console.log(renderControlIssueTitle(planId));
        } else {
          console.log(renderControlIssueBody(snapshot));
        }
        break;
      }

      case 'render-halt-comment': {
        if (!planId || !flags.reason) usage();
        const snapshot = loadSnapshot(planId);
        console.log(
          renderHaltComment(snapshot, { reason: flags.reason, detail: flags.detail })
        );
        break;
      }

      case 'current-phase': {
        if (!planId) usage();
        const snapshot = loadSnapshot(planId);
        const current = findCurrentPhase(snapshot);
        const next = findNextPendingPhase(snapshot);
        printJson({
          current_phase: current ? { id: current.id, status: current.status } : null,
          next_pending: next ? { id: next.id, branch: next.branch } : null,
          next_action: computeNextAction(snapshot),
        });
        break;
      }

      case 'init-control-issue': {
        if (!planId) usage();
        const snapshot = loadSnapshot(planId);
        const labels = controlIssueLabels(planId);
        printJson({
          title: renderControlIssueTitle(planId),
          body: renderControlIssueBody(snapshot),
          labels,
          project_status: 'Backlog',
          gh_command: `gh issue create --title "${renderControlIssueTitle(planId)}" --body-file - --label ${labels.map((l) => `"${l}"`).join(' --label ')}`,
          project_status_note:
            'New control issues enter Project status Backlog. Move to In Progress when work starts (set-project-status).',
        });
        break;
      }

      default:
        usage();
    }
}

async function runAsync(cmd, planId, flags) {
  switch (cmd) {
    case 'set-project-status': {
      if (!planId || !flags.status) usage();
      const snapshot = loadSnapshot(planId);
      validateSnapshot(snapshot);
      const issueNumber = Number(flags.issue || snapshot.control_issue);
      if (!Number.isInteger(issueNumber) || issueNumber < 1) {
        throw new ExecutePlanError('issue number required (--issue or snapshot.control_issue)');
      }
      const result = await updateIssueProjectStatus(issueNumber, flags.status);
      printJson(result);
      if (!result.ok && !result.skipped) {
        process.exit(1);
      }
      break;
    }

    case 'complete-plan': {
      if (!planId) usage();
      const snapshot = loadSnapshot(planId);
      validateSnapshot(snapshot);
      setAutonomyCompleted(snapshot);
      const comment = renderCompletePlanComment(snapshot, planId);
      const issueNumber = snapshot.control_issue;
      if (flags.write) {
        saveSnapshot(planId, snapshot);
        syncRuntimeState(planId);
      }
      const statusResult = await updateIssueProjectStatus(issueNumber, 'Done');
      let closeResult = { skipped: true, reason: 'skip_close_flag' };
      let ok = true;
      const errors = [];

      if (!statusResult.ok && !statusResult.skipped) {
        ok = false;
        errors.push('project_status_failed');
      }

      if (!flags['skip-close']) {
        try {
          closeResult = closeIssueWithComment(issueNumber, comment);
        } catch (e) {
          closeResult = { ok: false, error: e.message, gh_hint: `gh issue close ${issueNumber}` };
          ok = false;
          errors.push('issue_close_failed');
        }
      }

      printJson({
        ok,
        plan_id: planId,
        autonomy: snapshot.autonomy,
        control_issue: issueNumber,
        project_status: statusResult,
        issue_close: closeResult,
        errors: errors.length ? errors : undefined,
        comment,
      });
      if (!flags.write) {
        console.error('execute_plan_runtime: dry-run (pass --write to persist snapshot)');
      }
      if (!ok) {
        process.exit(1);
      }
      break;
    }

    default:
      usage();
  }
}

function getPhaseSummary(snapshot, phaseId) {
  const phase = snapshot.phases.find((p) => p.id === phaseId);
  return phase || null;
}

main();
