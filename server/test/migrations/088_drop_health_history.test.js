import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/088_drop_health_history.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/088_drop_health_history_down.sql',
);

describe('088_drop_health_history migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('logs row count and drops health_history', () => {
    expect(sql).toMatch(/health_history/);
    expect(sql).toMatch(/RAISE NOTICE/);
    expect(sql).toMatch(/DROP TABLE IF EXISTS public\.health_history/);
    expect(sql).not.toMatch(/gen_random_uuid/);
  });

  it('down migration recreates empty health_history with constraints', () => {
    expect(downSql).toMatch(/CREATE TABLE IF NOT EXISTS public\.health_history/);
    expect(downSql).toMatch(/health_history_pkey/);
    expect(downSql).toMatch(/health_history_health_entry_id_fkey/);
    expect(downSql).toMatch(/health_history_marked_by_user_id_fkey/);
  });
});
