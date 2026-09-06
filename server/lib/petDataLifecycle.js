/**
 * Pet-related data and file lifecycle (F-09, F-10, F-12).
 */
import fs from 'fs';
import path from 'path';

import { logAuditEventSafe } from './audit.js';
import { createNotification, userDisplayName } from './notificationHelper.js';
import {
  COLLABORATOR_ROLES,
  FOSTER_PET_ACCESS_ROLE,
} from './petAccess.js';
import { removePrivateHealthFile } from './privateHealthStorage.js';

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

async function collectPetFileUrls(pool, petId) {
  const urls = [];
  const photo = await pool.query('SELECT photo_path FROM pets WHERE id = $1', [petId]);
  if (photo.rows[0]?.photo_path) {
    urls.push(photo.rows[0].photo_path);
  }

  const entryPhotos = await pool.query(
    `SELECT hep.url
     FROM health_event_photos hep
     JOIN health_entries he ON he.id = hep.health_entry_id
     WHERE he.pet_id = $1`,
    [petId],
  );
  for (const row of entryPhotos.rows) {
    if (row.url) urls.push(row.url);
  }

  const issueDocs = await pool.query(
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
 * Delete pet-related rows and purge health/pet files. Pet row remains for DELETE /:id.
 */
export async function deleteAllPetData(pool, petId, { actorUserId = null, req = null } = {}) {
  await pool.query('BEGIN');
  try {
    const fileUrls = await collectPetFileUrls(pool, petId);
    const rowsRemoved = {};

    for (const table of PET_DATA_TABLES) {
      const result = await pool.query(`DELETE FROM ${table} WHERE pet_id = $1`, [petId]);
      rowsRemoved[table] = result.rowCount ?? 0;
    }

    await pool.query(
      `UPDATE pets
       SET photo_path = NULL, weight = NULL, vet_id = NULL, updated_at = NOW()
       WHERE id = $1`,
      [petId],
    );

    if (actorUserId) {
      logAuditEventSafe(pool, {
        actorUserId,
        action: 'pet.data_deleted',
        resourceType: 'pet',
        resourceId: petId,
        petId,
        req,
        metadata: { tables: rowsRemoved, files_scheduled: fileUrls.length },
      });
    }

    await pool.query('COMMIT');
    removeFileUrls(fileUrls);

    return {
      deleted: true,
      pet_id: petId,
      rows_removed: rowsRemoved,
      files_removed: fileUrls.length,
    };
  } catch (err) {
    await pool.query('ROLLBACK');
    throw err;
  }
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

/**
 * Notify collaborators when a pet is marked passed away (F-10).
 * @returns {Promise<number>} notified_count
 */
export async function notifyPassedAwayCollaborators(pool, {
  petId,
  ownerId,
  petName,
}) {
  const notifyRoles = [...COLLABORATOR_ROLES, FOSTER_PET_ACCESS_ROLE];
  const access = await pool.query(
    `SELECT pa.user_id
     FROM pet_access pa
     WHERE pa.pet_id = $1
       AND pa.user_id != $2
       AND pa.role = ANY($3::text[])
       AND COALESCE(pa.hidden, false) = false`,
    [petId, ownerId, notifyRoles],
  );

  const ownerResult = await pool.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [ownerId],
  );
  const ownerName = userDisplayName(ownerResult.rows[0] || {});
  const displayPetName = petName || 'your pet';

  let notifiedCount = 0;
  for (const row of access.rows) {
    await createNotification(pool, {
      userId: row.user_id,
      petId,
      petName: displayPetName,
      title: 'In loving memory',
      message: `${ownerName} marked ${displayPetName} as passed away.`,
      type: 'general',
    });
    notifiedCount += 1;
  }
  return notifiedCount;
}
