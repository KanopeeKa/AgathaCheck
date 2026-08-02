/**
 * Product activity log for Organisation v2 last-activity sorting (D-v2-ACT-1).
 * Distinct from audit_events and pet_timeline_entries — see docs/architecture/pet-activity-model.md.
 */
import { v4 as uuidv4 } from 'uuid';

import { logger } from './logger.js';

export const PET_ACTIVITY_EVENT_TYPES = Object.freeze([
  'health_log',
  'foster_session',
  'profile_edit',
  'document_upload',
]);

/** Safe metadata keys per event type (D-v2-ACT-3 — keys/counts only, no payloads). */
const ALLOWED_METADATA_KEYS = Object.freeze({
  health_log: new Set(['action', 'entry_type']),
  foster_session: new Set(['mutation', 'session_status', 'outcome']),
  profile_edit: new Set(['field_count', 'changed_fields']),
  document_upload: new Set(['document_count']),
});

/**
 * Manifest of files that must call recordPetActivity* after product writes.
 * CI contract test enforces this list — update when adding or moving hooks.
 */
export const PET_ACTIVITY_HOOK_MANIFEST = Object.freeze([
  {
    id: 'health-entry-crud',
    file: 'server/routes/healthEntries/crudRouter.js',
    eventType: 'health_log',
    minCalls: 2,
  },
  {
    id: 'health-entry-completion',
    file: 'server/routes/healthEntries/completionRouter.js',
    eventType: 'health_log',
    minCalls: 7,
  },
  {
    id: 'health-document-upload',
    file: 'server/routes/healthEntries/documentsRouter.js',
    eventType: 'document_upload',
    minCalls: 1,
  },
  {
    id: 'pet-profile-update',
    file: 'server/routes/pets/coreRouter.js',
    eventType: 'profile_edit',
    minCalls: 1,
  },
  {
    id: 'foster-session-lib',
    file: 'server/lib/fosterSessions.js',
    eventType: 'foster_session',
    minCalls: 6,
  },
  {
    id: 'adoption-journey-placement',
    file: 'server/lib/adoptionJourneys.js',
    eventType: 'foster_session',
    minCalls: 3,
  },
  {
    id: 'placement-action-router',
    file: 'server/routes/organizations/placements/actionRouter.js',
    eventType: 'foster_session',
    minCalls: 1,
  },
  {
    id: 'foster-placement-accept-decline',
    file: 'server/routes/fosterPlacements.js',
    eventType: 'foster_session',
    minCalls: 2,
  },
]);

export function sanitizePetActivityMetadata(eventType, metadata = {}) {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return {};
  }
  const allowed = ALLOWED_METADATA_KEYS[eventType];
  if (!allowed) return {};

  const safe = {};
  for (const [key, value] of Object.entries(metadata)) {
    if (!allowed.has(key)) continue;
    if (key === 'changed_fields') {
      if (Array.isArray(value)) {
        safe.changed_fields = value
          .filter((item) => typeof item === 'string' && item.length > 0)
          .slice(0, 20);
      }
      continue;
    }
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      safe[key] = value;
    }
  }
  return safe;
}

async function runInTransaction(pool, fn) {
  if (typeof pool.connect === 'function') {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
  return fn(pool);
}

/**
 * Insert a product activity event and bump pets.last_activity_at in one transaction.
 * Returns event id, or null when required fields are missing.
 */
export async function recordPetActivity(pool, event) {
  const { petId, orgId, actorUserId = null, eventType, metadata = {} } = event;

  if (!petId || !orgId || !eventType) {
    return null;
  }
  if (!PET_ACTIVITY_EVENT_TYPES.includes(eventType)) {
    logger.warn({ eventType }, 'invalid pet activity event type');
    return null;
  }

  const eventId = uuidv4();
  const safeMetadata = sanitizePetActivityMetadata(eventType, metadata);

  await runInTransaction(pool, async (db) => {
    await db.query(
      `INSERT INTO pet_activity_events (
         id, pet_id, org_id, event_type, actor_user_id, occurred_at, metadata
       ) VALUES ($1, $2, $3, $4, $5, NOW(), $6::jsonb)`,
      [
        eventId,
        petId,
        orgId,
        eventType,
        actorUserId,
        JSON.stringify(safeMetadata),
      ],
    );
    await db.query(
      'UPDATE pets SET last_activity_at = NOW() WHERE id = $1',
      [petId],
    );
  });

  return eventId;
}

export function recordPetActivitySafe(pool, event) {
  return recordPetActivity(pool, event).catch((err) => {
    logger.error({ err, eventType: event?.eventType }, 'failed to record pet activity');
    return null;
  });
}

export async function lookupPetOrgId(pool, petId) {
  const result = await pool.query(
    'SELECT organization_id FROM pets WHERE id = $1',
    [petId],
  );
  return result.rows[0]?.organization_id || null;
}

/** Record activity when the pet belongs to an organisation; no-op otherwise. */
export function recordPetActivityForPet(pool, { petId, actorUserId, eventType, metadata = {} }) {
  return lookupPetOrgId(pool, petId).then((orgId) => {
    if (!orgId) return null;
    return recordPetActivitySafe(pool, {
      petId,
      orgId,
      actorUserId,
      eventType,
      metadata,
    });
  });
}

/** Record foster placement mutation activity (placement always has org context). */
export function recordFosterSessionActivity(
  pool,
  placement,
  actorUserId,
  metadata = {},
) {
  if (!placement?.pet_id || !placement?.organization_id) {
    return Promise.resolve(null);
  }
  return recordPetActivitySafe(pool, {
    petId: placement.pet_id,
    orgId: placement.organization_id,
    actorUserId,
    eventType: 'foster_session',
    metadata,
  });
}
