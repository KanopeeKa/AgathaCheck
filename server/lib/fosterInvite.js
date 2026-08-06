/**
 * Foster invite flows — email for new users, in-app notification for existing users.
 */
import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from './audit.js';
import { buildFosterInvitationNewUserEmail } from './email/templates/fosterInvitationNewUser.js';
import { resolveEmailLocale } from './email/locale.js';
import { createNotification, userDisplayName } from './notificationHelper.js';
import { createFosterProfileForManualParent } from './fosterProfiles.js';
import { defaultRetentionCategoryForParent } from './fosterCompliance.js';
import {
  isOrgFosterParent,
  isOrgAdmin,
  isSuperAdmin,
  normaliseRole,
} from './orgRoles.js';
import { sendTransactionalEmail } from '../services/mailService.js';

const CREATION_SOURCE_INVITE = 'invite';

async function loadOrgContext(pool, orgId) {
  const result = await pool.query(
    'SELECT name, bio, email, logo_url FROM organizations WHERE id = $1',
    [orgId],
  );
  const row = result.rows[0] || {};
  return {
    name: row.name || 'Your organisation',
    bio: row.bio || '',
    email: row.email || '',
    logoUrl: row.logo_url || '',
  };
}

async function loadInviterContext(pool, orgId, actorUserId) {
  const result = await pool.query(
    `SELECT u.first_name, u.last_name, u.email, ou.role
     FROM users u
     JOIN organization_users ou ON ou.user_id = u.id AND ou.organization_id = $2
     WHERE u.id = $1`,
    [actorUserId, orgId],
  );
  if (result.rows.length === 0) return { name: 'An organisation admin', role: 'admin' };
  const row = result.rows[0];
  const role = normaliseRole(row.role);
  let roleLabel = 'associate';
  if (isSuperAdmin(role)) roleLabel = 'super admin';
  else if (isOrgAdmin(role)) roleLabel = 'admin';
  return { name: userDisplayName(row), role: roleLabel };
}

async function findExistingFosterRelationship(pool, orgId, userId) {
  const result = await pool.query(
    `SELECT id FROM org_foster_parents
     WHERE organization_id = $1 AND user_id = $2 AND opt_out_at IS NULL LIMIT 1`,
    [orgId, userId],
  );
  return result.rows[0] || null;
}

async function ensureFosterProfileForUser(client, userId) {
  const existing = await client.query(
    'SELECT id FROM foster_profiles WHERE user_id = $1',
    [userId],
  );
  if (existing.rows.length > 0) return existing.rows[0].id;
  const userResult = await client.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  const user = userResult.rows[0] || {};
  return createFosterProfileForManualParent(client, {
    userId,
    displayName: userDisplayName(user),
    email: user.email,
    phone: null,
    fosterAddress: '',
  });
}

async function createMemberFosterRelationship(client, {
  orgId, userId, actorUserId, fosterProfileId,
}) {
  const retentionCategory = defaultRetentionCategoryForParent({
    approvalState: 'under_review',
    creationSource: CREATION_SOURCE_INVITE,
    userId,
  });
  const id = uuidv4();
  const result = await client.query(
    `INSERT INTO org_foster_parents (
       id, organization_id, user_id, display_name, email,
       approval_state, creation_source, foster_profile_id, retention_category,
       lawful_basis_attested_at, lawful_basis_attested_by
     )
     SELECT $1, $2, u.id,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')),
            u.email, 'under_review', $3, $4, $5, NOW(), $6
     FROM users u WHERE u.id = $7
     RETURNING *`,
    [id, orgId, CREATION_SOURCE_INVITE, fosterProfileId, retentionCategory, actorUserId, userId],
  );
  return result.rows[0];
}

async function createExternalFosterByEmail(client, { orgId, email, actorUserId }) {
  const fosterProfileId = await createFosterProfileForManualParent(client, {
    displayName: email,
    email,
    phone: null,
    fosterAddress: '',
  });
  const retentionCategory = defaultRetentionCategoryForParent({
    approvalState: 'under_review',
    creationSource: CREATION_SOURCE_INVITE,
    userId: null,
  });
  const id = uuidv4();
  const result = await client.query(
    `INSERT INTO org_foster_parents (
       id, organization_id, display_name, email,
       approval_state, creation_source, foster_profile_id, retention_category,
       lawful_basis_attested_at, lawful_basis_attested_by
     ) VALUES ($1, $2, $3, $4, 'under_review', $5, $6, $7, NOW(), $8)
     RETURNING *`,
    [id, orgId, email, email, CREATION_SOURCE_INVITE, fosterProfileId, retentionCategory, actorUserId],
  );
  return result.rows[0];
}

async function sendFosterInAppNotification(pool, { targetUserId, orgId, orgName }) {
  await createNotification(pool, {
    userId: targetUserId,
    organizationId: orgId,
    title: `Foster for ${orgName}`,
    message: `${orgName} invited you to begin fostering.`,
    type: 'fosterInvitationReceived',
  });
}

export async function fosterInviteByUserId(pool, {
  orgId, actorUserId, targetUserId, locale, req,
}) {
  const member = await pool.query(
    'SELECT 1 FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, targetUserId],
  );
  if (member.rows.length === 0) {
    return { error: 'User is not a member of this organisation', status: 404 };
  }
  if (await isOrgFosterParent(pool, orgId, targetUserId)) {
    return { error: 'User is already a foster for this organisation', status: 409 };
  }
  if (await findExistingFosterRelationship(pool, orgId, targetUserId)) {
    return { error: 'Foster onboarding already in progress', status: 409 };
  }

  const client = await pool.connect();
  let row;
  try {
    await client.query('BEGIN');
    const fosterProfileId = await ensureFosterProfileForUser(client, targetUserId);
    row = await createMemberFosterRelationship(client, {
      orgId, userId: targetUserId, actorUserId, fosterProfileId,
    });
    await client.query('COMMIT');
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    throw err;
  } finally {
    client.release();
  }

  const org = await loadOrgContext(pool, orgId);
  await sendFosterInAppNotification(pool, { targetUserId, orgId, orgName: org.name });

  logAuditEventSafe(pool, {
    actorUserId,
    action: 'foster_invite_sent',
    resourceType: 'shelter_foster_relationship',
    resourceId: row.id,
    orgId,
    metadata: { channel: 'in_app', target_user_id: targetUserId },
    req,
  });

  return {
    status: 201,
    foster_parent_id: row.id,
    user_id: targetUserId,
    channel: 'in_app',
    approval_state: 'under_review',
  };
}

export async function fosterInviteByEmail(pool, {
  orgId, actorUserId, email, locale, req,
}) {
  const normalizedEmail = (email || '').trim().toLowerCase();
  if (!normalizedEmail) return { error: 'Email is required', status: 400 };

  const userResult = await pool.query(
    'SELECT id FROM users WHERE LOWER(email) = $1',
    [normalizedEmail],
  );

  if (userResult.rows.length > 0) {
    const targetUserId = userResult.rows[0].id;
    const member = await pool.query(
      'SELECT 1 FROM organization_users WHERE organization_id = $1 AND user_id = $2',
      [orgId, targetUserId],
    );
    if (member.rows.length === 0) {
      if (await findExistingFosterRelationship(pool, orgId, targetUserId)) {
        return { error: 'Foster onboarding already in progress', status: 409 };
      }
      const client = await pool.connect();
      let row;
      try {
        await client.query('BEGIN');
        const fosterProfileId = await ensureFosterProfileForUser(client, targetUserId);
        row = await createMemberFosterRelationship(client, {
          orgId, userId: targetUserId, actorUserId, fosterProfileId,
        });
        await client.query('COMMIT');
      } catch (err) {
        try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
        throw err;
      } finally {
        client.release();
      }
      const org = await loadOrgContext(pool, orgId);
      await sendFosterInAppNotification(pool, {
        targetUserId, orgId, orgName: org.name,
      });
      return {
        status: 201,
        foster_parent_id: row.id,
        user_id: targetUserId,
        channel: 'in_app',
        approval_state: 'under_review',
      };
    }
    return fosterInviteByUserId(pool, {
      orgId, actorUserId, targetUserId, locale, req,
    });
  }

  const externalDup = await pool.query(
    `SELECT id FROM org_foster_parents
     WHERE organization_id = $1 AND LOWER(email) = $2 AND opt_out_at IS NULL LIMIT 1`,
    [orgId, normalizedEmail],
  );
  if (externalDup.rows.length > 0) {
    return { error: 'A foster record with this email already exists', status: 409 };
  }

  const client = await pool.connect();
  let row;
  try {
    await client.query('BEGIN');
    row = await createExternalFosterByEmail(client, {
      orgId, email: normalizedEmail, actorUserId,
    });
    await client.query('COMMIT');
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    throw err;
  } finally {
    client.release();
  }

  const org = await loadOrgContext(pool, orgId);
  const inviter = await loadInviterContext(pool, orgId, actorUserId);
  try {
    const { subject, text, html } = await buildFosterInvitationNewUserEmail(pool, {
      orgId,
      locale: resolveEmailLocale(locale),
      orgName: org.name,
      orgDescription: org.bio || '',
      orgContactEmail: org.email || '',
      orgLogoUrl: org.logoUrl || '',
      inviterName: inviter.name,
      inviterRole: inviter.role,
    });
    await sendTransactionalEmail({ to: normalizedEmail, subject, text, html });
  } catch (mailErr) {
    console.error('Foster invitation email failed:', mailErr);
  }

  logAuditEventSafe(pool, {
    actorUserId,
    action: 'foster_invite_sent',
    resourceType: 'shelter_foster_relationship',
    resourceId: row.id,
    orgId,
    metadata: { channel: 'email', email: normalizedEmail },
    req,
  });

  return {
    status: 201,
    foster_parent_id: row.id,
    email: normalizedEmail,
    channel: 'email',
    approval_state: 'under_review',
  };
}

export async function fosterInviteByUserIds(pool, {
  orgId, actorUserId, userIds, locale, req,
}) {
  const ids = [...new Set((userIds || []).filter(Boolean))];
  if (ids.length === 0) return { error: 'user_ids is required', status: 400 };

  const results = [];
  const errors = [];
  for (const targetUserId of ids) {
    const result = await fosterInviteByUserId(pool, {
      orgId, actorUserId, targetUserId, locale, req,
    });
    if (result.error) errors.push({ user_id: targetUserId, error: result.error });
    else results.push(result);
  }

  if (results.length === 0) {
    return { error: errors[0]?.error || 'No invites sent', status: 409, errors };
  }
  return { status: 201, invited: results, errors };
}
