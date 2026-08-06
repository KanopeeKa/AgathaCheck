import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from '../../lib/audit.js';
import {
  normaliseAddressVisibility,
  normaliseContactVisibility,
  normaliseMessageChannel,
  normaliseVisibleTo,
  visibilityFieldsFromRow,
} from '../../lib/fosterVisibility.js';
import { withdrawFosterAgreement } from '../../lib/fosterAgreementWithdrawal.js';
import { isOrgAdmin, isOrgFosterParent } from '../../lib/orgRoles.js';
import { extractUserId, requireMember } from './shared.js';
import { publicError } from '../../config/security.js';

async function ensureMemberFosterRelationship(pool, orgId, userId) {
  const existing = await pool.query(
    `SELECT id
     FROM org_foster_parents
     WHERE organization_id = $1 AND user_id = $2
     ORDER BY created_at DESC
     LIMIT 1`,
    [orgId, userId],
  );
  if (existing.rows.length > 0) {
    return existing.rows[0].id;
  }

  const userResult = await pool.query(
    `SELECT u.id,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
            u.email
     FROM users u
     WHERE u.id = $1`,
    [userId],
  );
  if (userResult.rows.length === 0) return null;
  const user = userResult.rows[0];

  let fosterProfileId = null;
  const profileResult = await pool.query(
    'SELECT id FROM foster_profiles WHERE user_id = $1',
    [userId],
  );
  if (profileResult.rows.length > 0) {
    fosterProfileId = profileResult.rows[0].id;
  }

  const relationshipId = uuidv4();
  await pool.query(
    `INSERT INTO org_foster_parents (
       id, organization_id, user_id, display_name, email, foster_profile_id,
       approval_state, creation_source
     ) VALUES ($1, $2, $3, $4, $5, $6, 'approved', 'member')`,
    [
      relationshipId,
      orgId,
      userId,
      (user.display_name || '').trim() || user.email || '',
      user.email || null,
      fosterProfileId,
    ],
  );
  return relationshipId;
}

async function requireFosterSelf(pool, orgId, role, res, userId, targetUserId) {
  const isSelfFoster = await isOrgFosterParent(pool, orgId, userId);
  if (!isOrgAdmin(role) && !isSelfFoster) {
    res.status(403).json({ error: 'Forbidden' });
    return false;
  }
  if (!isOrgAdmin(role) && userId !== targetUserId) {
    res.status(403).json({ error: 'Forbidden' });
    return false;
  }
  return true;
}

export function registerFosterSelfManagementRoutes(router, pool) {
  router.patch('/:orgId/foster-parents/self/visibility', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};

    try {
      const role = await requireMember(pool, res, orgId, userId);
      if (!role) return;
      if (!(await requireFosterSelf(pool, orgId, role, res, userId, userId))) return;

      const relationshipId = await ensureMemberFosterRelationship(pool, orgId, userId);
      if (!relationshipId) {
        return res.status(404).json({ error: 'Foster relationship not found' });
      }

      const visibleTo = normaliseVisibleTo(data.visible_to ?? data.visibleTo);
      const addressVisibility = normaliseAddressVisibility(
        data.address_visibility ?? data.addressVisibility,
      );
      const contactVisibility = normaliseContactVisibility(
        data.contact_visibility ?? data.contactVisibility,
      );
      const messageChannel = normaliseMessageChannel(
        data.notification_message_channel ?? data.notificationMessageChannel,
      );

      const result = await pool.query(
        `UPDATE org_foster_parents
         SET visible_to = $1,
             address_visibility = $2,
             contact_visibility = $3,
             notification_message_channel = $4,
             updated_at = NOW()
         WHERE id = $5 AND organization_id = $6
         RETURNING *`,
        [
          visibleTo,
          addressVisibility,
          contactVisibility,
          messageChannel,
          relationshipId,
          orgId,
        ],
      );

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'foster_visibility_changed',
        resourceType: 'shelter_foster_relationship',
        resourceId: relationshipId,
        orgId,
        metadata: visibilityFieldsFromRow(result.rows[0]),
        req,
      });

      res.json(visibilityFieldsFromRow(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-parents/self/withdraw-agreement', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};
    const confirmation = data.confirmation ?? data.confirmText ?? '';

    try {
      const role = await requireMember(pool, res, orgId, userId);
      if (!role) return;
      if (!(await requireFosterSelf(pool, orgId, role, res, userId, userId))) return;

      const userResult = await pool.query(
        `SELECT TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) AS display_name
         FROM users WHERE id = $1`,
        [userId],
      );
      const displayName = userResult.rows[0]?.display_name || '';

      const outcome = await withdrawFosterAgreement(pool, {
        orgId,
        fosterUserId: userId,
        actorUserId: userId,
        fosterDisplayName: displayName,
        confirmation,
        req,
      });

      if (outcome.error) {
        return res.status(outcome.status).json({ error: outcome.error });
      }

      res.json({
        withdrawn: true,
        flagged_session_ids: outcome.flagged_session_ids,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
