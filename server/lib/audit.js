import { createHmac } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { AUDIT_PSEUDONYM_SALT } from '../config/observability.js';
import { logger } from './logger.js';

export function auditContextFromReq(req) {
  if (!req) {
    return { requestId: null, ipAddress: null, userAgent: null };
  }
  return {
    requestId: req.requestId || req.headers?.['x-request-id'] || null,
    ipAddress: req.ip || req.socket?.remoteAddress || null,
    userAgent: req.headers?.['user-agent'] || null,
  };
}

export function pseudonymizeActor(userId) {
  if (!userId) return null;
  return createHmac('sha256', AUDIT_PSEUDONYM_SALT)
    .update(String(userId))
    .digest('hex')
    .slice(0, 32);
}

/**
 * Append an audit event. Failures are logged but never block the caller.
 */
export async function logAuditEvent(pool, event) {
  const {
    actorUserId = null,
    actorType = 'user',
    action,
    resourceType,
    resourceId = null,
    orgId = null,
    petId = null,
    outcome = 'success',
    metadata = {},
    req = null,
    retentionTier = 'hot',
  } = event;

  if (!action || !resourceType) {
    logger.warn({ event }, 'audit event missing required fields');
    return null;
  }

  const ctx = auditContextFromReq(req);
  const safeMetadata =
    metadata && typeof metadata === 'object' && !Array.isArray(metadata)
      ? metadata
      : {};

  try {
    const result = await pool.query(
      `INSERT INTO audit_events (
         id, occurred_at, actor_user_id, actor_type, action, resource_type,
         resource_id, org_id, pet_id, outcome, metadata, request_id,
         ip_address, user_agent, retention_tier
       ) VALUES (
         $1, NOW(), $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, $11, $12, $13, $14
       ) RETURNING id`,
      [
        uuidv4(),
        actorUserId,
        actorType,
        action,
        resourceType,
        resourceId,
        orgId,
        petId,
        outcome,
        JSON.stringify(safeMetadata),
        ctx.requestId,
        ctx.ipAddress,
        ctx.userAgent,
        retentionTier,
      ]
    );
    return result.rows[0]?.id ?? null;
  } catch (err) {
    logger.error({ err, action, resourceType }, 'failed to write audit event');
    return null;
  }
}

export function logAuditEventSafe(pool, event) {
  return logAuditEvent(pool, event).catch((err) => {
    logger.error({ err, action: event?.action }, 'audit event promise rejected');
    return null;
  });
}
