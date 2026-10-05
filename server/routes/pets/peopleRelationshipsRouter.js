import { publicError } from '../../config/security.js';
import { userCanManageProfile } from '../../lib/petAccess.js';
import { RELATIONSHIP_KINDS } from '../../lib/people/constants.js';
import { asPeopleError } from '../../lib/people/errors.js';
import {
  add,
  listForPet,
  remove,
  replaceAll,
  setSlot,
} from '../../lib/people/relationships.js';
import { extractUserId } from './shared.js';

function sendPeopleError(res, err) {
  const pe = asPeopleError(err);
  if (pe) return res.status(pe.status).json(pe.toJson());
  return null;
}

function normalizeRelationships(body) {
  const raw = body?.relationships;
  if (!Array.isArray(raw)) return { error: 'relationships array is required' };
  const normalized = [];
  for (const item of raw) {
    const kind = item.relationship_kind || item.relationshipKind;
    if (!RELATIONSHIP_KINDS.includes(kind)) {
      return { error: `Invalid relationship_kind: ${kind}` };
    }
    const contactId = item.contact_id || item.contactId;
    if (!contactId) return { error: 'contact_id is required on each relationship' };
    normalized.push({
      id: item.id || null,
      contact_id: contactId,
      relationship_kind: kind,
      is_primary: Boolean(item.is_primary ?? item.isPrimary),
      active: item.active !== false,
    });
  }
  return { relationships: normalized };
}

export function registerPeopleRelationshipsRoutes(router, pool) {
  router.get('/:petId/people-relationships', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId } = req.params;
    try {
      if (!(await userCanManageProfile(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const rows = await listForPet(pool, petId);
      res.json(rows);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:petId/people-relationships/slots/:kind', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId, kind } = req.params;
    try {
      if (!(await userCanManageProfile(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const contactId = req.body?.contact_id ?? req.body?.contactId ?? null;
      const rows = await setSlot(pool, petId, kind, contactId, userId);
      res.json(rows);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:petId/people-relationships', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId } = req.params;
    try {
      if (!(await userCanManageProfile(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const rows = await add(pool, petId, req.body || {}, userId);
      res.status(201).json(rows);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:petId/people-relationships/:relationshipId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId, relationshipId } = req.params;
    try {
      if (!(await userCanManageProfile(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const rows = await remove(pool, petId, relationshipId, userId);
      res.json(rows);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:petId/people-relationships', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId } = req.params;
    try {
      if (!(await userCanManageProfile(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const parsed = normalizeRelationships(req.body || {});
      if (parsed.error) return res.status(400).json({ error: parsed.error });

      const rows = await replaceAll(pool, petId, parsed.relationships, userId);
      res.json(rows);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });
}
