import { extractUserId } from './shared.js';

export function registerLifecycleRoutes(router, pool) {
  router.delete('/:id/data', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.status(200).json({ deleted: true, pet_id: req.params.id });
  });

  // STUB: the pet's passedAway flag is persisted via PUT /api/pets/:id; this
  // endpoint only exists to notify shared users (sharing is not implemented), so
  // it acknowledges without side effects.
  router.post('/:id/passed-away', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.status(200).json({ passed_away: true, pet_id: req.params.id });
  });
}
