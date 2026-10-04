-- Durable cleanup jobs (file deletion, required notifications). No FKs — jobs survive cascades.

CREATE TABLE IF NOT EXISTS cleanup_jobs (
  id                    UUID PRIMARY KEY,
  job_type              VARCHAR(64) NOT NULL,
  dedupe_key            VARCHAR(255) NOT NULL UNIQUE,
  correlation_id        UUID,
  payload               JSONB DEFAULT '{}'::jsonb,
  status                VARCHAR(20) NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'running', 'succeeded', 'retryable', 'dead')),
  attempts              INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  max_attempts          INTEGER NOT NULL DEFAULT 8 CHECK (max_attempts > 0),
  next_attempt_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  lease_token           UUID,
  lease_expires_at      TIMESTAMPTZ,
  last_error_redacted   TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_cleanup_jobs_status_next_attempt
  ON cleanup_jobs (status, next_attempt_at);

CREATE INDEX IF NOT EXISTS idx_cleanup_jobs_correlation_id
  ON cleanup_jobs (correlation_id)
  WHERE correlation_id IS NOT NULL;
