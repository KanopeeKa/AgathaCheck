-- Lease columns for suggestion daily scheduler: stale in-flight reclaim (>1h).

ALTER TABLE scheduler_daily_runs
  ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
