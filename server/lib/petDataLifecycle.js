/**
 * Pet-related data and file lifecycle (F-09, F-10, F-12).
 */
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

import { logAuditEvent } from './audit.js';
import { withTransaction } from './db/withTransaction.js';
import { enqueueCleanupJob } from './jobs/cleanupJobsApi.js';
import { kickCleanupJobs } from './jobs/cleanupJobsRunner.js';
import {
  defaultKindForType,
  normaliseKind,
  normalisePriority,
  NOTIFICATION_PRIORITY_NORMAL,
} from './notificationKind.js';
import { userDisplayName } from './notificationHelper.js';
import {
  PET_ACCESS_ROLES,
  FOSTER_PET_ACCESS_ROLE,
} from './petAccess.js';
import {
  parseHealthFileIdFromUrl,
  privateHealthDir,
  removePrivateHealthFile,
  resolvePrivateHealthFile,
} from './privateHealthStorage.js';

const PET_DATA_TABLES = [
  'weight_entries',
  'health_issues',
  'health_entries',
  'pet_timeline_entries',
  'pet_activity_events',
  'family_events',
  'notifications',
  'pet_share_links',
];

const PASSED_AWAY_EVENT = 'passed_away';

async function collectPetFileUrls(db, petId) {
  const urls = [];
  const photo = await db.query('SELECT photo_path FROM pets WHERE id = $1', [petId]);
  if (photo.rows[0]?.photo_path) {
    urls.push(photo.rows[0].photo_path);
  }

  const entryPhotos = await db.query(
    `SELECT hep.url
     FROM health_event_photos hep
     JOIN health_entries he ON he.id = hep.health_entry_id
     WHERE he.pet_id = $1`,
    [petId],
  );
  for (const row of entryPhotos.rows) {
    if (row.url) urls.push(row.url);
  }

  const issueDocs = await db.query(
    `SELECT hid.url
     FROM health_issue_documents hid
     JOIN health_issues hi ON hi.id = hid.health_issue_id
     WHERE hi.pet_id = $1`,
    [petId],
  );
  for (const row of issueDocs.rows) {
    if (row.url) urls.push(row.url);
  }

  return urls;
}

function fileRefFromUrl(url) {
  if (!url || typeof url !== 'string') return null;

  const healthFileId = parseHealthFileIdFromUrl(url);
  if (healthFileId) {
    const resolved = resolvePrivateHealthFile(healthFileId);
    if (resolved?.filePath) {
      const root = privateHealthDir();
      const rel = path.relative(root, resolved.filePath);
      if (rel && !rel.startsWith('..') && !path.isAbsolute(rel)) {
        const relativePath = rel.split(path.sep).join('/');
        return {
          storage: 'private_health',
          relative_path: relativePath,
          dedupeKey: `file:private_health:${relativePath}`,
        };
      }
    }
    const fallbackName = `${healthFileId}.jpg`;
    return {
      storage: 'private_health',
      relative_path: fallbackName,
      dedupeKey: `file:private_health:${fallbackName}`,
    };
  }

  if (url.startsWith('/uploads/')) {
    const relativePath = url.replace(/^\/uploads\//, '');
    if (!relativePath) return null;
    return {
      storage: 'uploads',
      relative_path: relativePath,
      dedupeKey: `file:uploads:${relativePath}`,
    };
  }

  return null;
}

async function collectPetFileRefs(client, petId) {
  const urls = await collectPetFileUrls(client, petId);
  const byDedupe = new Map();
  for (const url of urls) {
    const ref = fileRefFromUrl(url);
    if (ref) byDedupe.set(ref.dedupeKey, ref);
  }
  return [...byDedupe.values()];
}

async function enqueuePetFileDeletes(client, petId, fileRefs) {
  for (const ref of fileRefs) {
    await enqueueCleanupJob(client, {
      type: 'file_delete',
      dedupeKey: ref.dedupeKey,
      correlationId: petId,
      payload: {
        storage: ref.storage,
        relative_path: ref.relative_path,
      },
    });
  }
}

function buildDeleteResponse(petId, rowsRemoved, filesScheduled) {
  const count = filesScheduled ?? 0;
  return {
    deleted: true,
    pet_id: petId,
    rows_removed: rowsRemoved,
    files_scheduled: count,
    file_cleanup: count > 0 ? 'scheduled' : 'none',
    files_removed: count,
  };
}

async function runPetDataDeletionTransaction(client, petId, {
  actorUserId = null,
  req = null,
  auditAction = null,
  deletePetRow = false,
} = {}) {
  const fileRefs = await collectPetFileRefs(client, petId);
  await enqueuePetFileDeletes(client, petId, fileRefs);

  const rowsRemoved = {};
  for (const table of PET_DATA_TABLES) {
    const result = await client.query(`DELETE FROM ${table} WHERE pet_id = $1`, [petId]);
    rowsRemoved[table] = result.rowCount ?? 0;
  }

  if (deletePetRow) {
    const del = await client.query('DELETE FROM pets WHERE id = $1', [petId]);
    if ((del.rowCount ?? 0) === 0) {
      throw new Error('pet not found');
    }
  } else {
    await client.query(
      `UPDATE pets
       SET photo_path = NULL, weight = NULL, vet_id = NULL, updated_at = NOW()
       WHERE id = $1`,
      [petId],
    );
  }

  if (actorUserId && auditAction) {
    const auditId = await logAuditEvent(client, {
      actorUserId,
      action: auditAction,
      resourceType: 'pet',
      resourceId: petId,
      petId,
      req,
      metadata: { tables: rowsRemoved, files_scheduled: fileRefs.length },
    });
    if (!auditId) {
      throw new Error('required audit event was not written');
    }
  }

  return { rowsRemoved, filesScheduled: fileRefs.length };
}

function removePetUploadFromDisk(uploadPath) {
  if (!uploadPath || typeof uploadPath !== 'string') return;
  if (!uploadPath.startsWith('/uploads/')) return;
  const relative = uploadPath.replace(/^\//, '');
  const filePath = path.resolve(process.cwd(), relative);
  try {
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      fs.unlinkSync(filePath);
    }
  } catch {
    // best-effort
  }
}

function removeFileUrls(urls) {
  for (const url of urls) {
    if (!url || typeof url !== 'string') continue;
    if (url.includes('/api/health-files/') || url.includes('/uploads/health')) {
      removePrivateHealthFile(url);
    } else if (url.startsWith('/uploads/')) {
      removePetUploadFromDisk(url);
    }
  }
}

/**
 * Delete pet-related rows and schedule file cleanup jobs. Pet row remains for DELETE /:id.
 */
export async function deleteAllPetData(pool, petId, { actorUserId = null, req = null } = {}) {
  const outcome = await withTransaction(pool, async (client) =>
    runPetDataDeletionTransaction(client, petId, {
      actorUserId,
      req,
      auditAction: 'pet.data_deleted',
      deletePetRow: false,
    }),
  );

  scheduleFileCleanupAfterCommit();

  return buildDeleteResponse(petId, outcome.rowsRemoved, outcome.filesScheduled);
}

/**
 * Delete all pet data, the pet row, and schedule file cleanup in one transaction.
 */
export async function deletePet(pool, petId, { actorUserId = null, req = null } = {}) {
  const outcome = await withTransaction(pool, async (client) =>
    runPetDataDeletionTransaction(client, petId, {
      actorUserId,
      req,
      auditAction: 'pet.deleted',
      deletePetRow: true,
    }),
  );

  scheduleFileCleanupAfterCommit();

  return buildDeleteResponse(petId, outcome.rowsRemoved, outcome.filesScheduled);
}

function scheduleFileCleanupAfterCommit() {
  kickCleanupJobs();
}

/** Purge on-disk files for a pet without deleting DB rows (used before account delete cascade). */
export async function purgePetFiles(pool, petId) {
  const fileUrls = await collectPetFileUrls(pool, petId);
  removeFileUrls(fileUrls);
  return fileUrls.length;
}

/** Purge files for every pet owned by a user before account deletion. */
export async function purgeAllPetFilesForUser(pool, userId) {
  const pets = await pool.query('SELECT id FROM pets WHERE user_id = $1', [userId]);
  let filesRemoved = 0;
  for (const row of pets.rows) {
    filesRemoved += await purgePetFiles(pool, row.id);
  }
  return { pets_processed: pets.rows.length, files_removed: filesRemoved };
}

async function insertPassedAwayNotification(client, {
  userId,
  petId,
  petName,
  title,
  message,
}) {
  const kind = normaliseKind(defaultKindForType('general'));
  const priority = normalisePriority(NOTIFICATION_PRIORITY_NORMAL);
  await client.query(
    `INSERT INTO notifications (
       id, user_id, pet_id, pet_name, health_entry_id, organization_id,
       title, message, type, kind, priority, resolved_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
    [
      uuidv4(),
      userId,
      petId,
      petName,
      null,
      null,
      title,
      message,
      'general',
      kind,
      priority,
      null,
    ],
  );
}

/**
 * Notify collaborators when a pet is marked passed away (F-10, D14).
 */
export async function notifyPassedAwayCollaborators(pool, {
  petId,
  ownerId,
  petName,
}) {
  return withTransaction(pool, async (client) => {
    let displayPetName = petName;
    if (!displayPetName) {
      const petRow = await client.query('SELECT name FROM pets WHERE id = $1', [petId]);
      displayPetName = petRow.rows[0]?.name || 'your pet';
    }

    const ownerResult = await client.query(
      'SELECT first_name, last_name, email FROM users WHERE id = $1',
      [ownerId],
    );
    const ownerName = userDisplayName(ownerResult.rows[0] || {});

    const notifyRoles = [...PET_ACCESS_ROLES, FOSTER_PET_ACCESS_ROLE];
    const access = await client.query(
      `SELECT pa.user_id
       FROM pet_access pa
       WHERE pa.pet_id = $1
         AND pa.user_id != $2
         AND pa.role = ANY($3::text[])
         AND COALESCE(pa.hidden, false) = false`,
      [petId, ownerId, notifyRoles],
    );

    let notifiedCount = 0;
    let alreadyNotifiedCount = 0;

    for (const row of access.rows) {
      const ledger = await client.query(
        `INSERT INTO pet_lifecycle_notifications (pet_id, event, recipient_user_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (pet_id, event, recipient_user_id) DO NOTHING
         RETURNING recipient_user_id`,
        [petId, PASSED_AWAY_EVENT, row.user_id],
      );
      if (ledger.rows.length === 0) {
        alreadyNotifiedCount += 1;
        continue;
      }
      await insertPassedAwayNotification(client, {
        userId: row.user_id,
        petId,
        petName: displayPetName,
        title: 'In loving memory',
        message: `${ownerName} marked ${displayPetName} as passed away.`,
      });
      notifiedCount += 1;
    }

    let deliveryStatus = 'no_recipients';
    if (notifiedCount > 0) {
      deliveryStatus = 'delivered';
    } else if (alreadyNotifiedCount > 0) {
      deliveryStatus = 'already_notified';
    }

    return {
      notified_count: notifiedCount,
      already_notified_count: alreadyNotifiedCount,
      delivery_status: deliveryStatus,
    };
  });
}
