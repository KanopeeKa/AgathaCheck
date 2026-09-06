-- F-06: server-side refresh sessions with rotation and reuse detection
CREATE TABLE IF NOT EXISTS refresh_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  family_id UUID NOT NULL,
  rotated_from UUID NULL REFERENCES refresh_sessions(id) ON DELETE SET NULL,
  revoked_at TIMESTAMPTZ NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_refresh_sessions_token_hash
  ON refresh_sessions (token_hash);

CREATE INDEX IF NOT EXISTS idx_refresh_sessions_user_id
  ON refresh_sessions (user_id);

CREATE INDEX IF NOT EXISTS idx_refresh_sessions_family_id
  ON refresh_sessions (family_id);
