'use strict';

/**
 * The `execute-plan-scope` result as a commit status (pure).
 * A status has no check suite, so a cancelled workflow run can never orphan it; the rulesets pin the
 * context to GitHub Actions (integration 15368), so only a status set with a workflow `GITHUB_TOKEN`
 * counts. Observation applies the same rule: statuses from any other creator are ignored.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/state-machine.md §4.0 (`checks`).
 */

const SCOPE_CONTEXT = 'execute-plan-scope';
const TRUSTED_CREATOR = 'github-actions[bot]';
const DESCRIPTION_MAX = 140;

/** `<reason>: <first summary line>`, cut to GitHub's 140-character limit. */
function describeScope(title, summary) {
  const first = String(summary || '').split('\n').find((l) => l.trim()) || '';
  const text = first ? `${title}: ${first.trim()}` : String(title);
  return text.length > DESCRIPTION_MAX ? `${text.slice(0, DESCRIPTION_MAX - 1)}…` : text;
}

const reasonOf = (description) => {
  const m = /^([a-z][a-z-]*)(?::|$)/.exec(String(description || ''));
  return m ? m[1] : null;
};

/**
 * Newest trusted `execute-plan-scope` status → a `checks` entry, or null when none exists.
 * `statuses` = `GET /commits/{sha}/statuses` (any order).
 */
function scopeEntryFromStatuses(statuses) {
  const mine = (statuses || []).filter(
    (s) => s.context === SCOPE_CONTEXT && s.creator && s.creator.login === TRUSTED_CREATOR,
  );
  const latest = mine.reduce((a, b) => (!a || Number(b.id) > Number(a.id) ? b : a), null);
  if (!latest) return null;
  const pending = latest.state === 'pending';
  return {
    name: SCOPE_CONTEXT,
    status: pending ? 'in_progress' : 'completed',
    conclusion: pending ? null : latest.state === 'success' ? 'success' : 'failure',
    reason: reasonOf(latest.description),
    completed_at: pending ? null : latest.updated_at || latest.created_at || null,
  };
}

/** True when any trusted scope status on this commit failed after `epoch`. */
function scopeFailedSince(statuses, epoch) {
  return (statuses || []).some(
    (s) => s.context === SCOPE_CONTEXT && s.creator && s.creator.login === TRUSTED_CREATOR
      && (s.state === 'failure' || s.state === 'error') && Date.parse(s.created_at) > Date.parse(epoch),
  );
}

module.exports = { SCOPE_CONTEXT, TRUSTED_CREATOR, DESCRIPTION_MAX, describeScope, reasonOf, scopeEntryFromStatuses, scopeFailedSince };
