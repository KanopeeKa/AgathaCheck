import {
  getActivePlacementForPet,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  placementToMap,
} from '../../../lib/fosterPlacements.js';
import { extractUserId, requireOrgAdmin } from '../shared.js';
import { publicError } from '../../../config/security.js';
import { PLACEMENT_DETAIL_SELECT, queryPlacementRows } from './shared.js';

export function registerPlacementQueryRoutes(router, pool) {
  router.get('/:orgId/placements', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const rows = await queryPlacementRows(
        pool,
        'WHERE fp.organization_id = $1 ORDER BY fp.created_at DESC',
        [orgId],
      );
      res.json(rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/pets/:petId/foster-history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const petResult = await pool.query(
        'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
        [petId, orgId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const rows = await queryPlacementRows(
        pool,
        'WHERE fp.organization_id = $1 AND fp.pet_id = $2 ORDER BY fp.created_at DESC',
        [orgId, petId],
      );
      res.json(rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/pets/:petId/placement', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const petResult = await pool.query(
        'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
        [petId, orgId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const active = await getActivePlacementForPet(pool, petId);
      if (!active) {
        return res.json({ status: PLACEMENT_STATUS_NOT_IN_FOSTER, placement: null });
      }
      const detail = await pool.query(`${PLACEMENT_DETAIL_SELECT} WHERE fp.id = $1`, [active.id]);
      res.json({
        status: active.status,
        placement: placementToMap(detail.rows[0]),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
