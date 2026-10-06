import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  cancelPlannedAbsence,
  createPlannedAbsence,
  getPlannedAbsenceDetail,
  getPlannedAbsenceReadiness,
  listPlannedAbsences,
  parseListScope,
  patchPlannedAbsence,
} from './plannedAbsenceUseCases.js';

export function registerPlannedAbsenceCoreRoutes(router, pool) {
  router.get('/', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const scopeResult = parseListScope(req);
    if (!scopeResult.ok) return res.status(400).json({ error: scopeResult.error });
    const items = await listPlannedAbsences(pool, userId, scopeResult);
    res.json(items);
  }));

  router.post('/', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await createPlannedAbsence(pool, userId, req.body || {});
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.status(out.status).json(out.body);
  }));

  router.get('/:id/readiness', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await getPlannedAbsenceReadiness(pool, userId, req.params.id);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(out.readiness);
  }));

  router.get('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await getPlannedAbsenceDetail(pool, userId, req.params.id);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(out.absence);
  }));

  router.patch('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await patchPlannedAbsence(pool, userId, req.params.id, req.body || {});
    if (out.error) return res.status(out.status).json({ error: out.error });
    if (out.payload) return res.status(out.status).json(out.payload);
    res.json(out.body);
  }));

  router.post('/:id/cancel', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await cancelPlannedAbsence(pool, userId, req.params.id);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(out.absence);
  }));
}
