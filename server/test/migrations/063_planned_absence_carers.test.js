import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/063_planned_absence_carers.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/063_planned_absence_carers_down.sql',
);

describe('063_planned_absence_carers migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds per-pet carer columns with kind and cross-field checks', () => {
    expect(sql).toMatch(/ALTER TABLE planned_absence_pets/);
    expect(sql).toMatch(/carer_kind TEXT/);
    expect(sql).toMatch(/carer_user_id UUID REFERENCES users\(id\) ON DELETE SET NULL/);
    expect(sql).toMatch(/carer_name TEXT/);
    expect(sql).toMatch(/carer_note TEXT/);
    expect(sql).toMatch(/planned_absence_pets_carer_kind_check/);
    expect(sql).toMatch(/'shared_user', 'note_only'/);
    expect(sql).toMatch(/planned_absence_pets_carer_fields_check/);
    expect(sql).toMatch(/carer_kind = 'note_only'/);
    expect(sql).toMatch(/carer_name IS NOT NULL/);
  });

  it('down migration drops constraints and columns', () => {
    expect(downSql).toMatch(/DROP CONSTRAINT IF EXISTS planned_absence_pets_carer_fields_check/);
    expect(downSql).toMatch(/DROP CONSTRAINT IF EXISTS planned_absence_pets_carer_kind_check/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS carer_note/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS carer_name/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS carer_user_id/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS carer_kind/);
  });
});
