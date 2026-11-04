'use strict';

/**
 * Execute-plan v2 status comment: parse, format, and fold a decision into the next status.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/contracts.md §3.5.
 */

const { MAX_LAUNCH_HISTORY } = require('./execute_plan_constants');

const STATUS_MARKER = (planId) => `<!-- execute-plan-status:${planId} -->`;
const FENCE_RE = /```json\s*\n([\s\S]*?)\n```/;

/** @returns {object|null} the JSON block of a status comment, or null when absent or malformed. */
function parseStatusComment(body) {
  const text = String(body == null ? '' : body);
  const first = text.trimStart().split('\n', 1)[0].trim();
  if (!/^<!-- execute-plan-status:[a-z0-9][a-z0-9-]{2,48} -->$/.test(first)) return null;
  const m = FENCE_RE.exec(text);
  if (!m) return null;
  try {
    const parsed = JSON.parse(m[1]);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

const cell = (v) => (v === null || v === undefined || v === '' ? '—' : String(v).replace(/\\/g, '\\\\').replace(/\|/g, '\\|').replace(/\s+/g, ' '));

/** `table` is a ready string, or rows `{ phase, branch, pr, state, failed, launches }`. */
function formatStatusComment(status, table) {
  let rows = '';
  if (typeof table === 'string') rows = table;
  else {
    const header = ['| Phase | Branch | PR | State | Failed attempts | Launches |', '|---|---|---|---|---|---|'];
    const body = (table || []).map(
      (r) => `| ${cell(r.phase)} | ${cell(r.branch)} | ${cell(r.pr)} | ${cell(r.state)} | ${cell(r.failed)} | ${cell(r.launches)} |`,
    );
    rows = [...header, ...body].join('\n');
  }
  return `${STATUS_MARKER(status.plan_id)}\n\`\`\`json\n${JSON.stringify(status, null, 2)}\n\`\`\`\n\n${rows}\n`;
}

function formatLogLine(oldState, newState, url) {
  return `execute-plan: ${oldState} → ${newState} — ${url}`;
}

/**
 * Pure. Folds one decision into the status. Driver-written fields (lease, launches, dispatched)
 * are carried over untouched; a worker tick refreshes `lease.last_tick_at`.
 * `observations` (optional) lets the release PR merge be recorded; `epoch` keeps a stop's `at` only while it is current.
 */
function applyDecisionToStatus(status, decision, { now, actor, observations, epoch } = {}) {
  const next = { ...status, launches: [...(status.launches || [])].slice(-MAX_LAUNCH_HISTORY) };
  next.state = decision.state;
  next.phase = decision.phase === undefined ? null : decision.phase;
  if (actor === 'agent' && next.lease) next.lease = { ...next.lease, last_tick_at: now };
  const rel = observations && observations.release && observations.release.pr;
  if (rel && rel.merged_at && !next.release) next.release = { pr: rel.number, merge_sha: rel.merge_commit_sha || null };
  if (decision.stop) {
    const prev = status.stop;
    const current = prev && (!epoch || Date.parse(prev.at) > Date.parse(epoch));
    const same = current && prev.reason === decision.stop.reason && prev.detail === decision.stop.detail;
    next.stop = same ? prev : { reason: decision.stop.reason, detail: decision.stop.detail, at: now };
  }
  next.updated_at = now;
  return next;
}

/**
 * Fold a just-read status comment into a proposed write so a stale in-memory copy cannot drop a
 * concurrent driver's stop or regress driver-owned fields (launches, dispatched, release).
 * `baseline` is the status loaded at the start of the tick.
 */
function mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline }) {
  if (!fresh || typeof fresh !== 'object') return proposed;
  const next = { ...proposed };
  const stopIsCurrent = (stop) =>
    stop &&
    epoch &&
    Number.isFinite(Date.parse(stop.at)) &&
    Number.isFinite(Date.parse(epoch)) &&
    Date.parse(stop.at) > Date.parse(epoch);
  const stopAt = (stop) => (stop && stop.at && Date.parse(stop.at)) || 0;

  const freshStopCurrent = stopIsCurrent(fresh.stop);
  if (freshStopCurrent) {
    const baselineStopAt = stopAt(baseline && baseline.stop);
    const freshStopAt = stopAt(fresh.stop);
    const proposedStopAt = stopAt(proposed.stop);
    const driverWroteAfterLoad = freshStopAt > baselineStopAt;
    const proposedWouldDrop = !stopIsCurrent(proposed.stop);
    const liveNotOlderThanProposed = freshStopAt >= proposedStopAt;
    if (driverWroteAfterLoad || proposedWouldDrop || liveNotOlderThanProposed) {
      next.stop = fresh.stop;
      if (fresh.state === 'stopped') {
        next.state = fresh.state;
        next.phase = fresh.phase;
      }
    }
  }

  const lastLaunchAt = (arr) => Date.parse((Array.isArray(arr) && arr.at(-1) && arr.at(-1).at) || 0);
  const freshLaunches = fresh.launches || [];
  const nextLaunches = next.launches || [];
  if (
    Date.parse(fresh.updated_at || 0) > Date.parse((baseline && baseline.updated_at) || 0) ||
    lastLaunchAt(freshLaunches) > lastLaunchAt(nextLaunches)
  ) {
    next.launches = freshLaunches;
  }

  const mergeList = (a, b) => [...new Set([...(Array.isArray(a) ? a : []), ...(Array.isArray(b) ? b : [])])];
  const fd = fresh.dispatched || {};
  const nd = next.dispatched || {};
  next.dispatched = {
    preuat_heads: mergeList(fd.preuat_heads, nd.preuat_heads),
    deploy_tags: mergeList(fd.deploy_tags, nd.deploy_tags),
    ...(fd.scope_republish || nd.scope_republish ? { scope_republish: fd.scope_republish || nd.scope_republish } : {}),
  };
  if (fresh.release && !next.release) next.release = fresh.release;

  const tickAt = (lease) => (lease && (lease.last_tick_at || lease.launched_at)) || null;
  const freshTick = tickAt(fresh.lease);
  const nextTick = tickAt(next.lease);
  if (fresh.lease && freshTick && (!nextTick || Date.parse(freshTick) > Date.parse(nextTick))) {
    next.lease = { ...next.lease, ...fresh.lease, last_tick_at: freshTick };
  }

  return next;
}

async function readMergedStatusForWrite(client, commentId, proposed, { epoch, baseline }) {
  const live = await client.getIssueComment(commentId);
  let fresh = parseStatusComment(live.body);
  let merged = mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline });
  const again = await client.getIssueComment(commentId);
  if (again.updated_at !== live.updated_at) {
    fresh = parseStatusComment(again.body);
    merged = mergeStatusBeforeWrite(proposed, fresh, { epoch, baseline });
  }
  return merged;
}

module.exports = {
  STATUS_MARKER,
  parseStatusComment,
  formatStatusComment,
  formatLogLine,
  applyDecisionToStatus,
  mergeStatusBeforeWrite,
  readMergedStatusForWrite,
};
