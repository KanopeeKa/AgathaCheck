import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/071_planned_absence_pet_note.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/071_planned_absence_pet_note_down.sql',
);

describe('071_planned_absence_pet_note migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds pet_note column to planned_absence_pets', () => {
    expect(sql).toMatch(/ALTER TABLE planned_absence_pets/);
    expect(sql).toMatch(/pet_note TEXT/);
  });

  it('down migration drops pet_note column', () => {
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS pet_note/);
  });
});
