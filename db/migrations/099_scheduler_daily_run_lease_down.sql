ALTER TABLE scheduler_daily_runs
  DROP COLUMN IF EXISTS completed_at,
  DROP COLUMN IF EXISTS claimed_at;
