-- Support intake: tickets, attachments, outbox, staff flag (phase 3).

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_support_staff BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS support_tickets (
  id                      UUID PRIMARY KEY,
  reference               VARCHAR(16) NOT NULL UNIQUE,
  user_id                 UUID REFERENCES users(id) ON DELETE CASCADE,
  reporter_email          VARCHAR(254) NOT NULL,
  reporter_email_normalised VARCHAR(254) NOT NULL,
  signed_in               BOOLEAN NOT NULL,
  submit_ip               VARCHAR(64),
  category                VARCHAR(32) NOT NULL
                            CHECK (category IN ('bug', 'suggestion', 'account', 'billing')),
  title                   VARCHAR(120) NOT NULL,
  description             TEXT NOT NULL CHECK (char_length(description) <= 5000),
  expected                TEXT CHECK (expected IS NULL OR char_length(expected) <= 2000),
  actual                  TEXT CHECK (actual IS NULL OR char_length(actual) <= 2000),
  steps                   TEXT CHECK (steps IS NULL OR char_length(steps) <= 3000),
  frequency               VARCHAR(16)
                            CHECK (frequency IS NULL OR frequency IN ('always', 'sometimes', 'once')),
  context                 JSONB NOT NULL DEFAULT '{}'::jsonb,
  locale                  VARCHAR(16) NOT NULL,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  github_issue_number     INTEGER
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user_created
  ON support_tickets (user_id, created_at)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_tickets_email_norm_created
  ON support_tickets (reporter_email_normalised, created_at);

CREATE INDEX IF NOT EXISTS idx_support_tickets_submit_ip_created
  ON support_tickets (submit_ip, created_at)
  WHERE signed_in = false AND submit_ip IS NOT NULL;

CREATE TABLE IF NOT EXISTS support_attachments (
  id            UUID PRIMARY KEY,
  ticket_id     UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  storage_key   TEXT NOT NULL,
  mime          VARCHAR(128) NOT NULL,
  bytes         INTEGER NOT NULL CHECK (bytes > 0),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_attachments_ticket_id
  ON support_attachments (ticket_id);

CREATE TABLE IF NOT EXISTS support_outbox (
  id                    UUID PRIMARY KEY,
  ticket_id             UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
  kind                  VARCHAR(32) NOT NULL
                          CHECK (kind IN ('receipt', 'github_issue', 'github_issue_delete')),
  github_issue_number   INTEGER,
  status                VARCHAR(20) NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'sent', 'failed', 'blocked', 'disabled')),
  attempts              INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  next_attempt_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_error            TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT support_outbox_ticket_kind_required CHECK (
    (kind IN ('receipt', 'github_issue') AND ticket_id IS NOT NULL)
    OR (kind = 'github_issue_delete' AND ticket_id IS NULL)
  ),
  CONSTRAINT support_outbox_delete_issue_required CHECK (
    kind <> 'github_issue_delete' OR github_issue_number IS NOT NULL
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS support_outbox_ticket_kind_uidx
  ON support_outbox (ticket_id, kind)
  WHERE kind IN ('receipt', 'github_issue');

CREATE UNIQUE INDEX IF NOT EXISTS support_outbox_delete_kind_issue_uidx
  ON support_outbox (kind, github_issue_number)
  WHERE kind = 'github_issue_delete';

CREATE INDEX IF NOT EXISTS idx_support_outbox_status_next_attempt
  ON support_outbox (status, next_attempt_at);
