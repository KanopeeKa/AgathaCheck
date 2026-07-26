ALTER TABLE document_templates DROP COLUMN IF EXISTS is_public;

ALTER TABLE organization_users DROP CONSTRAINT IF EXISTS organization_users_role_check;

DROP INDEX IF EXISTS idx_org_permissions_org_user;
DROP INDEX IF EXISTS idx_org_permissions_active;
DROP TABLE IF EXISTS organization_permissions;
