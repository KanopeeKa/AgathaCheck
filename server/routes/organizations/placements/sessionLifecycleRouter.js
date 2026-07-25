import { normalizeCalendarDateInput } from '../../../lib/calendarDate.js';
import {
  auditFosteringSession,
  AUDIT_FOSTERING_SESSION_CREATED,
  AUDIT_SESSION_RETURN_CONFIRMED,
  AUDIT_SESSION_START_CONFIRMED_FOSTER,
  AUDIT_SESSION_START_CONFIRMED_SHELTER,
  completeSessionEnd,
  confirmFosterSessionStart,
  confirmShelterSessionStart,
  requestSessionEnd,
  sessionStatusFromPlacement,
  transitionSessionStatus,
} from '../../../lib/fosterSessions.js';
import {
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
  SESSION_STATUS_RETURNED_TO_SHELTER,
} from '../../../lib/fosterPlacements.js';
import { extractUserId, requireMember, requireOrgAdmin } from '../shared.js';
import { publicError } from '../../../config/security.js';
import { queryPlacementDetailById } from './shared.js';

const TRANSITION_TARGETS = new Set([
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
]);

async function loadPlacementForOrg(pool, placementId, orgId) {
  const placementResult = await pool.query(
    'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
    [placementId, orgId],
  );
  return placementResult.rows[0] ?? null;
}

async function respondWithPlacementDetail(pool, res, placementId, statusCode = 200) {
  const detail = await queryPlacementDetailById(pool, placementId);
  if (!detail) {
    return res.status(404).json({ error: 'Placement not found' });
  }
  return res.status(statusCode).json(detail);
}

export function registerPlacementSessionLifecycleRoutes(router, pool) {
  router.post('/:orgId/placements/:id/transition', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const targetStatus = data.session_status || data.sessionStatus;

    if (!TRANSITION_TARGETS.has(targetStatus)) {
      return res.status(400).json({
        error: 'session_status must be preparation or ready_to_start',
      });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await transitionSessionStatus(pool, placement, targetStatus);
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      return respondWithPlacementDetail(pool, res, placementId);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/confirm-shelter-start', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await confirmShelterSessionStart(pool, placement, {
        actorUserId: userId,
        req,
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      return respondWithPlacementDetail(pool, res, placementId);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/confirm-foster-start', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireMember(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await confirmFosterSessionStart(pool, placement, userId, { req });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      return respondWithPlacementDetail(pool, res, placementId);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/request-end', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await requestSessionEnd(pool, placement);
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      return respondWithPlacementDetail(pool, res, placementId);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/end-session', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const outcome = data.outcome || data.session_status || data.sessionStatus;
    const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

    if (![SESSION_STATUS_RETURNED_TO_SHELTER, SESSION_STATUS_CANCELLED].includes(outcome)) {
      return res.status(400).json({
        error: 'outcome must be returned_to_shelter or cancelled',
      });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await completeSessionEnd(pool, placement, outcome, endDate, {
        actorUserId: userId,
        req,
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      return respondWithPlacementDetail(pool, res, placementId);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}

export {
  AUDIT_FOSTERING_SESSION_CREATED,
  AUDIT_SESSION_RETURN_CONFIRMED,
  AUDIT_SESSION_START_CONFIRMED_FOSTER,
  AUDIT_SESSION_START_CONFIRMED_SHELTER,
  auditFosteringSession,
  sessionStatusFromPlacement,
};
