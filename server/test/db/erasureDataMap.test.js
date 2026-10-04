import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  bindingKey,
  discoverUserLinkedBindings,
  loadErasureDataMap,
} from './helpers/erasureDataMapDiscovery.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'users'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('erasureDataMap tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('erasure data map (real PG)', () => {
  it('has schema_version 1 and covers every discovered user link', async () => {
    const map = loadErasureDataMap();
    expect(map.schema_version).toBe(1);

    const mapKeys = new Set(
      (map.bindings || []).map((row) => bindingKey(row.table, row.column)),
    );

    const discovered = await discoverUserLinkedBindings(pool);
    const missing = discovered.filter(
      (binding) => !mapKeys.has(bindingKey(binding.table, binding.column)),
    );

    expect(missing).toEqual([]);
  });

  it('documents planned PEOPLE tables without requiring them in discovery yet', async () => {
    const map = loadErasureDataMap();
    expect(Array.isArray(map.planned_tables)).toBe(true);
    expect(map.planned_tables.length).toBeGreaterThan(0);

    for (const planned of map.planned_tables) {
      const exists = await pool.query(
        `SELECT 1 FROM information_schema.tables
         WHERE table_schema = 'public' AND table_name = $1`,
        [planned.table],
      );
      if (exists.rows.length === 0) {
        continue;
      }
      const column = await pool.query(
        `SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = $1 AND column_name = $2`,
        [planned.table, planned.column],
      );
      if (column.rows.length > 0) {
        const mapKeys = new Set(
          (map.bindings || []).map((row) => bindingKey(row.table, row.column)),
        );
        expect(mapKeys.has(bindingKey(planned.table, planned.column))).toBe(true);
      }
    }
  });

  it('lists cleanup_jobs handling and users root row', () => {
    const map = loadErasureDataMap();
    expect(map.cleanup_jobs?.erasure_action).toBeTruthy();
    const root = (map.bindings || []).find(
      (row) => row.table === 'users' && row.column === 'id',
    );
    expect(root?.erasure_action).toBe('explicit_delete');
  });
});
