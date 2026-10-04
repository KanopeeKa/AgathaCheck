import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/092_weight_monitoring_unify.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/092_weight_monitoring_unify_down.sql');

describe('092_weight_monitoring_unify migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('U-9 converts lb rows, enforces kg unit and adds users.weight_unit', () => {
    expect(sql).toMatch(/weight \* 0\.45359237/);
    expect(sql).toMatch(/weight_entries_unit_kg_check/);
    expect(sql).toMatch(/users_weight_unit_check/);
    expect(sql).toMatch(/ADD COLUMN weight_unit/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down drops constraints and weight_unit without reverting kg values', () => {
    expect(downSql).toMatch(/DROP CONSTRAINT IF EXISTS users_weight_unit_check/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS weight_unit/);
    expect(downSql).toMatch(/converted lb values are not restored/i);
  });
});
