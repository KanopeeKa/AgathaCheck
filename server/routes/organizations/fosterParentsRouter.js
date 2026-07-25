import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from '../../lib/audit.js';
import { buildExternalFosterNoticeEmail } from '../../lib/email/templates/externalFosterNotice.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import { OPEN_PLACEMENT_STATUSES } from '../../lib/fosterPlacements.js';
import { fosterParentMemberRolesSql, normaliseRole } from '../../lib/orgRoles.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

const APPROVAL_STATES = new Set(['under_review', 'approved', 'declined', 'archived']);
const MEMBER_APPROVAL_STATE = 'approved';
const MEMBER_CREATION_SOURCE = 'member';

export function registerFosterParentsRoutes(router, pool) {
    function fosterParentToMap(row, { kind = row.kind } = {}) {
      const displayName = (row.display_name || '').trim();
      let activePets = row.active_pets || [];
      if (typeof activePets === 'string') {
        try {
          activePets = JSON.parse(activePets);
        } catch (_) {
          activePets = [];
        }
      }
      const isMember = kind === 'member';
      return {
        id: row.id,
        kind,
        user_id: row.user_id || null,
        display_name: displayName || row.email || '',
        email: row.email || null,
        phone: row.phone || null,
        foster_address: row.foster_address || '',
        notes: row.notes || '',
        role: row.role ? normaliseRole(row.role) : null,
        photo_url: row.photo_url || null,
        active_pet_count: parseInt(row.active_pet_count, 10) || 0,
        active_pets: activePets,
        approval_state: isMember
          ? MEMBER_APPROVAL_STATE
          : (row.approval_state || 'approved'),
        creation_source: isMember
          ? MEMBER_CREATION_SOURCE
          : (row.creation_source || 'manual_shelter_entry'),
      };
    }

    router.get('/:orgId/foster-parents', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const memberResult = await pool.query(
          `SELECT ou.id,
                  'member' AS kind,
                  u.id AS user_id,
                  TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
                  u.email,
                  u.photo_url,
                  ou.role,
                  NULL::varchar AS phone,
                  ''::text AS notes,
                  (
                    SELECT COUNT(DISTINCT fpl.pet_id)::int
                    FROM foster_placements fpl
                    WHERE fpl.organization_id = ou.organization_id
                      AND fpl.foster_user_id = u.id
                      AND fpl.status = ANY($2::text[])
                  ) AS active_pet_count,
                  (
                    SELECT COALESCE(json_agg(json_build_object(
                      'pet_id', p.id,
                      'pet_name', p.name,
                      'status', fpl.status
                    ) ORDER BY p.name), '[]'::json)
                    FROM foster_placements fpl
                    JOIN pets p ON p.id = fpl.pet_id
                    WHERE fpl.organization_id = ou.organization_id
                      AND fpl.foster_user_id = u.id
                      AND fpl.status = ANY($2::text[])
                  ) AS active_pets
           FROM organization_users ou
           JOIN users u ON u.id = ou.user_id
           WHERE ou.organization_id = $1
             AND ou.role IN (${fosterParentMemberRolesSql()})
           ORDER BY display_name, u.email`,
          [orgId, OPEN_PLACEMENT_STATUSES],
        );

        const externalResult = await pool.query(
          `SELECT fp.id,
                  'external' AS kind,
                  fp.user_id,
                  fp.display_name,
                  fp.email,
                  NULL AS photo_url,
                  NULL AS role,
                  fp.phone,
                  fp.notes,
                  fp.approval_state,
                  fp.creation_source,
                  (
                    SELECT COUNT(DISTINCT fpl.pet_id)::int
                    FROM foster_placements fpl
                    WHERE fpl.organization_id = fp.organization_id
                      AND fpl.org_foster_parent_id = fp.id
                      AND fpl.status = ANY($2::text[])
                  ) AS active_pet_count,
                  (
                    SELECT COALESCE(json_agg(json_build_object(
                      'pet_id', p.id,
                      'pet_name', p.name,
                      'status', fpl.status
                    ) ORDER BY p.name), '[]'::json)
                    FROM foster_placements fpl
                    JOIN pets p ON p.id = fpl.pet_id
                    WHERE fpl.organization_id = fp.organization_id
                      AND fpl.org_foster_parent_id = fp.id
                      AND fpl.status = ANY($2::text[])
                  ) AS active_pets
           FROM org_foster_parents fp
           WHERE fp.organization_id = $1
           ORDER BY fp.display_name`,
          [orgId, OPEN_PLACEMENT_STATUSES],
        );

        const combined = [
          ...memberResult.rows.map((row) => fosterParentToMap(row, { kind: 'member' })),
          ...externalResult.rows.map((row) => fosterParentToMap(row, { kind: 'external' })),
        ].sort((a, b) => a.display_name.localeCompare(b.display_name, undefined, { sensitivity: 'base' }));

        res.json(combined);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/:orgId/foster-parents', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      const data = req.body || {};
      const displayName = (data.display_name || data.displayName || '').trim();
      const email = (data.email || '').trim() || null;
      const phone = (data.phone || '').trim() || null;
      const fosterAddress = (data.foster_address || data.fosterAddress || '').trim();
      const notes = (data.notes || '').trim();
      const lawfulBasisConfirmed = data.lawful_basis_confirmed === true
        || data.lawfulBasisConfirmed === true;

      if (!displayName) {
        return res.status(400).json({ error: 'Display name is required' });
      }
      if (!lawfulBasisConfirmed) {
        return res.status(400).json({ error: 'Lawful basis confirmation is required' });
      }
      if (!email) {
        return res.status(400).json({ error: 'Email is required for external foster contacts' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const orgResult = await pool.query(
          'SELECT name FROM organizations WHERE id = $1',
          [orgId],
        );
        const orgName = orgResult.rows[0]?.name || 'Your organisation';

        const id = uuidv4();
        const result = await pool.query(
          `INSERT INTO org_foster_parents (
             id, organization_id, display_name, email, phone, foster_address, notes,
             lawful_basis_attested_at, lawful_basis_attested_by,
             approval_state, creation_source
           ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), $8, 'under_review', 'manual_shelter_entry')
           RETURNING *`,
          [id, orgId, displayName, email, phone, fosterAddress, notes, userId],
        );
        const row = result.rows[0];

        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'manual_foster_record_created',
          resourceType: 'shelter_foster_relationship',
          resourceId: id,
          orgId,
          metadata: { creation_source: 'manual_shelter_entry', approval_state: 'under_review' },
          req,
        });

        try {
          const locale = resolveEmailLocale(data.locale);
          const { subject, text, html } = buildExternalFosterNoticeEmail({
            locale,
            orgName,
          });
          await sendTransactionalEmail({ to: email, subject, text, html });
        } catch (mailErr) {
          console.error('External foster notice email failed:', mailErr);
        }

        res.status(201).json(fosterParentToMap({
          ...row,
          kind: 'external',
          photo_url: null,
          role: null,
          active_pet_count: 0,
          active_pets: [],
        }, { kind: 'external' }));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.patch('/:orgId/foster-parents/:id/approval', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      const fosterParentId = req.params.id;
      const data = req.body || {};
      const approvalState = (data.approval_state || data.approvalState || '').trim();

      if (!APPROVAL_STATES.has(approvalState)) {
        return res.status(400).json({ error: 'Invalid approval_state' });
      }
      if (approvalState === 'under_review') {
        return res.status(400).json({ error: 'Cannot set approval_state to under_review' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const result = await pool.query(
          `UPDATE org_foster_parents
           SET approval_state = $1, updated_at = NOW()
           WHERE id = $2 AND organization_id = $3
           RETURNING *`,
          [approvalState, fosterParentId, orgId],
        );
        if (result.rows.length === 0) {
          return res.status(404).json({ error: 'Foster parent not found' });
        }

        const auditActionByState = {
          approved: 'foster_approval_granted',
          declined: 'foster_approval_declined',
          archived: 'foster_archived',
        };
        const auditAction = auditActionByState[approvalState];
        if (auditAction) {
          logAuditEventSafe(pool, {
            actorUserId: userId,
            action: auditAction,
            resourceType: 'shelter_foster_relationship',
            resourceId: fosterParentId,
            orgId,
            metadata: { approval_state: approvalState },
            req,
          });
        }

        const row = result.rows[0];
        res.json(fosterParentToMap({
          ...row,
          kind: 'external',
          photo_url: null,
          role: null,
          active_pet_count: 0,
          active_pets: [],
        }, { kind: 'external' }));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.put('/:orgId/foster-parents/:id', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      const fosterParentId = req.params.id;
      const data = req.body || {};
      const displayName = (data.display_name || data.displayName || '').trim();
      const email = (data.email || '').trim() || null;
      const phone = (data.phone || '').trim() || null;
      const fosterAddress = (data.foster_address || data.fosterAddress || '').trim();
      const notes = (data.notes || '').trim();

      if (!displayName) {
        return res.status(400).json({ error: 'Display name is required' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const result = await pool.query(
          `UPDATE org_foster_parents
           SET display_name = $1, email = $2, phone = $3, foster_address = $4, notes = $5, updated_at = NOW()
           WHERE id = $6 AND organization_id = $7
           RETURNING *`,
          [displayName, email, phone, fosterAddress, notes, fosterParentId, orgId],
        );
        if (result.rows.length === 0) {
          return res.status(404).json({ error: 'Foster parent not found' });
        }
        const row = result.rows[0];
        res.json(fosterParentToMap({
          ...row,
          kind: 'external',
          photo_url: null,
          role: null,
          active_pet_count: 0,
          active_pets: [],
        }, { kind: 'external' }));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.delete('/:orgId/foster-parents/:id', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      const fosterParentId = req.params.id;

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const result = await pool.query(
          'DELETE FROM org_foster_parents WHERE id = $1 AND organization_id = $2 RETURNING id',
          [fosterParentId, orgId],
        );
        if (result.rows.length === 0) {
          return res.status(404).json({ error: 'Foster parent not found' });
        }
        res.json({ deleted: true, id: fosterParentId });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });
}
