'use strict';

const { ENTRY_STATES, STATE_MARKER } = require('./uat_queue_constants');

class UatQueueError extends Error {
  constructor(message, code = 'uat_queue_error') {
    super(message);
    this.name = 'UatQueueError';
    this.code = code;
  }
}

function nowIso(date = new Date()) {
  return date.toISOString();
}

function createEmptyState() {
  return {
    version: 1,
    updated_at: null,
    main_barrier_sha: null,
    main_barrier_reason: null,
    main_barrier_at: null,
    promote_hold: false,
    promote_hold_reason: null,
    promote_hold_since: null,
    active_watcher: null,
    entries: [],
  };
}

function normalizeState(raw) {
  if (!raw || typeof raw !== 'object') {
    return createEmptyState();
  }
  return {
    version: 1,
    updated_at: raw.updated_at || null,
    main_barrier_sha: raw.main_barrier_sha || null,
    main_barrier_reason: raw.main_barrier_reason || null,
    main_barrier_at: raw.main_barrier_at || null,
    promote_hold: Boolean(raw.promote_hold),
    promote_hold_reason: raw.promote_hold_reason || null,
    promote_hold_since: raw.promote_hold_since || null,
    active_watcher: raw.active_watcher || null,
    entries: Array.isArray(raw.entries) ? raw.entries.map(normalizeEntry) : [],
  };
}

function normalizeEntry(entry) {
  return {
    seq: Number(entry.seq),
    pr_number: Number(entry.pr_number),
    merge_sha: String(entry.merge_sha),
    uat_tag: entry.uat_tag || null,
    enqueued_by: entry.enqueued_by || null,
    enqueued_at: entry.enqueued_at || null,
    state: ENTRY_STATES.has(entry.state) ? entry.state : 'pending',
    result: entry.result || null,
    deploy_run_id: entry.deploy_run_id || null,
    gate_summary_ref: entry.gate_summary_ref || null,
    completed_at: entry.completed_at || null,
  };
}

function parseStateFromCommentBody(body) {
  if (!body || !body.includes(STATE_MARKER)) {
    return createEmptyState();
  }
  const fenceMatch = body.match(/```json\s*([\s\S]*?)\s*```/);
  if (!fenceMatch) {
    throw new UatQueueError('invalid uat-queue-state JSON in marker comment');
  }
  return normalizeState(JSON.parse(fenceMatch[1]));
}

function renderStateCommentBody(state) {
  const payload = normalizeState(state);
  const updatedAt = nowIso();
  payload.updated_at = updatedAt;
  state.updated_at = updatedAt;
  return `${STATE_MARKER}\n\`\`\`json\n${JSON.stringify(payload, null, 2)}\n\`\`\``;
}

function nextSeq(state) {
  if (!state.entries.length) return 1;
  return Math.max(...state.entries.map((e) => e.seq)) + 1;
}

function findEntryByMergeSha(state, mergeSha) {
  const needle = String(mergeSha).toLowerCase();
  return state.entries.find((e) => e.merge_sha.toLowerCase() === needle) || null;
}

function findActiveEntry(state, mergeSha) {
  const entry = findEntryByMergeSha(state, mergeSha);
  if (!entry) return null;
  if (entry.state === 'superseded' || entry.state === 'complete') {
    return null;
  }
  return entry;
}

function expectedUatTag(prNumber, date = new Date()) {
  const yy = String(date.getUTCFullYear()).slice(-2);
  const mm = String(date.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(date.getUTCDate()).padStart(2, '0');
  return `uat-${yy}${mm}${dd}-${Number(prNumber)}`;
}

function parseUatTag(ref) {
  const match = String(ref).match(/^uat-(\d{6})-(\d+)$/);
  if (!match) return null;
  return { yymmdd: match[1], prNumber: Number(match[2]) };
}

/**
 * @param {object} state
 * @param {{ mergeSha: string, prNumber: number, enqueuedBy?: string, uatTag?: string, enqueuedAt?: string }} input
 */
function enqueueEntry(state, input) {
  const mergeSha = String(input.mergeSha).trim();
  const prNumber = Number(input.prNumber);
  if (!mergeSha || !Number.isInteger(prNumber) || prNumber < 1) {
    throw new UatQueueError('enqueue requires --merge and --pr');
  }

  const existing = findEntryByMergeSha(state, mergeSha);
  if (existing && existing.state !== 'superseded') {
    return { state, entry: existing, created: false };
  }

  const entry = normalizeEntry({
    seq: nextSeq(state),
    pr_number: prNumber,
    merge_sha: mergeSha,
    uat_tag: input.uatTag || expectedUatTag(prNumber),
    enqueued_by: input.enqueuedBy || null,
    enqueued_at: input.enqueuedAt || nowIso(),
    state: hasRemedialEntry(state) ? 'frozen' : 'pending',
  });

  state.entries.push(entry);
  return { state, entry, created: true };
}

function hasRemedialEntry(state) {
  return state.entries.some((e) => e.state === 'remedial');
}

function applyRemedialFreeze(state, remedialSeq) {
  for (const entry of state.entries) {
    if (entry.seq > remedialSeq && (entry.state === 'pending' || entry.state === 'deploying')) {
      entry.state = 'frozen';
    }
  }
  return state;
}

function unfreezeAfterBarrier(state) {
  const sorted = [...state.entries].sort((a, b) => a.seq - b.seq);
  for (const entry of sorted) {
    if (entry.state === 'frozen') {
      entry.state = 'pending';
    }
  }
  return state;
}

function setBarrier(state, { sha, reason, at }) {
  const barrierSha = String(sha).trim();
  if (!barrierSha) {
    throw new UatQueueError('set-barrier requires --sha');
  }
  state.main_barrier_sha = barrierSha;
  state.main_barrier_reason = reason || null;
  state.main_barrier_at = at || nowIso();
  clearPromoteHold(state);
  unfreezeAfterBarrier(state);
  return state;
}

function setPromoteHold(state, { reason, at }) {
  state.promote_hold = true;
  state.promote_hold_reason = reason || null;
  state.promote_hold_since = at || nowIso();
  return state;
}

function clearPromoteHold(state) {
  state.promote_hold = false;
  state.promote_hold_reason = null;
  state.promote_hold_since = null;
  return state;
}

function markEntryRemedial(state, { mergeSha, prNumber }) {
  let entry = null;
  if (mergeSha) {
    entry = findEntryByMergeSha(state, mergeSha);
  } else if (prNumber != null) {
    entry = state.entries.find(
      (e) => e.pr_number === Number(prNumber) && e.state !== 'superseded'
    );
  } else {
    entry = headEntryNeedingAttention(state);
  }
  if (!entry) {
    throw new UatQueueError('mark-remedial: no matching queue entry');
  }
  if (entry.state !== 'failed' && entry.state !== 'remedial') {
    throw new UatQueueError(
      `mark-remedial: entry seq ${entry.seq} is ${entry.state}, expected failed or remedial`,
    );
  }
  entry.state = 'remedial';
  applyRemedialFreeze(state, entry.seq);
  return { state, entry };
}

function updateEntry(state, mergeSha, patch) {
  const entry = findEntryByMergeSha(state, mergeSha);
  if (!entry) {
    throw new UatQueueError(`no queue entry for merge ${mergeSha}`);
  }
  if (patch.state && !ENTRY_STATES.has(patch.state)) {
    throw new UatQueueError(`invalid entry state: ${patch.state}`);
  }
  Object.assign(entry, patch);
  if (patch.state === 'remedial') {
    applyRemedialFreeze(state, entry.seq);
  }
  return { state, entry };
}

function updateEntryByPr(state, prNumber, patch) {
  const entry = state.entries.find((e) => e.pr_number === Number(prNumber) && e.state !== 'superseded');
  if (!entry) {
    throw new UatQueueError(`no queue entry for PR #${prNumber}`);
  }
  return updateEntry(state, entry.merge_sha, patch);
}

function applyDeployResult(state, { deployRef, conclusion, deployRunId, gateSummaryRef }) {
  const parsed = parseUatTag(deployRef);
  if (!parsed) {
    throw new UatQueueError(`deploy ref is not a UAT tag: ${deployRef}`);
  }

  const entry =
    state.entries.find((e) => e.pr_number === parsed.prNumber && e.state !== 'superseded') ||
    null;
  if (!entry) {
    return { state, entry: null, skipped: true, reason: 'no_matching_entry' };
  }

  if (conclusion === 'success') {
    entry.state = 'complete';
    entry.result = 'success';
    entry.deploy_run_id = deployRunId || entry.deploy_run_id;
    entry.completed_at = nowIso();
    return { state, entry, skipped: false };
  }

  entry.state = 'failed';
  entry.result = 'failure';
  entry.deploy_run_id = deployRunId || entry.deploy_run_id;
  entry.gate_summary_ref = gateSummaryRef || entry.gate_summary_ref;
  entry.completed_at = nowIso();
  return { state, entry, skipped: false };
}

function isWatcherLeaseActive(state, now = new Date()) {
  const watcher = state.active_watcher;
  if (!watcher || !watcher.lease_until) return false;
  return new Date(watcher.lease_until).getTime() > now.getTime();
}

function normalizeLeaseMinutes(leaseMinutes) {
  const value = Number(leaseMinutes);
  if (!Number.isFinite(value) || value <= 0) {
    throw new UatQueueError('leaseMinutes must be a positive number');
  }
  return value;
}

function acquireWatcher(state, { holder, leaseMinutes = 90, watchingSeq, now = new Date() }) {
  if (!holder || typeof holder !== 'string') {
    throw new UatQueueError('acquire-watcher requires --holder');
  }
  if (isWatcherLeaseActive(state, now)) {
    return { state, acquired: false, reason: 'lease_held', holder: state.active_watcher.holder };
  }
  const minutes = normalizeLeaseMinutes(leaseMinutes);
  const leaseUntil = new Date(now.getTime() + minutes * 60 * 1000);
  state.active_watcher = {
    holder,
    lease_until: leaseUntil.toISOString(),
    watching_seq: watchingSeq || null,
  };
  return { state, acquired: true, watcher: state.active_watcher };
}

function releaseWatcher(state) {
  state.active_watcher = null;
  return state;
}

/**
 * @param {{ barrierSha?: string|null, branchTipSha: string, isAncestor: (ancestor: string, descendant: string) => boolean }} input
 */
function barrierCheck({ barrierSha, branchTipSha, isAncestor }) {
  if (!barrierSha) {
    return { needs_rebase: false, barrier_sha: null, reason: 'no_barrier' };
  }
  const needsRebase = !isAncestor(barrierSha, branchTipSha);
  return {
    needs_rebase: needsRebase,
    barrier_sha: barrierSha,
    branch_tip_sha: branchTipSha,
    reason: needsRebase ? 'branch_behind_barrier' : 'barrier_satisfied',
  };
}

function headEntryNeedingAttention(state) {
  const sorted = [...state.entries].sort((a, b) => a.seq - b.seq);
  return (
    sorted.find((e) =>
      ['pending', 'deploying', 'failed', 'remedial'].includes(e.state)
    ) || null
  );
}

/**
 * Soft merge hold — exit 2 when work agents should not merge until coordinator clears barrier.
 */
function queueHeadHold(state) {
  const head = headEntryNeedingAttention(state);
  if (head && (head.state === 'failed' || head.state === 'remedial')) {
    return {
      hold: true,
      reason: `head_entry_${head.state}`,
      entry: head,
    };
  }
  if (state.promote_hold) {
    return {
      hold: true,
      reason: 'promote_hold',
      entry: head,
    };
  }
  return { hold: false, reason: 'clear', entry: head };
}

module.exports = {
  UatQueueError,
  acquireWatcher,
  applyDeployResult,
  applyRemedialFreeze,
  barrierCheck,
  createEmptyState,
  enqueueEntry,
  expectedUatTag,
  findActiveEntry,
  findEntryByMergeSha,
  hasRemedialEntry,
  headEntryNeedingAttention,
  isWatcherLeaseActive,
  normalizeState,
  parseStateFromCommentBody,
  parseUatTag,
  queueHeadHold,
  releaseWatcher,
  renderStateCommentBody,
  setBarrier,
  setPromoteHold,
  clearPromoteHold,
  markEntryRemedial,
  updateEntry,
  updateEntryByPr,
};
