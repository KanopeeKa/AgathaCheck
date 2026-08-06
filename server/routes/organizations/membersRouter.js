import { v4 as uuidv4 } from 'uuid';
import { publicError } from '../../config/security.js';
import {
  ASSIGNABLE_ROLES,
  ORG_ROLE_ADMIN,
  canAssignRole,
  normaliseRole,
} from '../../lib/orgRoles.js';
import {
  getOrgPersonDetail,
  listOrgPeople,
  updateOrgPersonContact,
} from '../../lib/orgPeople.js';
import { extractUserId, requireOrgAdmin, requirePermission } from './shared.js';
import { loadActivePermissionKeys } from '../../lib/orgPermissions.js';
import {
  buildFosterOnboardingTimeline,
  confirmFosterOnboardingStep,
  requireFosterOnboardingReviewPermission,
} from './fosterOnboarding.js';

export function registerMembersRoutes(router, pool) {
    router.get('/:orgId/members', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
        const result = await pool.query(
          `SELECT ou.id, ou.role, ou.created_at, u.id as user_id, u.email, u.first_name, u.last_name, u.photo_url
           FROM organization_users ou
           JOIN users u ON u.id = ou.user_id
           WHERE ou.organization_id = $1
           ORDER BY ou.created_at`,
          [req.params.orgId]
        );
        res.json(result.rows.map(r => ({
          id: r.id,
          user_id: r.user_id,
          email: r.email,
          first_name: r.first_name,
          last_name: r.last_name,
          photo_url: r.photo_url,
          role: normaliseRole(r.role),
          created_at: r.created_at,
        })));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/people', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      try {
        const role = await requirePermission(pool, res, orgId, userId, 'view_admin_contacts');
        if (!role) return;
        const permissionKeys = await loadActivePermissionKeys(pool, orgId, userId);
        const viewer = { userId, role, permissionKeys };
        const people = await listOrgPeople(pool, orgId, viewer);
        res.json(people);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/people/:kind/:personId', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, kind, personId } = req.params;
      if (kind !== 'member' && kind !== 'external') {
        return res.status(400).json({ error: 'Invalid person kind' });
      }
      try {
        const role = await requirePermission(pool, res, orgId, userId, 'view_admin_contacts');
        if (!role) return;
        const permissionKeys = await loadActivePermissionKeys(pool, orgId, userId);
        const viewer = { userId, role, permissionKeys };
        const detail = await getOrgPersonDetail(pool, orgId, kind, personId, viewer);
        if (!detail) return res.status(404).json({ error: 'Person not found' });
        const fosterOnboarding = await buildFosterOnboardingTimeline(pool, orgId, kind, personId);
        if (fosterOnboarding) detail.foster_onboarding = fosterOnboarding;
        res.json(detail);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post(
      '/:orgId/people/:kind/:personId/foster-onboarding/steps/:stepKey/confirm',
      async (req, res) => {
        const userId = extractUserId(req);
        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        const { orgId, kind, personId, stepKey } = req.params;
        if (kind !== 'member' && kind !== 'external') {
          return res.status(400).json({ error: 'Invalid person kind' });
        }
        try {
          if (!(await requireFosterOnboardingReviewPermission(pool, res, orgId, userId))) return;
          const result = await confirmFosterOnboardingStep(pool, orgId, kind, personId, stepKey, userId, req);
          res.json(result);
        } catch (err) {
          if (err.statusCode === 400) return res.status(400).json({ error: err.message });
          if (err.statusCode === 404) return res.status(404).json({ error: err.message });
          res.status(500).json({ error: publicError(err) });
        }
      },
    );

    router.put('/:orgId/people/:kind/:personId/contact', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const { orgId, kind, personId } = req.params;
      if (kind !== 'member' && kind !== 'external') {
        return res.status(400).json({ error: 'Invalid person kind' });
      }
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
        await updateOrgPersonContact(pool, orgId, kind, personId, req.body || {});
        const detail = await getOrgPersonDetail(pool, orgId, kind, personId);
        if (!detail) return res.status(404).json({ error: 'Person not found' });
        const fosterOnboarding = await buildFosterOnboardingTimeline(pool, orgId, kind, personId);
        if (fosterOnboarding) detail.foster_onboarding = fosterOnboarding;
        res.json(detail);
      } catch (err) {
        if (err.statusCode === 400) {
          return res.status(400).json({ error: err.message });
        }
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:id/invite', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const actorRole = await requireOrgAdmin(pool, res, req.params.id, userId);
        if (!actorRole) return;
        const { email, role = ORG_ROLE_ADMIN } = req.body;
        if (!email) {
          return res.status(400).json({ error: 'Email is required' });
        }
        if (!ASSIGNABLE_ROLES.includes(role)) {
          return res.status(400).json({ error: 'Invalid role' });
        }
        if (!canAssignRole(actorRole, role)) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
          return res.status(404).json({ error: 'User not found' });
        }
        const invitedUserId = userResult.rows[0].id;
        const pendingRole = `pending_${role}`;
        const id = uuidv4();
        await pool.query(
          'INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, $4) ON CONFLICT (organization_id, user_id) DO UPDATE SET role = $4',
          [id, req.params.id, invitedUserId, pendingRole]
        );
        res.json({ success: true, user_id: invitedUserId });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.put('/:orgId/members/:userId/role', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const actorRole = await requireOrgAdmin(pool, res, req.params.orgId, userId);
        if (!actorRole) return;
        const { role } = req.body;
        if (!ASSIGNABLE_ROLES.includes(role)) {
          return res.status(400).json({ error: 'Invalid role' });
        }
        if (!canAssignRole(actorRole, role)) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        const result = await pool.query(
          'UPDATE organization_users SET role = $1 WHERE organization_id = $2 AND user_id = $3 RETURNING *',
          [role, req.params.orgId, req.params.userId]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Member not found' });
        const row = result.rows[0];
        res.json({ ...row, role: normaliseRole(row.role) });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.delete('/:orgId/members/me', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, userId]);
        res.json({ message: 'Left organization' });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.delete('/:orgId/members/:userId', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
        await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, req.params.userId]);
        res.json({ message: 'Member removed' });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });
}
