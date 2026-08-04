import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from '../../lib/audit.js';
import {
  PRIVACY_FIELDS,
  CARD_VISIBILITY_ALL,
  CARD_VISIBILITY_ADMINS,
  CARD_VISIBILITY_NAMED,
  CONTACT_VISIBILITY_ADMINS,
  CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS,
  CONTACT_VISIBILITY_ADMINS_OR_NAMED,
  CONTACT_VISIBILITY_NAMED,
  ADDRESS_VISIBILITY_ADMINS_OR_NAMED,
  ADDRESS_VISIBILITY_ADMINS,
  ADDRESS_VISIBILITY_NAMED,
  ADDRESS_VISIBILITY_HIDDEN,
  enforceCardVisibilityFloor,
  grantsByFieldFromRows,
  normaliseAddressVisibility,
  normaliseCardVisibility,
  normaliseContactVisibility,
  privacyPayloadFromMembership,
  privacySettingsFromRow,
} from '../../lib/orgMemberPrivacy.js';
import { normaliseRole } from '../../lib/orgRoles.js';
import { publicError } from '../../config/security.js';
import { extractUserId, requireMember } from './shared.js';

async function loadMembershipPrivacy(pool, orgId, userId) {
  const result = await pool.query(
    `SELECT ou.id,
            ou.organization_id,
            ou.user_id,
            ou.role,
            ou.card_visibility,
            ou.phone_visibility,
            ou.email_visibility,
            ou.address_visibility
     FROM organization_users ou
     WHERE ou.organization_id = $1 AND ou.user_id = $2`,
    [orgId, userId],
  );
  return result.rows[0] || null;
}

async function loadGrantsForSubject(pool, orgId, subjectUserId) {
  const result = await pool.query(
    `SELECT field, grantee_user_id
     FROM organization_visibility_grants
     WHERE organization_id = $1 AND subject_user_id = $2`,
    [orgId, subjectUserId],
  );
  return result.rows;
}

async function loadActiveGranteeIds(pool, orgId, granteeIds) {
  if (!granteeIds.length) return new Set();
  const result = await pool.query(
    `SELECT user_id
     FROM organization_users
     WHERE organization_id = $1
       AND user_id = ANY($2::uuid[])
       AND role NOT LIKE 'pending_%'`,
    [orgId, granteeIds],
  );
  return new Set(result.rows.map((row) => row.user_id));
}

async function listAvailableMembers(pool, orgId, excludeUserId) {
  const result = await pool.query(
    `SELECT u.id AS user_id,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
            ou.role
     FROM organization_users ou
     JOIN users u ON u.id = ou.user_id
     WHERE ou.organization_id = $1
       AND ou.user_id <> $2
       AND ou.role NOT LIKE 'pending_%'
     ORDER BY display_name, u.email`,
    [orgId, excludeUserId],
  );
  return result.rows.map((row) => ({
    user_id: row.user_id,
    display_name: (row.display_name || '').trim(),
    role: normaliseRole(row.role),
  }));
}

function isProvided(value) {
  return value !== undefined && value !== null && String(value).trim() !== '';
}

function validatePrivacyPayload(data, role) {
  const errors = [];
  const cardRaw = data.card_visibility ?? data.cardVisibility;
  const phoneRaw = data.phone_visibility ?? data.phoneVisibility;
  const emailRaw = data.email_visibility ?? data.emailVisibility;
  const addressRaw = data.address_visibility ?? data.addressVisibility;

  const cardValues = new Set([CARD_VISIBILITY_ALL, CARD_VISIBILITY_ADMINS, CARD_VISIBILITY_NAMED]);
  const contactValues = new Set([
    CONTACT_VISIBILITY_ADMINS,
    CONTACT_VISIBILITY_ADMINS_AND_FOSTER_MANAGERS,
    CONTACT_VISIBILITY_ADMINS_OR_NAMED,
    CONTACT_VISIBILITY_NAMED,
  ]);
  const addressValues = new Set([
    ADDRESS_VISIBILITY_ADMINS_OR_NAMED,
    ADDRESS_VISIBILITY_ADMINS,
    ADDRESS_VISIBILITY_NAMED,
    ADDRESS_VISIBILITY_HIDDEN,
  ]);

  if (isProvided(cardRaw) && !cardValues.has(String(cardRaw).trim())) {
    errors.push('Invalid card_visibility');
  }
  if (isProvided(phoneRaw) && !contactValues.has(String(phoneRaw).trim())) {
    errors.push('Invalid phone_visibility');
  }
  if (isProvided(emailRaw) && !contactValues.has(String(emailRaw).trim())) {
    errors.push('Invalid email_visibility');
  }
  if (isProvided(addressRaw) && !addressValues.has(String(addressRaw).trim())) {
    errors.push('Invalid address_visibility');
  }

  return errors;
}

function parseGrantInput(body = {}) {
  const raw = body.grants || {};
  const parsed = {};
  for (const field of PRIVACY_FIELDS) {
    const values = raw[field];
    parsed[field] = Array.isArray(values)
      ? [...new Set(values.map((id) => String(id || '').trim()).filter(Boolean))]
      : [];
  }
  return parsed;
}

async function replaceGrants(pool, orgId, subjectUserId, grantsByField) {
  await pool.query(
    `DELETE FROM organization_visibility_grants
     WHERE organization_id = $1 AND subject_user_id = $2`,
    [orgId, subjectUserId],
  );

  const allGranteeIds = [...new Set(PRIVACY_FIELDS.flatMap((field) => grantsByField[field]))];
  const activeGrantees = await loadActiveGranteeIds(pool, orgId, allGranteeIds);

  for (const field of PRIVACY_FIELDS) {
    for (const granteeUserId of grantsByField[field]) {
      if (!activeGrantees.has(granteeUserId)) continue;
      await pool.query(
        `INSERT INTO organization_visibility_grants (
           id, organization_id, subject_user_id, grantee_user_id, field
         ) VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (organization_id, subject_user_id, grantee_user_id, field)
         DO NOTHING`,
        [uuidv4(), orgId, subjectUserId, granteeUserId, field],
      );
    }
  }
}

export async function getMemberPrivacyPayload(pool, orgId, userId) {
  const membership = await loadMembershipPrivacy(pool, orgId, userId);
  if (!membership) return null;
  const grantRows = await loadGrantsForSubject(pool, orgId, userId);
  const grants = grantsByFieldFromRows(grantRows);
  const availableMembers = await listAvailableMembers(pool, orgId, userId);
  return {
    ...privacyPayloadFromMembership(membership, grants),
    available_members: availableMembers,
  };
}

export function registerMemberPrivacyRoutes(router, pool) {
  router.get('/:orgId/members/me/privacy', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    try {
      const role = await requireMember(pool, res, orgId, userId);
      if (!role) return;
      const payload = await getMemberPrivacyPayload(pool, orgId, userId);
      if (!payload) return res.status(404).json({ error: 'Membership not found' });
      res.json(payload);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:orgId/members/me/privacy', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};
    try {
      const role = await requireMember(pool, res, orgId, userId);
      if (!role) return;

      const membership = await loadMembershipPrivacy(pool, orgId, userId);
      if (!membership) return res.status(404).json({ error: 'Membership not found' });

      const validationErrors = validatePrivacyPayload(data, role);
      if (validationErrors.length > 0) {
        return res.status(400).json({ error: validationErrors[0] });
      }

      const defaults = privacySettingsFromRow({}, role);
      const cardVisibility = enforceCardVisibilityFloor(
        normaliseCardVisibility(data.card_visibility ?? data.cardVisibility),
        role,
      );
      const phoneVisibility = normaliseContactVisibility(
        data.phone_visibility ?? data.phoneVisibility,
        defaults.phone_visibility,
      );
      const emailVisibility = normaliseContactVisibility(
        data.email_visibility ?? data.emailVisibility,
        defaults.email_visibility,
      );
      const addressVisibility = normaliseAddressVisibility(
        data.address_visibility ?? data.addressVisibility,
      );

      const grantsByField = parseGrantInput(data);
      const previous = await getMemberPrivacyPayload(pool, orgId, userId);

      const updated = await pool.query(
        `UPDATE organization_users
         SET card_visibility = $1,
             phone_visibility = $2,
             email_visibility = $3,
             address_visibility = $4,
             updated_at = NOW()
         WHERE organization_id = $5 AND user_id = $6
         RETURNING *`,
        [
          cardVisibility,
          phoneVisibility,
          emailVisibility,
          addressVisibility,
          orgId,
          userId,
        ],
      );

      await replaceGrants(pool, orgId, userId, grantsByField);
      const payload = await getMemberPrivacyPayload(pool, orgId, userId);

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'member_visibility_changed',
        resourceType: 'organization_membership',
        resourceId: updated.rows[0]?.id || membership.id,
        orgId,
        metadata: {
          previous,
          current: payload,
        },
        req,
      });

      res.json(payload);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
