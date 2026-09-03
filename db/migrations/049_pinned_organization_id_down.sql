DROP TRIGGER IF EXISTS trg_clear_pinned_org_on_membership_loss ON organization_users;
DROP FUNCTION IF EXISTS clear_pinned_org_on_membership_loss();
DROP INDEX IF EXISTS idx_users_pinned_organization_id;
ALTER TABLE users DROP COLUMN IF EXISTS pinned_organization_id;
