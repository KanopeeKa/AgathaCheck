import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/088_people_relationship_slots.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/088_people_relationship_slots_down.sql',
);

describe('088_people_relationship_slots migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds sort_order and partial unique indexes with dedupe', () => {
    expect(sql).toMatch(/sort_order\s+SMALLINT\s+NOT\s+NULL\s+DEFAULT\s+0/);
    expect(sql).toMatch(/deactivated_count/);
    expect(sql).toMatch(/RAISE NOTICE/);
    expect(sql).toMatch(/primary_vet/);
    expect(sql).toMatch(/out_of_hours_vet/);
    expect(sql).toMatch(/CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_contact_rel_one_active_primary_vet/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops indexes and sort_order', () => {
    expect(downSql).toMatch(/DROP INDEX IF EXISTS idx_pet_contact_rel_one_active_primary_vet/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS sort_order/);
  });
});
