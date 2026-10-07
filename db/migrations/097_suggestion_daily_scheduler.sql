-- Cluster-safe once-per-UTC-day guard for suggestion generation (multi-instance hosts).

CREATE TABLE IF NOT EXISTS scheduler_daily_runs (
  job_key    VARCHAR(64) PRIMARY KEY,
  run_day    DATE NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
