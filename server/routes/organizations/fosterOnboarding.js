import { logAuditEventSafe } from '../../lib/audit.js';
import { hasPermissionForUser } from '../../lib/orgPermissions.js';
import { normaliseRole } from '../../lib/orgRoles.js';

export const FOSTER_ONBOARDING_STEP_KEYS = Object.freeze([
  'connected', 'profile', 'invitation_accepted', 'under_review',
  'onboarding_form', 'home_visit', 'competencies', 'agreement', 'approved',
]);

const DEFERRED_STEP_KEYS = new Set(['onboarding_form', 'home_visit', 'agreement']);

const STEP_LABELS = Object.freeze({
  connected: 'Connected to organisation',
  profile: 'Profile on AgathaTrack',
  invitation_accepted: 'Invitation accepted',
  under_review: 'Under review',
  onboarding_form: 'Onboarding form completed',
  home_visit: 'Home visit recorded',
  competencies: 'Competencies confirmed',
  agreement: 'Agreement signed',
  approved: 'Approved foster',
});

function parseJsonArray(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch { return []; }
  }
  return [];
}

export function isValidFosterOnboardingStepKey(stepKey) {
  return FOSTER_ONBOARDING_STEP_KEYS.includes(stepKey);
}

export function fosterOnboardingStepLabel(stepKey) {
  return STEP_LABELS[stepKey] || stepKey;
}

function fosterResourceId(kind, personId, context) {
  if (context?.fosterParentId) return context.fosterParentId;
  if (kind === 'external') return personId;
  return `${kind}:${personId}`;
}

export async function loadFosterOnboardingContext(pool, orgId, kind, personId) {
  if (kind === 'external') {
    const result = await pool.query(
      `SELECT fp.id AS foster_parent_id, fp.user_id, fp.approval_state,
              fp.rules_agreement_at, fp.foster_profile_id,
              fprof.confirmed_competencies, fprof.self_declared_competencies
       FROM org_foster_parents fp
       LEFT JOIN foster_profiles fprof ON fprof.id = fp.foster_profile_id
       WHERE fp.organization_id = $1 AND fp.id = $2`,
      [orgId, personId],
    );
    const row = result.rows[0];
    if (!row) return null;
    return {
      kind, personId, fosterParentId: row.foster_parent_id, userId: row.user_id,
      role: null, isPending: false, approvalState: row.approval_state || null,
      rulesAgreementAt: row.rules_agreement_at || null,
      fosterProfileId: row.foster_profile_id || null,
      confirmedCompetencies: parseJsonArray(row.confirmed_competencies),
    };
  }
  const result = await pool.query(
    `SELECT ou.id, ou.user_id, ou.role, (ou.role LIKE 'pending_%') AS is_pending,
            ofp.id AS foster_parent_id, ofp.approval_state, ofp.rules_agreement_at,
            fprof.id AS foster_profile_id, fprof.confirmed_competencies,
            fprof.self_declared_competencies
     FROM organization_users ou
     LEFT JOIN org_foster_parents ofp
       ON ofp.organization_id = ou.organization_id AND ofp.user_id = ou.user_id
      AND ofp.opt_out_at IS NULL
     LEFT JOIN foster_profiles fprof ON fprof.user_id = ou.user_id
     WHERE ou.organization_id = $1 AND ou.id = $2`,
    [orgId, personId],
  );
  const row = result.rows[0];
  if (!row) return null;
  return {
    kind, personId, fosterParentId: row.foster_parent_id || null, userId: row.user_id,
    role: normaliseRole(row.role || ''), isPending: row.is_pending === true,
    approvalState: row.approval_state || null, rulesAgreementAt: row.rules_agreement_at || null,
    fosterProfileId: row.foster_profile_id || null,
    confirmedCompetencies: parseJsonArray(row.confirmed_competencies),
  };
}

export function personHasFosterRelationship(context) {
  if (!context) return false;
  if (context.kind === 'external') return true;
  return !!(context.fosterParentId || context.approvalState);
}

export async function loadFosterOnboardingOverrides(pool, orgId, resourceId) {
  const result = await pool.query(
    `SELECT metadata->>'step_key' AS step_key FROM audit_events
     WHERE org_id = $1 AND action = 'foster_onboarding_step_confirmed'
       AND resource_id = $2 ORDER BY occurred_at ASC`,
    [orgId, resourceId],
  );
  return new Set(result.rows.map((r) => r.step_key).filter((k) => k && isValidFosterOnboardingStepKey(k)));
}

function isStepAutoComplete(stepKey, context, overrides) {
  if (overrides.has(stepKey)) return true;
  switch (stepKey) {
    case 'connected': return personHasFosterRelationship(context);
    case 'profile': return !!context.fosterProfileId || (context.kind === 'member' && !!context.userId);
    case 'invitation_accepted':
      if (context.kind === 'external') return !!context.userId;
      return context.kind === 'member' && !context.isPending;
    case 'under_review':
      return ['under_review', 'approved', 'declined', 'archived'].includes(context.approvalState);
    case 'onboarding_form': case 'home_visit': return false;
    case 'competencies': return context.confirmedCompetencies.length > 0;
    case 'agreement': return !!context.rulesAgreementAt;
    case 'approved': return context.approvalState === 'approved';
    default: return false;
  }
}

function isStepIssue(stepKey, context) {
  return stepKey === 'approved' && ['declined', 'archived'].includes(context.approvalState);
}

function isStepDeferred(stepKey, context, overrides) {
  return DEFERRED_STEP_KEYS.has(stepKey) && !isStepAutoComplete(stepKey, context, overrides);
}

export function buildFosterOnboardingSteps(context, overrides = new Set()) {
  const completion = FOSTER_ONBOARDING_STEP_KEYS.map((stepKey) => ({
    stepKey,
    completed: isStepAutoComplete(stepKey, context, overrides),
    issue: isStepIssue(stepKey, context),
    deferred: isStepDeferred(stepKey, context, overrides),
  }));
  let currentIndex = completion.findIndex((s) => !s.completed && !s.issue);
  if (currentIndex < 0) currentIndex = completion.length;
  return completion.map((step, index) => ({
    key: step.stepKey,
    label: fosterOnboardingStepLabel(step.stepKey),
    state: step.issue ? 'issue' : step.completed ? 'complete' : index === currentIndex ? 'current' : 'not_started',
    deferred: step.deferred,
    can_confirm: true,
  }));
}

export async function buildFosterOnboardingTimeline(pool, orgId, kind, personId) {
  const context = await loadFosterOnboardingContext(pool, orgId, kind, personId);
  if (!context || !personHasFosterRelationship(context)) return null;
  const resourceId = fosterResourceId(kind, personId, context);
  const overrides = await loadFosterOnboardingOverrides(pool, orgId, resourceId);
  return { resource_id: resourceId, steps: buildFosterOnboardingSteps(context, overrides) };
}

export async function confirmFosterOnboardingStep(pool, orgId, kind, personId, stepKey, actorUserId, req) {
  if (!isValidFosterOnboardingStepKey(stepKey)) {
    const err = new Error('Invalid step key'); err.statusCode = 400; throw err;
  }
  const context = await loadFosterOnboardingContext(pool, orgId, kind, personId);
  if (!context || !personHasFosterRelationship(context)) {
    const err = new Error('Person not found'); err.statusCode = 404; throw err;
  }
  const resourceId = fosterResourceId(kind, personId, context);
  await logAuditEventSafe(pool, {
    actorUserId, action: 'foster_onboarding_step_confirmed',
    resourceType: 'foster_onboarding_step', resourceId, orgId,
    metadata: { step_key: stepKey, confirmed_by: actorUserId, person_kind: kind, person_id: personId },
    req,
  });
  const overrides = await loadFosterOnboardingOverrides(pool, orgId, resourceId);
  overrides.add(stepKey);
  return { resource_id: resourceId, step_key: stepKey, steps: buildFosterOnboardingSteps(context, overrides) };
}

export async function requireFosterOnboardingReviewPermission(pool, res, orgId, userId) {
  if (await hasPermissionForUser(pool, userId, orgId, 'review_foster_onboarding')) return true;
  if (await hasPermissionForUser(pool, userId, orgId, 'manage_fosters')) return true;
  res.status(403).json({ error: 'Forbidden' });
  return false;
}
