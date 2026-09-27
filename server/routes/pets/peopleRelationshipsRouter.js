import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { userCanManageProfile } from '../../lib/petAccess.js';
import { RELATIONSHIP_KINDS } from '../../lib/people/constants.js';
import {
  contactUsableForPet,
  getPetOwnerUserId,
} from '../../lib/people/authz.js';
import { extractUserId } from './shared.js';

function relationshipRowToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    contact_id: row.contact_id,
    relationship_kind: row.relationship_kind,
    is_primary: row.is_primary === true || row.is_primary === 't',
    active: row.active === true || row.active === 't',
    contact: row.contact_name
      ? {
        id: row.contact_id,
        kind: row.contact_kind,
        name: row.contact_name,
        phone: row.contact_phone ?? null,
        inactive_at: row.contact_inactive_at
          ? row.contact_inactive_at.toISOString?.() || String(row.contact_inactive_at)
          : null,
      }
      : null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
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
      const result = await pool.query(
        `SELECT pcr.*,
          pc.kind AS contact_kind,
          pc.name AS contact_name,
          pc.phone AS contact_phone,
          pc.inactive_at AS contact_inactive_at
         FROM pet_contact_relationships pcr
         INNER JOIN people_contacts pc ON pc.id = pcr.contact_id
         WHERE pcr.pet_id = $1
         ORDER BY pcr.relationship_kind, pc.name`,
        [petId],
      );
      res.json(result.rows.map(relationshipRowToMap));
    } catch (err) {
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

      const petOwnerId = await getPetOwnerUserId(pool, petId);
      if (!petOwnerId) return res.status(404).json({ error: 'Pet not found' });

      for (const rel of parsed.relationships) {
        const ok = await contactUsableForPet(pool, rel.contact_id, userId, petOwnerId);
        if (!ok) {
          return res.status(400).json({ error: 'Contact not found' });
        }
      }

      await pool.query('DELETE FROM pet_contact_relationships WHERE pet_id = $1', [petId]);

      for (const rel of parsed.relationships) {
        const relId = rel.id || uuidv4();
        await pool.query(
          `INSERT INTO pet_contact_relationships (
             id, pet_id, contact_id, relationship_kind, is_primary, active,
             created_at, updated_at
           ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())`,
          [
            relId,
            petId,
            rel.contact_id,
            rel.relationship_kind,
            rel.is_primary,
            rel.active,
          ],
        );
      }

      const result = await pool.query(
        `SELECT pcr.*,
          pc.kind AS contact_kind,
          pc.name AS contact_name,
          pc.phone AS contact_phone,
          pc.inactive_at AS contact_inactive_at
         FROM pet_contact_relationships pcr
         INNER JOIN people_contacts pc ON pc.id = pcr.contact_id
         WHERE pcr.pet_id = $1
         ORDER BY pcr.relationship_kind, pc.name`,
        [petId],
      );
      res.json(result.rows.map(relationshipRowToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
