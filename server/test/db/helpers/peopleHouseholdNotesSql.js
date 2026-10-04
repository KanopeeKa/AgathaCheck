import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const migrationPath = path.resolve(
  __dirname,
  '../../../../db/migrations/089_people_household_notes.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../../db/migrations/089_people_household_notes_down.sql',
);

export async function applyPeopleHouseholdNotesMigration(pool) {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  await pool.query(sql);
}

export async function applyPeopleHouseholdNotesDown(pool) {
  const sql = fs.readFileSync(downPath, 'utf8');
  await pool.query(sql);
}
