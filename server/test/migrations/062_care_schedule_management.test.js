import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const migrationPath = path.resolve(
  __dirname,
  '../../../db/migrations/062_care_schedule_management.sql',
);
const downPath = path.resolve(
  __dirname,
  '../../../db/migrations/062_care_schedule_management_down.sql',
);

describe('062_care_schedule_management migration', () => {
  const sql = fs.readFileSync(migrationPath, 'utf8');
  const downSql = fs.readFileSync(downPath, 'utf8');

  it('creates care_schedule_events ledger with event types and idempotency index', () => {
    expect(sql).toMatch(/CREATE TABLE IF NOT EXISTS care_schedule_events/);
    expect(sql).toMatch(/event_type IN \('rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted'\)/);
    expect(sql).toMatch(/idx_care_schedule_events_idempotency/);
    expect(sql).toMatch(/health_entry_id UUID NOT NULL REFERENCES health_entries/);
    expect(sql).toMatch(/health_occurrence_id UUID REFERENCES health_occurrences/);
  });

  it('adds scheduling columns to health_entries and health_occurrences', () => {
    expect(sql).toMatch(/paused_since DATE/);
    expect(sql).toMatch(/schedule_policy_version VARCHAR\(20\)/);
    expect(sql).toMatch(/completion_timing VARCHAR\(20\)/);
    expect(sql).toMatch(/health_occurrences_completion_timing_check/);
    expect(sql).toMatch(/'early', 'on_time', 'late'/);
  });

  it('down migration drops ledger and columns', () => {
    expect(downSql).toMatch(/DROP TABLE IF EXISTS care_schedule_events/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS completion_timing/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS schedule_policy_version/);
    expect(downSql).toMatch(/DROP COLUMN IF EXISTS paused_since/);
  });
});
