#!/usr/bin/env node
/**
 * §9 TZ-shift data repair (DC-3). Default --dry-run; --apply writes.
 */
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { createAppPool } from '../../lib/db/createPool.js';
import { assertPgDateWireFormat } from '../../lib/db/pgTypes.js';
import { reportD5DateEdits } from '../../lib/care/repair/d5DateReport.js';
import { repairTzShift } from '../../lib/care/repair/tzShiftRepair.js';
import { loadBackendEnv } from '../lib/loadBackendEnv.js';

loadBackendEnv();

const apply = process.argv.includes('--apply');

function parseAsOfDate() {
  const eq = process.argv.find((a) => a.startsWith('--as-of-date='));
  if (eq) return normalizeCalendarDateInput(eq.slice('--as-of-date='.length));
  const idx = process.argv.indexOf('--as-of-date');
  if (idx >= 0 && process.argv[idx + 1]) {
    return normalizeCalendarDateInput(process.argv[idx + 1]);
  }
  return null;
}

const todayIso = parseAsOfDate();

function parseSinceDate() {
  const eq = process.argv.find((a) => a.startsWith('--since='));
  if (eq) return normalizeCalendarDateInput(eq.slice('--since='.length));
  const idx = process.argv.indexOf('--since');
  if (idx >= 0 && process.argv[idx + 1]) {
    return normalizeCalendarDateInput(process.argv[idx + 1]);
  }
  return '2026-10-01';
}

const pool = createAppPool();
const client = await pool.connect();
try {
  await assertPgDateWireFormat(client);
} finally {
  client.release();
}

if (process.argv.includes('--report-d5')) {
  const rows = await reportD5DateEdits(pool, { updatedSinceIso: parseSinceDate() });
  console.log(JSON.stringify({ mode: 'report-d5', count: rows.length, rows }, null, 2));
  await pool.end();
  process.exit(0);
}

const reports = await repairTzShift(pool, { apply, todayIso });
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
