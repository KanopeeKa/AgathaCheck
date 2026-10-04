import { createHash, randomBytes, timingSafeEqual } from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { logAuditEvent } from '../audit.js';
import { withTransaction } from '../db/withTransaction.js';
import { enqueueCleanupJob } from '../jobs/cleanupJobsApi.js';
import { kickCleanupJobs } from '../jobs/cleanupJobsRunner.js';
import { fileRefFromUrl } from '../petDataLifecycle.js';
import { revokeAllUserRefreshSessions } from '../refreshSessions.js';
import { redactJobError } from '../jobs/redactJobError.js';
import { isPostHogPersonDeleteConfigured } from '../posthogServer.js';

const ERASURE_MESSAGE =
  'Your account has been deleted. Remaining files and analytics data are being removed in the background.';

/** @type {string | null} */
let faultInjectionStep = null;

export function setAccountErasureFaultStep(step) {
  faultInjectionStep = step;
}

export function clearAccountErasureFaultStep() {
  faultInjectionStep = null;
}

function maybeFault(step) {
  if (faultInjectionStep === step) {
    throw new Error(`account erasure fault injection at ${step}`);
  }
}

export function generateStatusToken() {
  const token = randomBytes(32).toString('base64url');
  return {
    token,
    hash: hashStatusToken(token),
  };
}

export function hashStatusToken(token) {
  const buf = typeof token === 'string' ? Buffer.from(token, 'utf8') : token;
  return createHash('sha256').update(buf).digest('hex');
}

function constantTimeHashEqual(expectedHex, providedToken) {
  const providedHex = hashStatusToken(providedToken);
  const a = Buffer.from(expectedHex, 'hex');
  const b = Buffer.from(providedHex, 'hex');
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

async function collectPetFileUrlsForOwnedPets(client, userId) {
  const pets = await client.query(
    `SELECT id FROM pets WHERE user_id = $1 FOR UPDATE`,
    [userId],
  );
  const urls = [];
  for (const row of pets.rows) {
    const petId = row.id;
    const photo = await client.query('SELECT photo_path FROM pets WHERE id = $1', [petId]);
    if (photo.rows[0]?.photo_path) urls.push(photo.rows[0].photo_path);

    const entryPhotos = await client.query(
      `SELECT hep.url
       FROM health_event_photos hep
       JOIN health_entries he ON he.id = hep.health_entry_id
       WHERE he.pet_id = $1`,
      [petId],
    );
    for (const r of entryPhotos.rows) {
      if (r.url) urls.push(r.url);
    }

    const issueDocs = await client.query(
      `SELECT hid.url
       FROM health_issue_documents hid
       JOIN health_issues hi ON hi.id = hid.health_issue_id
       WHERE hi.pet_id = $1`,
      [petId],
    );
    for (const r of issueDocs.rows) {
      if (r.url) urls.push(r.url);
    }
  }
  return urls;
}

async function collectErasureFileRefs(client, userId) {
  const userRow = await client.query(
    'SELECT photo_url FROM users WHERE id = $1',
    [userId],
  );
  const urls = [...(await collectPetFileUrlsForOwnedPets(client, userId))];
  if (userRow.rows[0]?.photo_url) {
    urls.push(userRow.rows[0].photo_url);
  }
  const byDedupe = new Map();
  for (const url of urls) {
    const ref = fileRefFromUrl(url);
    if (ref) byDedupe.set(ref.dedupeKey, ref);
  }
  return [...byDedupe.values()];
}

async function applyExplicitErasurePii(client, userId, userEmail) {
  const email = userEmail?.toLowerCase?.() ?? null;
  await client.query(
    'UPDATE archived_pets SET transferred_to_user_id = NULL WHERE transferred_to_user_id = $1',
    [userId],
  );
  await client.query('UPDATE foster_profiles SET email = NULL WHERE user_id = $1', [userId]);
  await client.query('UPDATE org_foster_parents SET email = NULL WHERE user_id = $1', [userId]);
  await client.query(
    'UPDATE organization_permissions SET granted_by = NULL WHERE granted_by = $1',
    [userId],
  );
  await client.query(
    'UPDATE organization_permissions SET revoked_by = NULL WHERE revoked_by = $1',
    [userId],
  );
  await client.query(
    'UPDATE people_contacts SET email = NULL WHERE linked_user_id = $1',
    [userId],
  );
  await client.query('UPDATE prospects SET email = NULL WHERE user_id = $1', [userId]);
  await client.query('UPDATE vets SET email = NULL WHERE user_id = $1', [userId]);
  if (email) {
    await client.query(
      `UPDATE pet_share_invites
       SET invitee_email = 'erased@redacted.invalid'
       WHERE lower(invitee_email) = $1 OR invitee_user_id = $2`,
      [email, userId],
    );
    await client.query(
      `UPDATE planned_absence_carer_invites
       SET invitee_email = 'erased@redacted.invalid'
       WHERE lower(invitee_email) = $1 OR invitee_user_id = $2`,
      [email, userId],
    );
  }
  await client.query(
    `UPDATE audit_events
     SET actor_user_id = NULL,
         metadata = metadata - 'email' - 'actor_email'
     WHERE actor_user_id = $1`,
    [userId],
  );
}

async function syncOperationStatus(client, operationId) {
  const jobs = await client.query(
    `SELECT status, job_type FROM cleanup_jobs WHERE correlation_id = $1`,
    [operationId],
  );
  if (jobs.rows.length === 0) {
    await client.query(
      `UPDATE account_erasure_operations
       SET status = 'in_progress'
       WHERE id = $1 AND status = 'accepted'`,
      [operationId],
    );
    return;
  }

  const statuses = jobs.rows.map((r) => r.status);
  if (statuses.some((s) => s === 'dead')) {
    await client.query(
      `UPDATE account_erasure_operations
       SET status = 'failed',
           failed_at = COALESCE(failed_at, now()),
           last_error_redacted = COALESCE(last_error_redacted, $2)
       WHERE id = $1`,
      [operationId, redactJobError('one or more cleanup jobs reached dead status')],
    );
    return;
  }
  const allSucceeded = statuses.every((s) => s === 'succeeded');
  if (allSucceeded) {
    await client.query(
      `UPDATE account_erasure_operations
       SET status = 'completed',
           completed_at = COALESCE(completed_at, now())
       WHERE id = $1`,
      [operationId],
    );
    return;
  }
  await client.query(
    `UPDATE account_erasure_operations
     SET status = 'in_progress'
     WHERE id = $1 AND status IN ('accepted', 'in_progress')`,
    [operationId],
  );
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} userId
 */
export async function findErasureOperationForUser(pool, userId) {
  const result = await pool.query(
    `SELECT id, status FROM account_erasure_operations
     WHERE user_id = $1
     ORDER BY requested_at DESC
     LIMIT 1`,
    [userId],
  );
  return result.rows[0] ?? null;
}

/**
 * @param {import('pg').Pool} pool
 * @param {{ userId: string, userEmail: string, req?: import('express').Request }} params
 */
export async function acceptAccountErasure(pool, { userId, userEmail, req = null }) {
  const operationId = uuidv4();
  const { token: statusToken, hash: statusTokenHash } = generateStatusToken();

  await withTransaction(pool, async (client) => {
    maybeFault('lock_user');
    const lock = await client.query(
      'SELECT id, email FROM users WHERE id = $1 FOR UPDATE',
      [userId],
    );
    if (lock.rows.length === 0) {
      throw new Error('user not found for erasure');
    }

    maybeFault('collect_files');
    const fileRefs = await collectErasureFileRefs(client, userId);

    maybeFault('enqueue_jobs');
    for (const ref of fileRefs) {
      await enqueueCleanupJob(client, {
        type: 'file_delete',
        dedupeKey: ref.dedupeKey,
        correlationId: operationId,
        payload: {
          storage: ref.storage,
          relative_path: ref.relative_path,
        },
      });
    }
    await enqueueCleanupJob(client, {
      type: 'posthog_person_delete',
      dedupeKey: `posthog:${userId}`,
      correlationId: operationId,
      payload: { distinct_id: userId },
    });

    maybeFault('revoke_sessions');
    await revokeAllUserRefreshSessions(client, userId);

    maybeFault('insert_operation');
    await client.query(
      `INSERT INTO account_erasure_operations (
         id, user_id, status, status_token_hash, requested_at
       ) VALUES ($1, $2, 'accepted', $3, now())`,
      [operationId, userId, statusTokenHash],
    );

    maybeFault('explicit_erasure');
    await applyExplicitErasurePii(client, userId, userEmail);

    maybeFault('delete_user');
    const deleted = await client.query('DELETE FROM users WHERE id = $1', [userId]);
    if ((deleted.rowCount ?? 0) === 0) {
      throw new Error('user delete affected zero rows');
    }
    await client.query(
      `UPDATE account_erasure_operations
       SET db_erased_at = now(), status = 'in_progress'
       WHERE id = $1`,
      [operationId],
    );

    maybeFault('audit');
    const auditId = await logAuditEvent(client, {
      actorType: 'system',
      action: 'auth.account_deletion_accepted',
      resourceType: 'user',
      resourceId: userId,
      req,
      metadata: { operation_id: operationId },
    });
    if (!auditId) {
      throw new Error('required audit event was not written');
    }
  });

  kickCleanupJobs();

  return {
    message: ERASURE_MESSAGE,
    erasure: {
      operation_id: operationId,
      status: 'accepted',
      status_token: statusToken,
    },
  };
}

export function buildIdempotentErasureResponse(operation) {
  return {
    message: ERASURE_MESSAGE,
    erasure: {
      operation_id: operation.id,
      status: operation.status,
    },
  };
}

/**
 * @param {import('pg').Pool} pool
 * @param {string} operationId
 * @param {string} statusToken
 */
export async function getErasureStatus(pool, operationId, statusToken) {
  const opResult = await pool.query(
    'SELECT * FROM account_erasure_operations WHERE id = $1',
    [operationId],
  );
  const row = opResult.rows[0];
  const dummyHash = '0'.repeat(64);
  const hashToCompare = row?.status_token_hash ?? dummyHash;
  const tokenOk = statusToken && constantTimeHashEqual(hashToCompare, statusToken);
  if (!row || !tokenOk) {
    return { ok: false, status: 404 };
  }

  const client = await pool.connect();
  try {
    await syncOperationStatus(client, operationId);
  } finally {
    client.release();
  }

  const refreshed = await pool.query(
    'SELECT * FROM account_erasure_operations WHERE id = $1',
    [operationId],
  );
  const operation = refreshed.rows[0];

  const jobs = await pool.query(
    `SELECT status, job_type FROM cleanup_jobs WHERE correlation_id = $1`,
    [operationId],
  );
  const fileJobs = jobs.rows.filter((j) => j.job_type === 'file_delete');
  const fileStats = {
    total: fileJobs.length,
    succeeded: fileJobs.filter((j) => j.status === 'succeeded').length,
    pending: fileJobs.filter((j) => ['pending', 'running', 'retryable'].includes(j.status)).length,
    dead: fileJobs.filter((j) => j.status === 'dead').length,
  };

  const phJobs = jobs.rows.filter((j) => j.job_type === 'posthog_person_delete');
  let analytics = 'pending';
  if (phJobs.length === 0) {
    analytics = 'not_configured';
  } else {
    const ph = phJobs[0];
    if (ph.status === 'succeeded') {
      analytics = isPostHogPersonDeleteConfigured() ? 'completed' : 'not_configured';
    } else if (ph.status === 'dead') {
      analytics = 'failed';
    } else {
      analytics = 'pending';
    }
  }

  return {
    ok: true,
    body: {
      operation_id: operation.id,
      status: operation.status,
      steps: {
        database: 'completed',
        files: fileStats,
        analytics,
      },
    },
  };
}

export { ERASURE_MESSAGE };
