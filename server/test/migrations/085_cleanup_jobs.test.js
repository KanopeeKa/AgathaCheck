import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(__dirname, '../../../db/migrations/085_cleanup_jobs.sql');
const downPath = path.resolve(__dirname, '../../../db/migrations/085_cleanup_jobs_down.sql');

describe('085_cleanup_jobs migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates cleanup_jobs without gen_random_uuid defaults', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS cleanup_jobs/);
    expect(sql).not.toMatch(/gen_random_uuid/);
    expect(sql).toMatch(/dedupe_key.*UNIQUE/);
    expect(sql).toMatch(/status IN \('pending', 'running', 'succeeded', 'retryable', 'dead'\)/);
    expect(sql).toMatch(/idx_cleanup_jobs_status_next_attempt/);
    expect(sql).toMatch(/idx_cleanup_jobs_correlation_id/);
    expect(sql).not.toMatch(/REFERENCES/);
  });

  it('down migration drops only cleanup_jobs', () => {
    expect(downSql.trim()).toBe('DROP TABLE IF EXISTS cleanup_jobs;');
  });
});
