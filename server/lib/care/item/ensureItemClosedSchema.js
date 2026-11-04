/**
 * Apply migration 085 when the DB was migrated via SQL ledger only (CI E2E, local
 * `migrate.js up`) and `care_closed_reason` is not yet present.
 */

import { migrateCareItemClosed } from '../../../scripts/migrations/085_care_item_closed.js';

/** @type {Promise<void>|null} */
let ensurePromise = null;

/**
 * @param {import('pg').Pool | import('pg').PoolClient} db
 */
export async function ensureItemClosedSchema(db) {
  if (ensurePromise) {
    await ensurePromise;
    return;
  }
  ensurePromise = (async () => {
    const { rows } = await db.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_schema = current_schema()
         AND table_name = 'health_entries'
         AND column_name = 'care_closed_reason'`,
    );
    if (rows.length > 0) return;
    await migrateCareItemClosed(db);
  })();
  try {
    await ensurePromise;
  } catch (err) {
    ensurePromise = null;
    throw err;
  }
}
