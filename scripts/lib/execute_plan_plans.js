'use strict';

/**
 * Execute-plan v2: map PR refs and labels to plan ids and control issues.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/work-packages-platform.md §WP7a.
 */

const PLAN = '[a-z0-9][a-z0-9-]{2,48}';
const INTEGRATION_RE = new RegExp(`^cursor/(${PLAN})-integration-[a-z0-9]{4}$`);
const HEAD_RES = [
  new RegExp(`^cursor/(${PLAN})-p\\d+$`),
  new RegExp(`^cursor/(${PLAN})-sync-\\d+$`),
  new RegExp(`^cursor/(${PLAN})-remedial-\\d+$`),
  INTEGRATION_RE,
];

const LABEL_EXECUTE_PLAN = 'execute-plan';
const LABEL_APPROVED = 'autonomous-approved';
const LABEL_COMPLETE = 'plan:complete';
const PLAN_LABEL_PREFIX = 'plan:';

/** Candidate plan id from the PR refs (same shapes as categorizePull), or null. */
function planIdFromRefs({ head_ref, base_ref }) {
  for (const re of HEAD_RES) {
    const m = re.exec(head_ref || '');
    if (m) return m[1];
  }
  const m = INTEGRATION_RE.exec(base_ref || '');
  return m ? m[1] : null;
}

function labelNames(issue) {
  return ((issue && issue.labels) || []).map((l) => (typeof l === 'string' ? l : l.name));
}

/** Open issue labelled `execute-plan` + `plan:<id>`, else null (lowest number wins). */
async function findControlIssue(client, planId) {
  const issues = await client.listIssues({ labels: [LABEL_EXECUTE_PLAN, `${PLAN_LABEL_PREFIX}${planId}`], state: 'open' });
  const sorted = [...issues].sort((a, b) => a.number - b.number);
  return sorted[0] || null;
}

/** Open, approved, not-complete plans as `{ planId, issueNumber }`. */
async function listActivePlans(client) {
  const issues = await client.listIssues({ labels: [LABEL_EXECUTE_PLAN, LABEL_APPROVED], state: 'open' });
  const plans = [];
  for (const issue of issues) {
    const labels = labelNames(issue);
    if (labels.includes(LABEL_COMPLETE)) continue;
    const planLabel = labels.find((l) => l.startsWith(PLAN_LABEL_PREFIX) && l !== LABEL_COMPLETE);
    if (planLabel) plans.push({ planId: planLabel.slice(PLAN_LABEL_PREFIX.length), issueNumber: issue.number });
  }
  return plans;
}

module.exports = { planIdFromRefs, findControlIssue, listActivePlans, labelNames };
