import {
  addHomeVisitPhoto,
  cancelHomeVisit,
  loadHomeVisitsForFosterParent,
  requireHomeVisitsPermission,
  rescheduleHomeVisit,
  scheduleHomeVisit,
  updateHomeVisitChecklist,
  validateHomeVisit,
  visitToExportMap,
  visitToMap,
} from '../../lib/fosterHomeVisits.js';
import { resolveFosterParentForUser } from '../../lib/fosterQuestionnaire.js';
import { requireFosterOnboardingReviewPermission } from './fosterOnboarding.js';
import { extractUserId, requireMember } from './shared.js';
import { publicError } from '../../config/security.js';

function apiError(res, result) {
  return res.status(result.status).json({ error: result.error });
}

async function requireCandidateFosterParent(pool, res, orgId, userId) {
  const role = await requireMember(pool, res, orgId, userId);
  if (!role) return null;
  const fosterParent = await resolveFosterParentForUser(pool, orgId, userId);
  if (!fosterParent) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return fosterParent;
}

export function registerFosterHomeVisitsRoutes(router, pool) {
  router.get('/:orgId/foster-home-visits/:fosterParentId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, fosterParentId } = req.params;

    try {
      if (!(await requireFosterOnboardingReviewPermission(pool, res, orgId, userId))) return;

      const result = await loadHomeVisitsForFosterParent(pool, orgId, fosterParentId);
      if (result.error) return apiError(res, result);

      res.json({
        visits: result.visits.map((row) => visitToMap(row)),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/foster-home-visits/:fosterParentId/status', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, fosterParentId } = req.params;

    try {
      const fosterParent = await requireCandidateFosterParent(pool, res, orgId, userId);
      if (!fosterParent) return;
      if (fosterParent.id !== fosterParentId) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const result = await loadHomeVisitsForFosterParent(pool, orgId, fosterParentId);
      if (result.error) return apiError(res, result);

      const active = result.visits.find((v) => v.status === 'scheduled') || null;
      const latestValidated = result.visits.find((v) => v.status === 'validated') || null;

      res.json({
        active_visit: active ? visitToExportMap(active) : null,
        latest_validated: latestValidated ? visitToExportMap(latestValidated) : null,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-home-visits/:fosterParentId/schedule', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, fosterParentId } = req.params;
    const data = req.body || {};

    try {
      if (!(await requireHomeVisitsPermission(pool, res, orgId, userId))) return;

      const result = await scheduleHomeVisit(pool, {
        orgId,
        fosterParentId,
        visitDate: data.visit_date || data.visitDate,
        visitTime: data.visit_time || data.visitTime,
        address: data.address,
        notes: data.notes,
        attendees: data.attendees,
        actorUserId: userId,
        req,
      });
      if (result.error) return apiError(res, result);

      res.status(result.status).json({ visit: visitToMap(result.visit) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:orgId/foster-home-visits/:visitId/reschedule', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, visitId } = req.params;
    const data = req.body || {};

    try {
      if (!(await requireHomeVisitsPermission(pool, res, orgId, userId))) return;

      const result = await rescheduleHomeVisit(pool, {
        orgId,
        visitId,
        visitDate: data.visit_date || data.visitDate,
        visitTime: data.visit_time || data.visitTime,
        address: data.address,
        notes: data.notes,
        attendees: data.attendees,
        actorUserId: userId,
        req,
      });
      if (result.error) return apiError(res, result);

      res.status(result.status).json({ visit: visitToMap(result.visit) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-home-visits/:visitId/cancel', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, visitId } = req.params;
    const data = req.body || {};

    try {
      if (!(await requireHomeVisitsPermission(pool, res, orgId, userId))) return;

      const result = await cancelHomeVisit(pool, {
        orgId,
        visitId,
        cancelReason: data.cancel_reason || data.cancelReason,
        actorUserId: userId,
        req,
      });
      if (result.error) return apiError(res, result);

      res.json({ visit: visitToMap(result.visit) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:orgId/foster-home-visits/:visitId/checklist', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, visitId } = req.params;
    const data = req.body || {};

    try {
      if (!(await requireHomeVisitsPermission(pool, res, orgId, userId))) return;

      const result = await updateHomeVisitChecklist(pool, {
        orgId,
        visitId,
        checklistItems: data.checklist_items || data.checklistItems,
        notes: data.notes,
      });
      if (result.error) return apiError(res, result);

      res.json({ visit: visitToMap(result.visit) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-home-visits/:visitId/photos', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, visitId } = req.params;
    const data = req.body || {};

    try {
      if (!(await requireHomeVisitsPermission(pool, res, orgId, userId))) return;

      const result = await addHomeVisitPhoto(pool, {
        orgId,
        visitId,
        storagePath: data.storage_path || data.storagePath,
        caption: data.caption,
        actorUserId: userId,
      });
      if (result.error) return apiError(res, result);

      res.status(result.status).json({ visit: visitToMap(result.visit) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-home-visits/:visitId/validate', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, visitId } = req.params;
    const data = req.body || {};

    try {
      const result = await validateHomeVisit(pool, {
        orgId,
        visitId,
        outcome: data.outcome,
        outcomeReason: data.outcome_reason || data.outcomeReason,
        actorUserId: userId,
        req,
      });
      if (result.error) return apiError(res, result);

      res.json({ visit: visitToMap(result.visit) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
