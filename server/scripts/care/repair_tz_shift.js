#!/usr/bin/env node
/**
 * §9 TZ-shift data repair (DC-3). Default --dry-run; --apply writes.
 */
import { createAppPool } from '../../lib/db/createPool.js';
import { assertPgDateWireFormat } from '../../lib/db/pgTypes.js';
import { repairTzShift } from '../../lib/care/occurrence/tzShiftRepair.js';

const apply = process.argv.includes('--apply');

const pool = createAppPool();
const client = await pool.connect();
try {
  await assertPgDateWireFormat(client);
} finally {
  client.release();
}

const reports = await repairTzShift(pool, { apply });
console.log(
  JSON.stringify(
    {
      mode: apply ? 'apply' : 'dry-run',
      itemsWithChanges: reports.length,
      reports,
    },
    null,
    2,
  ),
);
await pool.end();
