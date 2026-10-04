import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { createDbPool } from './helpers/careHarness.js';
import {
  applyWeightMonitoringUnifyDown,
  applyWeightMonitoringUnifyMigration,
} from './helpers/weightMonitoringUnifySql.js';
import { KG_PER_LB } from '../../lib/care/observations/weightUnits.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'weight_entries'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('weight monitoring unify migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('092_weight_monitoring_unify migration (real PG)', () => {
  it('U-9 up converts fixture rows; down; up again; guard rejects stone', async () => {
    await applyWeightMonitoringUnifyDown(pool).catch(() => {});
    await pool.query(
      `DELETE FROM weight_entries
       WHERE unit IS NOT NULL AND lower(unit) NOT IN ('kg', 'lb', 'lbs')`,
    );

    const userId = uuidv4();
    const petId = uuidv4();
    await pool.query(
      `INSERT INTO users (id, email, password_hash) VALUES ($1, $2, 'hash')`,
      [userId, `wmu-${userId}@example.com`],
    );
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'P', 'cat')`,
      [petId, userId],
    );

    await applyWeightMonitoringUnifyDown(pool).catch(() => {});

    const lbId = uuidv4();
    const lbsId = uuidv4();
    const nullUnitId = uuidv4();
    const nullDateId = uuidv4();
    await pool.query(
      `INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, measured_at, created_at)
       VALUES ($1, $2, $3, 10, 'lb', '2020-01-01', NOW(), NOW()),
              ($4, $2, $3, 11, 'lbs', '2020-01-02', NOW(), NOW()),
              ($5, $2, $3, 12, NULL, '2020-01-03', NOW(), NOW()),
              ($6, $2, $3, 13, 'kg', NULL, '2020-06-01 12:00:00+00', '2020-06-01 12:00:00+00')`,
      [lbId, petId, userId, lbsId, nullUnitId, nullDateId],
    );

    await applyWeightMonitoringUnifyMigration(pool);

    const lbRow = await pool.query('SELECT weight, unit, date FROM weight_entries WHERE id = $1', [lbId]);
    expect(lbRow.rows[0].unit).toBe('kg');
    expect(lbRow.rows[0].weight).toBeCloseTo(10 * KG_PER_LB, 8);
    expect(lbRow.rows[0].date).not.toBeNull();

    const userCol = await pool.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_name = 'users' AND column_name = 'weight_unit'`,
    );
    expect(userCol.rows).toHaveLength(1);

    await applyWeightMonitoringUnifyDown(pool);

    const stoneId = uuidv4();
    await pool.query(
      `INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date)
       VALUES ($1, $2, $3, 1, 'stone', '2020-01-01')`,
      [stoneId, petId, userId],
    );
    await expect(applyWeightMonitoringUnifyMigration(pool)).rejects.toThrow(/convert manually first/i);
    await pool.query('DELETE FROM weight_entries WHERE id = $1', [stoneId]);
    await applyWeightMonitoringUnifyDown(pool).catch(() => {});
    await applyWeightMonitoringUnifyMigration(pool);

    await pool.query('DELETE FROM weight_entries WHERE id = $1', [stoneId]);
    await pool.query('DELETE FROM weight_entries WHERE pet_id = $1', [petId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [petId]);
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  });
});
