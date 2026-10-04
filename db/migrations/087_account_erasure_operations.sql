-- Durable account erasure acceptance records (no FK to users — survives user delete).

CREATE TABLE IF NOT EXISTS account_erasure_operations (
  id                    UUID PRIMARY KEY,
  user_id               UUID NOT NULL,
  status                VARCHAR(20) NOT NULL DEFAULT 'accepted'
                          CHECK (status IN ('accepted', 'in_progress', 'completed', 'failed')),
  status_token_hash     VARCHAR(64) NOT NULL,
  requested_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  db_erased_at            TIMESTAMPTZ,
  completed_at            TIMESTAMPTZ,
  failed_at               TIMESTAMPTZ,
  last_error_redacted     TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_account_erasure_operations_user_id
  ON account_erasure_operations (user_id);

CREATE INDEX IF NOT EXISTS idx_account_erasure_operations_status
  ON account_erasure_operations (status);
