/**
 * Org-level default permission sets per role tier (v4 Phase F).
 * @param {import('pg').PoolClient} client
 */
export async function migrateOrganizationRolePermissionDefaults(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS organization_role_permission_defaults (
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      role_tier VARCHAR(16) NOT NULL,
      permission_key VARCHAR(64) NOT NULL,
      granted BOOLEAN NOT NULL DEFAULT true,
      PRIMARY KEY (organization_id, role_tier, permission_key),
      CONSTRAINT organization_role_permission_defaults_tier_check
        CHECK (role_tier IN ('associate', 'admin'))
    )
  `);

  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_org_role_permission_defaults_org_tier
      ON organization_role_permission_defaults (organization_id, role_tier)
  `);
}
