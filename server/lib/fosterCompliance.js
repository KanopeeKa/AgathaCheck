/** G0 §11 retention categories for shelter–foster relationships (J1 Phase 4). */
export const FOSTER_RETENTION_CATEGORIES = new Set([
  'shelter_foster_relationship',
  'declined_archived',
  'manual_contact',
]);

export function defaultRetentionCategoryForParent({
  approvalState,
  creationSource,
  userId,
}) {
  if (approvalState === 'declined' || approvalState === 'archived') {
    return 'declined_archived';
  }
  if (creationSource === 'manual_shelter_entry' && !userId) {
    return 'manual_contact';
  }
  return 'shelter_foster_relationship';
}

export function isValidRetentionCategory(value) {
  return FOSTER_RETENTION_CATEGORIES.has(value);
}

export function registerFosterComplianceRoutes(router, {
  pool,
  extractUserId,
  requireOrgAdmin,
  logAuditEventSafe,
  fosterParentToMap,
  publicError,
}) {
  router.patch('/:orgId/foster-parents/:id/opt-out', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const fosterParentId = req.params.id;
    const data = req.body || {};
    const optOut = data.opt_out === true || data.optOut === true;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `UPDATE org_foster_parents
         SET opt_out_at = CASE WHEN $1 THEN NOW() ELSE NULL END,
             updated_at = NOW()
         WHERE id = $2 AND organization_id = $3
         RETURNING *`,
        [optOut, fosterParentId, orgId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Foster parent not found' });
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'foster_outreach_opt_out_recorded',
        resourceType: 'shelter_foster_relationship',
        resourceId: fosterParentId,
        orgId,
        metadata: { opt_out: optOut },
        req,
      });

      const row = result.rows[0];
      res.json(fosterParentToMap({
        ...row,
        kind: 'external',
        photo_url: null,
        role: null,
        active_pet_count: 0,
        active_pets: [],
      }, { kind: 'external' }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:orgId/foster-parents/:id/retention', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const fosterParentId = req.params.id;
    const data = req.body || {};
    const retentionCategory = (data.retention_category || data.retentionCategory || '').trim();

    if (!isValidRetentionCategory(retentionCategory)) {
      return res.status(400).json({ error: 'Invalid retention_category' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `UPDATE org_foster_parents
         SET retention_category = $1, updated_at = NOW()
         WHERE id = $2 AND organization_id = $3
         RETURNING *`,
        [retentionCategory, fosterParentId, orgId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Foster parent not found' });
      }

      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'foster_retention_category_updated',
        resourceType: 'shelter_foster_relationship',
        resourceId: fosterParentId,
        orgId,
        metadata: { retention_category: retentionCategory },
        req,
      });

      const row = result.rows[0];
      res.json(fosterParentToMap({
        ...row,
        kind: 'external',
        photo_url: null,
        role: null,
        active_pet_count: 0,
        active_pets: [],
      }, { kind: 'external' }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
