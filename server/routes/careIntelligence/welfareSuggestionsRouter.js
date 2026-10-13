import { publicError } from '../../config/security.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { extractUserId } from '../pets/shared.js';
import {
  WELFARE_RESPONSE_ACTIONS,
  listPendingWelfareSuggestions,
  respondToWelfareSuggestion,
} from './welfareSuggestionsService.js';

export function registerWelfareSuggestionRoutes(router, pool) {
  router.get('/:id/welfare-suggestions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const suggestions = await listPendingWelfareSuggestions(pool, userId, petId);
      if (suggestions === null) return res.status(404).json({ error: 'Pet not found' });
      res.json(suggestions);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/welfare-suggestions/:suggestionId/respond', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, suggestionId } = req.params;
    const action = (req.body?.action || '').trim();
    if (!WELFARE_RESPONSE_ACTIONS.has(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const primaryOutcome = req.body?.primary_outcome ?? req.body?.primaryOutcome ?? null;
      const result = await respondToWelfareSuggestion(
        pool,
        userId,
        petId,
        suggestionId,
        action,
        { primaryOutcome },
      );
      if (result === null) return res.status(404).json({ error: 'Pet not found' });
      if (result === undefined) {
        return res.status(404).json({ error: 'Welfare suggestion not found' });
      }
      if (result.error === 'primary_outcome_required') {
        return res.status(400).json({ error: 'primary_outcome is required for complete' });
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: `welfare_suggestion.${action}`,
        resourceType: 'welfare_suggestion',
        resourceId: suggestionId,
        petId,
        metadata: {
          subject_key: result.subject_key,
          dedupe_key: result.dedupe_key,
          primary_outcome: result.primary_outcome,
        },
        req,
      });
      return res.json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
