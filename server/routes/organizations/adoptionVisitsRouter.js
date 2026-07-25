import {
  createAdoptionVisit,
  recordVisitOutcome,
  validateAdoptionVisit,
  validateCreateVisitPayload,
  visitToMap,
} from '../../lib/adoptionVisits.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerAdoptionVisitsRoutes(router, pool) {
  router.get('/:orgId/adoption-visits', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `SELECT *
         FROM adoption_visits
         WHERE organization_id = $1
         ORDER BY scheduled_at DESC`,
        [orgId],
      );
      res.json(result.rows.map((row) => visitToMap(row)));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/adoption-visits', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const validation = validateCreateVisitPayload(req.body || {});
    if (validation.error) {
      return res.status(400).json({ error: validation.error });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await createAdoptionVisit(pool, {
        orgId,
        prospectId: validation.prospectId,
        fosteringSessionId: validation.fosteringSessionId,
        petId: validation.petId,
        scheduledAt: validation.scheduledAt,
        assignedFosterParentId: validation.assignedFosterParentId,
        createdBy: userId,
        auditContext: { req },
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }
      res.status(result.status).json(visitToMap(result.row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/adoption-visits/:id/outcome', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: visitId } = req.params;
    const data = req.body || {};
    const outcome = (data.outcome || '').trim();
    const outcomeNotes = (data.outcome_notes || data.outcomeNotes || '').trim();

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await recordVisitOutcome(pool, {
        orgId,
        visitId,
        outcome,
        outcomeNotes,
        actorUserId: userId,
        auditContext: { req },
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }
      res.json(visitToMap(result.row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/adoption-visits/:id/validate', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: visitId } = req.params;
    const data = req.body || {};
    const validationStatus = (data.validation_status || data.validationStatus || '').trim();

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await validateAdoptionVisit(pool, {
        orgId,
        visitId,
        validationStatus,
        actorUserId: userId,
        auditContext: { req },
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }
      res.json(visitToMap(result.row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
