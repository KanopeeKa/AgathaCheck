import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/064_planned_absence_handover.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/064_planned_absence_handover_down.sql',
);

describe('064_planned_absence_handover migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds handover note and download timestamp columns', () => {
    expect(sql).toMatch(/ALTER TABLE planned_absences/);
    expect(sql).toMatch(/handover_note TEXT/);
    expect(sql).toMatch(/last_handover_downloaded_at TIMESTAMPTZ/);
  });

  it('down migration drops handover columns', () => {
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS last_handover_downloaded_at/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS handover_note/);
  });
});
