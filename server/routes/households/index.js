import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  addHouseholdMember,
  createHousehold,
  getHouseholdDetail,
  listHouseholdsForUser,
  patchHousehold,
  getHouseholdMemberRemovalPreview,
  removeHouseholdMember,
  setHouseholdPets,
} from '../../lib/households/householdService.js';

export default function householdsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await createHousehold(pool, userId, req.body || {});
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.status(201).json(result.household);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const households = await listHouseholdsForUser(pool, userId);
      return res.json({ households });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const household = await getHouseholdDetail(pool, userId, req.params.id);
      if (!household) return res.status(404).json({ error: 'Household not found' });
      return res.json(household);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await patchHousehold(pool, userId, req.params.id, req.body || {});
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result.household);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/members', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await addHouseholdMember(pool, userId, req.params.id, req.body || {});
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.status(201).json(result.member);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/members/:userId/removal-preview', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await getHouseholdMemberRemovalPreview(
        pool,
        userId,
        req.params.id,
        req.params.userId,
      );
      if (result.error) {
        const body = { error: result.error };
        if (result.code) body.code = result.code;
        return res.status(result.status).json(body);
      }
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/members/:userId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await removeHouseholdMember(
        pool,
        userId,
        req.params.id,
        req.params.userId,
        req.body || {},
      );
      if (result.error) {
        const body = { error: result.error };
        if (result.code) body.code = result.code;
        return res.status(result.status).json(body);
      }
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/pets', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petIds = req.body?.pet_ids || req.body?.petIds || [];
    try {
      const result = await setHouseholdPets(pool, userId, req.params.id, petIds);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json({ pets: result.pets });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
