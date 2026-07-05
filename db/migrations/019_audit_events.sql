-- Centralized audit trail for security, support, and compliance.
-- Retention tiers (hot → warm → cold) are enforced by server/scripts/audit-retention.js.

CREATE TABLE IF NOT EXISTS audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  actor_user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
  actor_pseudonym TEXT NULL,
  actor_type TEXT NOT NULL DEFAULT 'user'
    CHECK (actor_type IN ('user', 'system', 'support')),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT NULL,
  org_id UUID NULL,
  pet_id VARCHAR(255) NULL,
  outcome TEXT NOT NULL DEFAULT 'success'
    CHECK (outcome IN ('success', 'failure')),
  metadata JSONB NOT NULL DEFAULT '{}',
  request_id TEXT NULL,
  ip_address INET NULL,
  user_agent TEXT NULL,
  retention_tier TEXT NOT NULL DEFAULT 'hot'
    CHECK (retention_tier IN ('hot', 'warm', 'cold'))
);

CREATE INDEX IF NOT EXISTS idx_audit_events_occurred_at ON audit_events (occurred_at);
CREATE INDEX IF NOT EXISTS idx_audit_events_actor_user_id
  ON audit_events (actor_user_id) WHERE actor_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_events_resource
  ON audit_events (resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_pet_id
  ON audit_events (pet_id) WHERE pet_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_events_org_id
  ON audit_events (org_id) WHERE org_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_events_retention_tier
  ON audit_events (retention_tier, occurred_at);
CREATE INDEX IF NOT EXISTS idx_audit_events_action ON audit_events (action);
