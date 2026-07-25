import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from '../../lib/audit.js';
import { buildExternalProspectNoticeEmail } from '../../lib/email/templates/externalProspectNotice.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import {
  defaultRetentionCategoryForProspect,
  findProspectMergeSuggestionsByEmail,
  mergeProspectIntoUser,
  prospectToMap,
} from '../../lib/prospects.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerProspectsRoutes(router, pool) {
  router.get('/:orgId/prospects', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `SELECT *
         FROM prospects
         WHERE organization_id = $1
         ORDER BY display_name, email`,
        [orgId],
      );

      res.json(result.rows.map((row) => prospectToMap(row)));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/prospects/merge-suggestions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const email = (req.query.email || '').trim();

    if (!email) {
      return res.status(400).json({ error: 'Email query parameter is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const suggestions = await findProspectMergeSuggestionsByEmail(pool, email);
      res.json(suggestions);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/prospects', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};
    const displayName = (data.display_name || data.displayName || '').trim();
    const email = (data.email || '').trim() || null;
    const phone = (data.phone || '').trim() || null;
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
      return res.status(400).json({ error: 'Email is required for prospect contacts' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const orgResult = await pool.query(
        'SELECT name FROM organizations WHERE id = $1',
        [orgId],
      );
      const orgName = orgResult.rows[0]?.name || 'Your organisation';

      const id = uuidv4();
      const retentionCategory = defaultRetentionCategoryForProspect({ userId: null });
      const result = await pool.query(
        `INSERT INTO prospects (
           id, organization_id, display_name, email, phone, notes,
           lawful_basis_attested_at, lawful_basis_attested_by,
           creation_source, retention_category, created_by
         ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), $7, 'manual_shelter_entry', $8, $7)
         RETURNING *`,
        [id, orgId, displayName, email, phone, notes, userId, retentionCategory],
      );
      const row = result.rows[0];

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'prospect_record_created',
        resourceType: 'prospect',
        resourceId: id,
        orgId,
        metadata: { creation_source: 'manual_shelter_entry' },
        req,
      });

      let noticeSent = false;
      try {
        const locale = resolveEmailLocale(data.locale);
        const { subject, text, html } = buildExternalProspectNoticeEmail({
          locale,
          orgName,
        });
        await sendTransactionalEmail({ to: email, subject, text, html });
        noticeSent = true;
      } catch (mailErr) {
        console.error('External prospect notice email failed:', mailErr);
      }

      if (noticeSent) {
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'indirect_contact_notice_sent',
          resourceType: 'prospect',
          resourceId: id,
          orgId,
          metadata: { channel: 'email', template: 'externalProspectNotice' },
          req,
        });
      }

      res.status(201).json(prospectToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:orgId/prospects/:id/contact', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const prospectId = req.params.id;
    const data = req.body || {};
    const displayName = (data.display_name || data.displayName || '').trim();
    const email = (data.email || '').trim() || null;
    const phone = (data.phone || '').trim() || null;

    if (!displayName) {
      return res.status(400).json({ error: 'Display name is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `UPDATE prospects
         SET display_name = $1, email = $2, phone = $3, updated_at = NOW()
         WHERE id = $4 AND organization_id = $5
         RETURNING *`,
        [displayName, email, phone, prospectId, orgId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Prospect not found' });
      }

      res.json(prospectToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/prospects/:id/merge', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const prospectId = req.params.id;
    const data = req.body || {};
    const targetUserId = (data.target_user_id || data.targetUserId || '').trim();

    if (!targetUserId) {
      return res.status(400).json({ error: 'target_user_id is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const mergeResult = await mergeProspectIntoUser(pool, {
        orgId,
        prospectId,
        targetUserId,
      });

      if (mergeResult.error) {
        const errorMessages = {
          not_found: 'Prospect not found',
          already_linked_to_different_user: 'Prospect is already linked to a different user',
          target_user_not_found: 'Target user not found',
        };
        return res.status(mergeResult.status).json({
          error: errorMessages[mergeResult.error] || mergeResult.error,
        });
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'prospect_merge_completed',
        resourceType: 'prospect',
        resourceId: prospectId,
        orgId,
        metadata: {
          merged_from_id: mergeResult.mergedFromId,
          merged_into_id: mergeResult.mergedIntoUserId,
          target_user_id: targetUserId,
        },
        req,
      });

      res.json(prospectToMap(mergeResult.row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
