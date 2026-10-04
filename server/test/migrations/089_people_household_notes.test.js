import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/089_people_household_notes.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/089_people_household_notes_down.sql',
);

describe('089_people_household_notes migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates people_contact_household_notes with cascades', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS people_contact_household_notes/);
    expect(sql).toMatch(/PRIMARY KEY \(contact_id, household_id\)/);
    expect(sql).toMatch(/REFERENCES people_contacts\(id\) ON DELETE CASCADE/);
    expect(sql).toMatch(/REFERENCES households\(id\) ON DELETE CASCADE/);
    expect(sql).toMatch(/updated_by_user_id.*ON DELETE SET NULL/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration drops the table', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS people_contact_household_notes/);
  });
});
