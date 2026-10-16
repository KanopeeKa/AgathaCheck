'use strict';

/**
 * Execute-plan v2 status comment: parse, format, and fold a decision into the next status.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/contracts.md §3.5.
 */

const STATUS_MARKER = (planId) => `<!-- execute-plan-status:${planId} -->`;
const MAX_LAUNCHES = 50;
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
  const next = { ...status, launches: [...(status.launches || [])].slice(-MAX_LAUNCHES) };
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

module.exports = { STATUS_MARKER, parseStatusComment, formatStatusComment, formatLogLine, applyDecisionToStatus };
