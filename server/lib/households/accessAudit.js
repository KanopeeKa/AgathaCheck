import { v4 as uuidv4 } from 'uuid';

const MAX_EVENTS_PER_PET = 100;

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 */
export async function recordPetAccessEvent(db, {
  petId,
  subjectUserId = null,
  eventType,
  accessSource,
  detail = null,
}) {
  if (!petId || !eventType || !accessSource) return;
  await db.query(
    `INSERT INTO pet_access_events (
       id, pet_id, subject_user_id, event_type, access_source, detail, created_at
     ) VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
    [uuidv4(), petId, subjectUserId, eventType, accessSource, detail],
  );
  await db.query(
    `DELETE FROM pet_access_events
     WHERE id IN (
       SELECT id FROM pet_access_events
       WHERE pet_id = $1
       ORDER BY created_at DESC
       OFFSET $2
     )`,
    [petId, MAX_EVENTS_PER_PET],
  );
}

export async function listPetAccessEvents(db, petId, limit = 100) {
  const capped = Math.min(Math.max(limit, 1), MAX_EVENTS_PER_PET);
  const result = await db.query(
    `SELECT id, pet_id, subject_user_id, event_type, access_source, detail, created_at
     FROM pet_access_events
     WHERE pet_id = $1
     ORDER BY created_at DESC
     LIMIT $2`,
    [petId, capped],
  );
  return result.rows;
}
