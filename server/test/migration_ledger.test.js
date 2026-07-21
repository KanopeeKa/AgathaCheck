import fs from 'fs';
import os from 'os';
import path from 'path';
import {
  loadManifest,
  resolveManifestPath,
  seedMigrationLedger,
  shouldAutoSeedMigrationLedger,
} from '../scripts/lib/migration-ledger.js';

function mockPool(responses) {
  const queue = [...responses];
  return {
    async query(sql) {
      const next = queue.shift();
      if (!next) {
        throw new Error(`unexpected query: ${sql}`);
      }
      if (typeof next === 'function') {
        return next(sql);
      }
      return next;
    },
  };
}

describe('migration-ledger', () => {
  test('resolveManifestPath finds committed manifest in repo', () => {
    expect(resolveManifestPath()).toMatch(/migration-manifest\.json$/);
    expect(fs.existsSync(resolveManifestPath())).toBe(true);
  });

  test('loadManifest returns incremental migration filenames', () => {
    const migrations = loadManifest();
    expect(migrations[0]).toBe('001_add_pet_access_hidden.sql');
    expect(migrations).toContain('020_org_custody.sql');
  });

  test('shouldAutoSeedMigrationLedger is true when users exist and ledger is empty', async () => {
    const pool = mockPool([
      { rows: [{ exists: true }] },
      { rows: [] },
    ]);
    const manifest = ['001_add_pet_access_hidden.sql'];
    await expect(shouldAutoSeedMigrationLedger(pool, manifest)).resolves.toBe(true);
  });

  test('shouldAutoSeedMigrationLedger is false when users table is missing', async () => {
    const pool = mockPool([{ rows: [{ exists: false }] }]);
    const manifest = ['001_add_pet_access_hidden.sql'];
    await expect(shouldAutoSeedMigrationLedger(pool, manifest)).resolves.toBe(false);
  });

  test('shouldAutoSeedMigrationLedger is false when any manifest migration is recorded', async () => {
    const pool = mockPool([
      { rows: [{ exists: true }] },
      { rows: [{ name: '001_add_pet_access_hidden.sql' }] },
    ]);
    const manifest = ['001_add_pet_access_hidden.sql', '002_add_missing_pet_columns.sql'];
    await expect(shouldAutoSeedMigrationLedger(pool, manifest)).resolves.toBe(false);
  });

  test('seedMigrationLedger inserts only missing manifest rows', async () => {
    const inserts = [];
    const pool = mockPool([
      { rows: [{ name: '001_add_pet_access_hidden.sql' }] },
      (sql) => {
        inserts.push(sql);
        return { rows: [] };
      },
    ]);

    const inserted = await seedMigrationLedger(pool, [
      '001_add_pet_access_hidden.sql',
      '002_add_missing_pet_columns.sql',
    ]);

    expect(inserted).toBe(1);
    expect(inserts).toHaveLength(1);
    expect(inserts[0]).toMatch(/INSERT INTO _migrations/);
  });

  test('loadManifest reads manifest from custom path', () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'manifest-'));
    const manifestPath = path.join(dir, 'migration-manifest.json');
    fs.writeFileSync(
      manifestPath,
      JSON.stringify({ incremental_migrations: ['001_test.sql'] })
    );
    expect(loadManifest(manifestPath)).toEqual(['001_test.sql']);
    fs.rmSync(dir, { recursive: true, force: true });
  });
});
