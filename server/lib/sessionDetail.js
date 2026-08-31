/**
 * Viewer-scoped fostering session aggregate (session-detail-view-eec3).
 * Spec: docs/domains/fostering/features/session-detail-view.md
 */
import { getJourneyForSession, journeyToMap } from './adoptionJourneys.js';
import { deriveSessionStatus } from './deriveSessionStatus.js';
import {
  ensureDefaultTemplates,
  listTemplatesForOrg,
  parseChecklistItems,
  renderChecklistFromTemplates,
  TEMPLATE_TYPE_SESSION_CHECKLIST,
} from './documentTemplates.js';
import {
  isPendingFosterAcceptance,
  loadPlacementDetail,
  normalizePlacementStatus,
  placementToMap,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_CONVERTED_TO_ADOPTION,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
  SESSION_STATUS_RETURNED_TO_SHELTER,
  SESSION_STATUS_TRANSFERRED,
  SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT,
} from './fosterPlacements.js';
import { hasPermissionForUser } from './orgPermissions.js';
import { normaliseRole } from './orgRoles.js';

export const VIEWER_ROLE_FOSTER_PARTICIPANT = 'foster_participant';
export const VIEWER_ROLE_SHELTER_OPERATOR = 'shelter_operator';
export const VIEWER_ROLE_SHELTER_OBSERVER = 'shelter_observer';
export const VIEWER_ROLE_READ_ONLY_HISTORY = 'read_only_history';

const TERMINAL_STATUSES = new Set([
  SESSION_STATUS_RETURNED_TO_SHELTER,
  SESSION_STATUS_TRANSFERRED,
  SESSION_STATUS_CONVERTED_TO_ADOPTION,
  SESSION_STATUS_CANCELLED,
]);

export function isTerminalSessionStatus(sessionStatus) {
  return TERMINAL_STATUSES.has(sessionStatus);
}

async function lookupMemberRole(pool, orgId, userId) {
  const result = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, userId],
  );
  return result.rows.length ? normaliseRole(result.rows[0].role) : null;
}

/**
 * Resolve viewer role for a session row. Returns { role } or { error, status }.
 */
export async function resolveSessionViewer(pool, { userId, placement }) {
  if (!placement) {
    return { error: 'Placement not found', status: 404 };
  }

  const sessionStatus = normalizePlacementStatus(placement.status);

  if (placement.foster_user_id === userId) {
    const role = isTerminalSessionStatus(sessionStatus)
      ? VIEWER_ROLE_READ_ONLY_HISTORY
      : VIEWER_ROLE_FOSTER_PARTICIPANT;
    return { role };
  }

  const memberRole = await lookupMemberRole(pool, placement.organization_id, userId);
  if (!memberRole) {
    return { error: 'Forbidden', status: 403 };
  }

  const canManage = await hasPermissionForUser(
    pool,
    userId,
    placement.organization_id,
    'manage_fostering_sessions',
  );
  if (canManage) {
    const role = isTerminalSessionStatus(sessionStatus)
      ? VIEWER_ROLE_READ_ONLY_HISTORY
      : VIEWER_ROLE_SHELTER_OPERATOR;
    return { role };
  }

  const canView = await hasPermissionForUser(
    pool,
    userId,
    placement.organization_id,
    'view_fostering_sessions',
  );
  if (canView) {
    return { role: VIEWER_ROLE_SHELTER_OBSERVER };
  }

  return { error: 'Forbidden', status: 403 };
}

export function buildAllowedActions(placement, viewerRole) {
  if (
    viewerRole === VIEWER_ROLE_READ_ONLY_HISTORY
    || viewerRole === VIEWER_ROLE_SHELTER_OBSERVER
  ) {
    if (
      viewerRole === VIEWER_ROLE_SHELTER_OBSERVER
      && isTerminalSessionStatus(normalizePlacementStatus(placement.status))
    ) {
      return [];
    }
    if (viewerRole === VIEWER_ROLE_READ_ONLY_HISTORY) {
      return [];
    }
  }

  const sessionStatus = normalizePlacementStatus(placement.status);
  const actions = [];

  const isFoster = viewerRole === VIEWER_ROLE_FOSTER_PARTICIPANT;
  const isOperator = viewerRole === VIEWER_ROLE_SHELTER_OPERATOR;

  if (isFoster || isOperator) {
    actions.push('contact_counterparty');
  }

  if (
    isFoster
    && (sessionStatus === SESSION_STATUS_PENDING_ACCEPTANCE
      || placement.status === 'pending')
  ) {
    actions.push('accept_invite', 'decline_invite');
    return actions;
  }

  if (isFoster && sessionStatus === SESSION_STATUS_READY_TO_START && !placement.foster_start_confirmed_at) {
    actions.push('confirm_foster_start');
  }

  if (isOperator && sessionStatus === SESSION_STATUS_PENDING_ACCEPTANCE) {
    actions.push('transition_preparation');
  }
  if (isOperator && sessionStatus === SESSION_STATUS_PREPARATION) {
    actions.push('transition_ready_to_start', 'update_checklist_item');
  }
  if (isOperator && sessionStatus === SESSION_STATUS_READY_TO_START && !placement.shelter_start_confirmed_at) {
    actions.push('confirm_shelter_start');
  }

  if (
    (isFoster || isOperator)
    && [SESSION_STATUS_PREPARATION, SESSION_STATUS_READY_TO_START, SESSION_STATUS_ACTIVE].includes(sessionStatus)
  ) {
    if (!actions.includes('update_checklist_item')) {
      actions.push('update_checklist_item');
    }
  }

  if (isOperator) {
    actions.push('register_export');
  }

  if (isOperator && sessionStatus === SESSION_STATUS_ACTIVE) {
    actions.push('request_end');
    if ((placement.session_type || '') === SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT) {
      actions.push('start_adoption_journey', 'expedite_visit_adoption');
    }
  }

  if (isOperator && sessionStatus === SESSION_STATUS_END_PENDING_CONFIRMATION) {
    actions.push('complete_end_returned', 'complete_end_cancelled');
  }

  if (sessionStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
    const conditions = (placement.adoption_conditions || '').trim();
    const awaitingConfirmation = placement.status === PLACEMENT_STATUS_WAITING_ADOPTION
      || (sessionStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS && !conditions);
    if (awaitingConfirmation && (isFoster || isOperator)) {
      actions.push('confirm_adoption');
    }
    if (isOperator) {
      if (placement.status === PLACEMENT_STATUS_PENDING_CONDITIONS
        || (sessionStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS && conditions)) {
        actions.push('complete_adoption_conditions');
      }
      actions.push('cancel_adoption');
    }
  }

  return [...new Set(actions)];
}

function buildCounterparty(placement, viewerRole) {
  if (viewerRole === VIEWER_ROLE_FOSTER_PARTICIPANT || viewerRole === VIEWER_ROLE_READ_ONLY_HISTORY) {
    return {
      kind: 'organization',
      id: placement.organization_id,
      display_name: placement.organization_name || '',
    };
  }
  return {
    kind: 'foster',
    id: placement.foster_user_id || null,
    display_name: (placement.foster_name || '').trim() || placement.foster_email || '',
    email: placement.foster_email || null,
  };
}

async function loadChecklistBlock(pool, placement) {
  await ensureDefaultTemplates(pool, placement.organization_id);
  const templates = await listTemplatesForOrg(
    pool,
    placement.organization_id,
    TEMPLATE_TYPE_SESSION_CHECKLIST,
  );
  const items = renderChecklistFromTemplates(
    templates,
    parseChecklistItems(placement.session_checklist_items),
  );
  return {
    items,
    templates: templates.map((t) => ({
      template_key: t.template_key,
      label: t.label,
      is_required: t.is_required,
    })),
  };
}

async function loadAdoptionBlock(pool, placementId) {
  const journeyRow = await getJourneyForSession(pool, placementId);
  if (!journeyRow) return null;
  return { journey: journeyToMap(journeyRow) };
}

/**
 * Build full session aggregate for a resolved viewer.
 */
export async function buildSessionAggregate(pool, placementId, viewerRole) {
  const row = await loadPlacementDetail(pool, placementId);
  if (!row) {
    return { error: 'Placement not found', status: 404 };
  }

  const sessionMap = placementToMap(row);
  const derived = deriveSessionStatus(row);
  const session = {
    ...sessionMap,
    derived_status: derived.derived_status,
    nearly_finished: derived.nearly_finished,
    in_view_to_adopt: derived.in_view_to_adopt,
    flagged_for_admin_review: row.flagged_for_admin_review === true,
  };

  const [checklist, adoption] = await Promise.all([
    loadChecklistBlock(pool, row),
    loadAdoptionBlock(pool, placementId),
  ]);

  const allowedActions = buildAllowedActions(row, viewerRole);

  return {
    status: 200,
    body: {
      ...session,
      viewer: {
        role: viewerRole,
        allowed_actions: allowedActions,
      },
      pet: {
        id: row.pet_id,
        name: row.pet_name || '',
        species: row.pet_species || '',
      },
      organization: {
        id: row.organization_id,
        name: row.organization_name || '',
      },
      counterparty: buildCounterparty(row, viewerRole),
      checklist,
      adoption,
      documents: [],
    },
  };
}

/**
 * Load session aggregate for an authenticated user (foster or shelter).
 */
export async function loadSessionAggregateForUser(pool, placementId, userId) {
  const row = await loadPlacementDetail(pool, placementId);
  if (!row) {
    return { error: 'Placement not found', status: 404 };
  }

  const viewerResult = await resolveSessionViewer(pool, { userId, placement: row });
  if (viewerResult.error) {
    return viewerResult;
  }

  return buildSessionAggregate(pool, placementId, viewerResult.role);
}
