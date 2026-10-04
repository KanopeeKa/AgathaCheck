/**
 * Single care item GET: commit read-path catch-up when the DB supports it.
 */

import { syncCareItemForRead } from '../occurrence/readSync.js';
import { careItemWire } from './wire.js';

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {object} entryRow
 * @param {string} entryId
 * @param {import('express').Request} req
 */
export async function careItemReadResponse(db, entryRow, entryId, req) {
  const synced = await syncCareItemForRead(db, entryId, req);
  return careItemWire(db, entryRow, req, {
    openRows: synced?.openRows,
    asOf: synced?.asOf,
  });
}
