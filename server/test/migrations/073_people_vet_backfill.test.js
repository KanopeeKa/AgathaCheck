import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/073_people_vet_backfill.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/073_people_vet_backfill_down.sql',
);

describe('073_people_vet_backfill migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds legacy_vet_id on people_contacts', () => {
    expect(sql).toMatch(/legacy_vet_id\s+UUID\s+UNIQUE/);
    expect(sql).toMatch(/REFERENCES vets\(id\) ON DELETE SET NULL/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops legacy_vet_id column', () => {
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS legacy_vet_id/);
  });
});
