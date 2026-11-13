import { enqueueCleanupJob } from '../../jobs/cleanupJobsApi.js';
import { parseSupportScreenshotStorageKey } from '../screenshots/storage.js';

/**
 * @param {string} storageKey
 * @returns {{ dedupeKey: string, payload: { storage: string, relative_path: string } } | null}
 */
export function supportScreenshotFileDeleteJob(storageKey) {
  const parsed = parseSupportScreenshotStorageKey(storageKey);
  if (!parsed) return null;
  return {
    dedupeKey: `file:${parsed.storage}:${parsed.relative_path}`,
    payload: {
      storage: parsed.storage,
      relative_path: parsed.relative_path,
    },
  };
}

/**
 * @param {import('pg').PoolClient} client
 * @param {string} storageKey
 * @param {string | null} correlationId
 */
export async function enqueueSupportAttachmentDelete(client, storageKey, correlationId = null) {
  const job = supportScreenshotFileDeleteJob(storageKey);
  if (!job) return false;
  await enqueueCleanupJob(client, {
    type: 'file_delete',
    dedupeKey: job.dedupeKey,
    correlationId,
    payload: job.payload,
  });
  return true;
}
