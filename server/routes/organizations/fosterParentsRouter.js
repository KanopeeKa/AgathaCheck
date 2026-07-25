import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from '../../lib/audit.js';
import { buildExternalFosterNoticeEmail } from '../../lib/email/templates/externalFosterNotice.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import {
  createFosterProfileForManualParent,
  findMergeSuggestionsByEmail,
  mergeManualFosterIntoUser,
} from '../../lib/fosterProfiles.js';
import {
  defaultRetentionCategoryForParent,
  registerFosterComplianceRoutes,
} from '../../lib/fosterCompliance.js';
import {
  fosterParentToMap,
  loadFosterParentListContext,
} from '../../lib/fosterParentPresenter.js';
import { OPEN_PLACEMENT_STATUSES } from '../../lib/fosterPlacements.js';
import { fosterParentMemberRolesSql } from '../../lib/orgRoles.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

const APPROVAL_STATES = new Set(['under_review', 'approved', 'declined', 'archived']);
const MEMBER_APPROVAL_STATE = 'approved';
const MEMBER_CREATION_SOURCE = 'member';

export function registerFosterParentsRoutes(router, pool) {
    router.get('/:orgId/foster-parents', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const listContext = await loadFosterParentListContext(pool, orgId);

        const memberResult = await pool.query(
          `SELECT ou.id,
                  'member' AS kind,
                  u.id AS user_id,
                  fprof.id AS foster_profile_id,
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
           LEFT JOIN foster_profiles fprof ON fprof.user_id = u.id
           WHERE ou.organization_id = $1
             AND ou.role IN (${fosterParentMemberRolesSql()})
           ORDER BY display_name, u.email`,
          [orgId, OPEN_PLACEMENT_STATUSES],
        );

        const externalResult = await pool.query(
          `SELECT fp.id,
                  'external' AS kind,
                  fp.user_id,
                  fp.foster_profile_id,
                  fp.display_name,
                  fp.opt_out_at,
                  fp.retention_category,
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
          ...memberResult.rows.map((row) => fosterParentToMap(row, {
            kind: 'member',
            profileRow: listContext.profilesByUser.get(row.user_id),
            activityCounts: listContext.activityByUser.get(row.user_id) || {},
            capacityUsage: listContext.usageByUser.get(row.user_id) || {},
          })),
          ...externalResult.rows.map((row) => fosterParentToMap(row, {
            kind: 'external',
            profileRow: listContext.profilesByParent.get(row.id),
            activityCounts: listContext.activityByParent.get(row.id) || {},
            capacityUsage: {},
          })),
        ].sort((a, b) => a.display_name.localeCompare(b.display_name, undefined, { sensitivity: 'base' }));

        res.json(combined);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.get('/:orgId/foster-parents/merge-suggestions', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      const email = (req.query.email || '').trim();

      if (!email) {
        return res.status(400).json({ error: 'Email query parameter is required' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const suggestions = await findMergeSuggestionsByEmail(pool, email, orgId);
        res.json(suggestions);
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
        const client = await pool.connect();
        let row;
        try {
          await client.query('BEGIN');
          const fosterProfileId = await createFosterProfileForManualParent(client, {
            displayName,
            email,
            phone,
            fosterAddress,
          });
          const retentionCategory = defaultRetentionCategoryForParent({
            approvalState: 'under_review',
            creationSource: 'manual_shelter_entry',
            userId: null,
          });
          const result = await client.query(
            `INSERT INTO org_foster_parents (
               id, organization_id, display_name, email, phone, foster_address, notes,
               lawful_basis_attested_at, lawful_basis_attested_by,
               approval_state, creation_source, foster_profile_id, retention_category
             ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), $8, 'under_review', 'manual_shelter_entry', $9, $10)
             RETURNING *`,
            [id, orgId, displayName, email, phone, fosterAddress, notes, userId, fosterProfileId, retentionCategory],
          );
          row = result.rows[0];
          await client.query('COMMIT');
        } catch (txErr) {
          try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
          throw txErr;
        } finally {
          client.release();
        }

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
           SET approval_state = $1::text,
               retention_category = CASE
                 WHEN $1::text IN ('declined', 'archived') THEN 'declined_archived'
                 ELSE retention_category
               END,
               updated_at = NOW()
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

    registerFosterComplianceRoutes(router, {
      pool,
      extractUserId,
      requireOrgAdmin,
      logAuditEventSafe,
      fosterParentToMap,
      publicError,
    });

    router.post('/:orgId/foster-parents/:id/merge', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const orgId = req.params.orgId;
      const fosterParentId = req.params.id;
      const data = req.body || {};
      const targetUserId = (data.target_user_id || data.targetUserId || '').trim();

      if (!targetUserId) {
        return res.status(400).json({ error: 'target_user_id is required' });
      }

      try {
        if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

        const mergeResult = await mergeManualFosterIntoUser(pool, {
          orgId,
          fosterParentId,
          targetUserId,
          actorUserId: userId,
        });

        if (mergeResult.error) {
          return res.status(mergeResult.status).json({ error: mergeResult.error });
        }

        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'foster_merge_completed',
          resourceType: 'foster_profile',
          resourceId: mergeResult.survivorProfileId,
          orgId,
          metadata: {
            merged_from_id: mergeResult.mergedFromProfileId,
            merged_into_id: mergeResult.survivorProfileId,
            merged_from_relationship_id: mergeResult.mergedFromRelationshipId,
            target_user_id: targetUserId,
          },
          req,
        });

        const row = mergeResult.row;
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
