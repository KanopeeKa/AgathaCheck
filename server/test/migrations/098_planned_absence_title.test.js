import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/098_planned_absence_title.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/098_planned_absence_title_down.sql');

describe('098_planned_absence_title migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('adds nullable title column with length limit', () => {
    expect(sql).toMatch(/ALTER TABLE planned_absences/);
    expect(sql).toMatch(/title VARCHAR\(60\)/);
  });

  it('down migration drops title', () => {
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS title/);
  });
});
