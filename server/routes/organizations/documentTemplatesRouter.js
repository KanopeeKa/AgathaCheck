import {
  buildPublicTemplateDownload,
  buildRegisterExport,
  ensureDefaultTemplates,
  groupPublicTemplatesByType,
  listPublicTemplatesForOrg,
  listTemplatesForOrg,
  publicTemplateToMap,
  renderChecklistFromTemplates,
  TEMPLATE_TYPE_ADOPTION_MILESTONE,
  TEMPLATE_TYPE_SESSION_CHECKLIST,
  templateToMap,
  updateJourneyMilestoneItem,
  updateSessionChecklistItem,
} from '../../lib/documentTemplates.js';
import { getJourneyForSession } from '../../lib/adoptionJourneys.js';
import { extractUserId, requireMember, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerDocumentTemplatesRoutes(router, pool) {
  router.get('/:orgId/legal-documents', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;

    try {
      if (!(await requireMember(pool, res, orgId, userId))) return;

      const templates = await listPublicTemplatesForOrg(pool, orgId);
      res.json(groupPublicTemplatesByType(templates));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/legal-documents/:templateId/download', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, templateId } = req.params;

    try {
      if (!(await requireMember(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `SELECT id, template_key, template_type, label, description
         FROM document_templates
         WHERE organization_id = $1
           AND id = $2
           AND is_public = true`,
        [orgId, templateId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Document not found' });
      }

      const template = publicTemplateToMap(result.rows[0]);
      res.json({
        format: 'markdown',
        filename: `${template.template_key}.md`,
        content: buildPublicTemplateDownload(template),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
  router.get('/:orgId/document-templates', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const templateType = (req.query.type || '').trim() || null;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      await ensureDefaultTemplates(pool, orgId);
      if (templateType) {
        const templates = await listTemplatesForOrg(pool, orgId, templateType);
        return res.json(templates);
      }

      const [sessionTemplates, milestoneTemplates] = await Promise.all([
        listTemplatesForOrg(pool, orgId, TEMPLATE_TYPE_SESSION_CHECKLIST),
        listTemplatesForOrg(pool, orgId, TEMPLATE_TYPE_ADOPTION_MILESTONE),
      ]);
      res.json({
        session_checklist: sessionTemplates,
        adoption_milestones: milestoneTemplates,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/placements/:id/session-checklist', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      await ensureDefaultTemplates(pool, orgId);
      const [templates, placementResult] = await Promise.all([
        listTemplatesForOrg(pool, orgId, TEMPLATE_TYPE_SESSION_CHECKLIST),
        pool.query(
          `SELECT session_checklist_items
           FROM foster_placements
           WHERE id = $1 AND organization_id = $2`,
          [placementId, orgId],
        ),
      ]);
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const items = renderChecklistFromTemplates(
        templates,
        placementResult.rows[0].session_checklist_items,
      );
      res.json({ items, templates: templates.map(templateToMap) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:orgId/placements/:id/session-checklist/:itemKey', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId, itemKey } = req.params;
    const completed = req.body?.completed === true;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await updateSessionChecklistItem(pool, {
        placementId,
        orgId,
        itemKey,
        completed,
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }
      res.json({ items: result.items });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/placements/:id/adoption-milestones', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      await ensureDefaultTemplates(pool, orgId);
      const journey = await getJourneyForSession(pool, placementId);
      if (!journey) {
        return res.status(404).json({ error: 'Adoption journey not found' });
      }

      const templates = await listTemplatesForOrg(pool, orgId, TEMPLATE_TYPE_ADOPTION_MILESTONE);
      const items = renderChecklistFromTemplates(templates, journey.milestone_items);
      res.json({
        journey_id: journey.id,
        items,
        templates: templates.map(templateToMap),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:orgId/adoption-journeys/:journeyId/milestones/:itemKey', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, journeyId, itemKey } = req.params;
    const completed = req.body?.completed === true;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await updateJourneyMilestoneItem(pool, {
        journeyId,
        orgId,
        itemKey,
        completed,
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }
      res.json({ items: result.items });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/placements/:id/register-export', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      await ensureDefaultTemplates(pool, orgId);
      const placementResult = await pool.query(
        `SELECT fp.id,
                fp.session_checklist_items,
                p.name AS pet_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         LEFT JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.id = $1 AND fp.organization_id = $2`,
        [placementId, orgId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      const orgResult = await pool.query(
        'SELECT name FROM organizations WHERE id = $1',
        [orgId],
      );
      const journey = await getJourneyForSession(pool, placementId);
      const [sessionTemplates, milestoneTemplates] = await Promise.all([
        listTemplatesForOrg(pool, orgId, TEMPLATE_TYPE_SESSION_CHECKLIST),
        listTemplatesForOrg(pool, orgId, TEMPLATE_TYPE_ADOPTION_MILESTONE),
      ]);

      const markdown = buildRegisterExport({
        orgName: orgResult.rows[0]?.name || 'Organisation',
        sessionTemplates,
        sessionItems: placement.session_checklist_items,
        milestoneTemplates,
        milestoneItems: journey?.milestone_items || {},
        petName: placement.pet_name,
        fosterName: (placement.foster_name || '').trim() || 'Foster',
      });
      res.json({ format: 'markdown', content: markdown });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
