import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

const CONNECTION_TOKEN_TTL_DAYS = 14;

export function canonicalOrgPair(orgA, orgB) {
  const a = String(orgA);
  const b = String(orgB);
  return a < b ? [a, b] : [b, a];
}

export function generateConnectionToken() {
  return crypto.randomBytes(24).toString('base64url');
}

export async function findActiveConnection(db, orgA, orgB) {
  const [low, high] = canonicalOrgPair(orgA, orgB);
  const result = await db.query(
    `SELECT * FROM org_connections
     WHERE org_low_id = $1 AND org_high_id = $2 AND status = 'active'
     LIMIT 1`,
    [low, high],
  );
  return result.rows[0] || null;
}

export async function createConnectionRequest(db, {
  requestingOrgId,
  targetOrgId,
  createdBy,
}) {
  if (String(requestingOrgId) === String(targetOrgId)) {
    const err = new Error('Cannot connect an organisation to itself');
    err.statusCode = 400;
    throw err;
  }

  const existing = await findActiveConnection(db, requestingOrgId, targetOrgId);
  if (existing) {
    const err = new Error('Organisations are already connected');
    err.statusCode = 409;
    throw err;
  }

  const token = generateConnectionToken();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + CONNECTION_TOKEN_TTL_DAYS);
  const id = uuidv4();

  await db.query(
    `INSERT INTO org_connection_requests (
       id, requesting_org_id, target_org_id, token, expires_at, created_by
     ) VALUES ($1,$2,$3,$4,$5,$6)`,
    [id, requestingOrgId, targetOrgId, token, expiresAt, createdBy],
  );

  return { id, token, expires_at: expiresAt.toISOString() };
}

export async function acceptConnectionRequest(db, token, acceptingUserId) {
  const reqResult = await db.query(
    `SELECT * FROM org_connection_requests WHERE token = $1 LIMIT 1`,
    [token],
  );
  if (reqResult.rows.length === 0) {
    const err = new Error('Connection request not found');
    err.statusCode = 404;
    throw err;
  }
  const request = reqResult.rows[0];
  if (request.status !== 'pending') {
    const err = new Error('Connection request is no longer pending');
    err.statusCode = 400;
    throw err;
  }
  if (new Date(request.expires_at) < new Date()) {
    await db.query(
      `UPDATE org_connection_requests SET status = 'expired' WHERE id = $1`,
      [request.id],
    );
    const err = new Error('Connection request has expired');
    err.statusCode = 410;
    throw err;
  }

  const adminCheck = await db.query(
    `SELECT 1 FROM organization_users
     WHERE organization_id = $1 AND user_id = $2
       AND role IN ('super_admin', 'admin')
     LIMIT 1`,
    [request.target_org_id, acceptingUserId],
  );
  if (adminCheck.rows.length === 0) {
    const err = new Error('Forbidden');
    err.statusCode = 403;
    throw err;
  }

  const [low, high] = canonicalOrgPair(
    request.requesting_org_id,
    request.target_org_id,
  );
  const connectionId = uuidv4();

  await db.query(
    `UPDATE org_connection_requests SET status = 'accepted' WHERE id = $1`,
    [request.id],
  );
  await db.query(
    `INSERT INTO org_connections (id, org_low_id, org_high_id, status)
     VALUES ($1,$2,$3,'active')
     ON CONFLICT (org_low_id, org_high_id) DO UPDATE SET status = 'active', revoked_at = NULL`,
    [connectionId, low, high],
  );

  return { connection_id: connectionId, org_low_id: low, org_high_id: high };
}

export async function revokeConnectionRequest(db, requestId, revokingOrgId) {
  const result = await db.query(
    `UPDATE org_connection_requests
     SET status = 'revoked', revoked_at = NOW()
     WHERE id = $1 AND requesting_org_id = $2 AND status = 'pending'
     RETURNING *`,
    [requestId, revokingOrgId],
  );
  if (result.rows.length === 0) {
    const err = new Error('Connection request not found');
    err.statusCode = 404;
    throw err;
  }
  return result.rows[0];
}

export async function disconnectOrgs(db, orgId, otherOrgId, revokedByOrgId) {
  const [low, high] = canonicalOrgPair(orgId, otherOrgId);
  await db.query(
    `UPDATE org_connections
     SET status = 'revoked', revoked_at = NOW(), revoked_by_org_id = $3
     WHERE org_low_id = $1 AND org_high_id = $2 AND status = 'active'`,
    [low, high, revokedByOrgId],
  );

  await db.query(
    `UPDATE custody_transfers
     SET status = 'cancelled',
         cancel_reason = 'org_disconnected',
         responded_at = NOW()
     WHERE status = 'pending'
       AND (
         (from_org_id = $1 AND to_org_id = $2)
         OR (from_org_id = $2 AND to_org_id = $1)
       )`,
    [orgId, otherOrgId],
  );
}

export async function listConnectionsForOrg(db, orgId) {
  const result = await db.query(
    `SELECT c.*,
            CASE WHEN c.org_low_id = $1 THEN c.org_high_id ELSE c.org_low_id END AS peer_org_id,
            o.name AS peer_org_name,
            o.type AS peer_org_type,
            o.email AS peer_org_email
     FROM org_connections c
     JOIN organizations o ON o.id = CASE WHEN c.org_low_id = $1 THEN c.org_high_id ELSE c.org_low_id END
     WHERE (c.org_low_id = $1 OR c.org_high_id = $1) AND c.status = 'active'
     ORDER BY c.connected_at DESC`,
    [orgId],
  );
  return result.rows;
}
