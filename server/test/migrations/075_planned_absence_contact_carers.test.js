import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/075_planned_absence_contact_carers.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/075_planned_absence_contact_carers_down.sql',
);

describe('075_planned_absence_contact_carers migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds contact_id to planned_absence_pets', () => {
    expect(sql).toMatch(/ADD COLUMN IF NOT EXISTS contact_id UUID/);
    expect(sql).toMatch(/REFERENCES people_contacts\(id\) ON DELETE SET NULL/);
    expect(sql).toMatch(/idx_planned_absence_pets_contact_id/);
  });

  it('down migration drops contact_id column', () => {
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS contact_id/);
  });
});
