import { logAuditEventSafe } from './audit.js';
import { createNotification } from './notificationHelper.js';
import {
  NOTIFICATION_KIND_ADMINISTRATIVE,
  NOTIFICATION_PRIORITY_URGENT,
} from './notificationKind.js';
import { OPEN_PLACEMENT_STATUSES, normalizePlacementStatus } from './fosterPlacements.js';
import {
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_PREPARATION,
} from './fosterPlacements.js';
import { ORG_ROLE_ADMIN, ORG_ROLE_SUPER_ADMIN } from './orgRoles.js';

const WITHDRAW_CONFIRMATION = 'withdraw';

const FLAGGABLE_STATUSES = new Set([
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_PREPARATION,
]);

export function isWithdrawConfirmationValid(value) {
  return String(value || '').trim() === WITHDRAW_CONFIRMATION;
}

export async function loadOrgAdminUserIds(pool, orgId) {
  const { rows } = await pool.query(
    `SELECT user_id
     FROM organization_users
     WHERE organization_id = $1
       AND role IN ($2, $3)
       AND role NOT LIKE 'pending_%'`,
    [orgId, ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN],
  );
  return rows.map((row) => row.user_id).filter(Boolean);
}

export async function flagSessionsForAdminReview(pool, {
  orgId,
  fosterUserId,
}) {
  const { rows } = await pool.query(
    `SELECT id, status
     FROM foster_placements
     WHERE organization_id = $1
       AND foster_user_id = $2
       AND status = ANY($3::text[])`,
    [orgId, fosterUserId, OPEN_PLACEMENT_STATUSES],
  );

  const flagged = [];
  for (const row of rows) {
    const status = normalizePlacementStatus(row.status);
    if (!FLAGGABLE_STATUSES.has(status)) continue;
    await pool.query(
      `UPDATE foster_placements
       SET flagged_for_admin_review = true,
           updated_at = NOW()
       WHERE id = $1`,
      [row.id],
    );
    flagged.push(row.id);
  }
  return flagged;
}

export async function withdrawFosterAgreement(pool, {
  orgId,
  fosterUserId,
  actorUserId,
  fosterDisplayName,
  confirmation,
  req = null,
}) {
  if (!isWithdrawConfirmationValid(confirmation)) {
    return { error: 'confirmation_required', status: 400 };
  }

  const relationship = await pool.query(
    `SELECT id, rules_agreement_at
     FROM org_foster_parents
     WHERE organization_id = $1
       AND user_id = $2
     ORDER BY created_at DESC
     LIMIT 1`,
    [orgId, fosterUserId],
  );

  let relationshipId = relationship.rows[0]?.id || null;
  if (relationshipId) {
    await pool.query(
      `UPDATE org_foster_parents
       SET rules_agreement_at = NULL,
           updated_at = NOW()
       WHERE id = $1`,
      [relationshipId],
    );
  }

  const flaggedSessionIds = await flagSessionsForAdminReview(pool, {
    orgId,
    fosterUserId,
  });

  const adminUserIds = await loadOrgAdminUserIds(pool, orgId);
  const fosterName = (fosterDisplayName || '').trim() || 'A foster';
  const title = 'Foster agreement withdrawn';
  const message = `${fosterName} withdrew their agreement to follow organisation rules. Review flagged fostering sessions.`;

  for (const adminUserId of adminUserIds) {
    if (adminUserId === fosterUserId) continue;
    await createNotification(pool, {
      userId: adminUserId,
      title,
      message,
      type: 'agreementWithdrawn',
      kind: NOTIFICATION_KIND_ADMINISTRATIVE,
      priority: NOTIFICATION_PRIORITY_URGENT,
    });
  }

  logAuditEventSafe(pool, {
    actorUserId,
    action: 'foster_agreement_withdrawn',
    resourceType: 'shelter_foster_relationship',
    resourceId: relationshipId,
    orgId,
    metadata: {
      foster_user_id: fosterUserId,
      flagged_session_ids: flaggedSessionIds,
      admin_notification_count: adminUserIds.length,
    },
    req,
  });

  return {
    status: 200,
    flagged_session_ids: flaggedSessionIds,
    relationship_id: relationshipId,
  };
}
