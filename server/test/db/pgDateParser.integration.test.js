import { describe, expect, it } from '@jest/globals';

import { createAppPool, verifyPgDateParser } from '../../lib/db/createPool.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { createDbPool, openHarness } from './helpers/careHarness.js';

describe('PG DATE parser (integration)', () => {
  it('returns YYYY-MM-DD strings from PostgreSQL DATE', async () => {
    const pool = createDbPool();
    try {
      await verifyPgDateParser(pool);
      const { rows } = await pool.query("SELECT '2026-09-30'::date AS d");
      expect(rows[0].d).toBe('2026-09-30');
      expect(dateToIsoDate(rows[0].d)).toBe('2026-09-30');
    } finally {
      await pool.end();
    }
  });

  it('openHarness pool passes TZ-7', async () => {
    const harness = await openHarness();
    if (!harness.pool) return;
    await verifyPgDateParser(harness.pool);
    await harness.pool.end();
  });
});
