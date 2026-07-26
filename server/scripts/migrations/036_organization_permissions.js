/**
 * Create organization_permissions, extend wire roles, backfill empty roles to associate.
 * @param {import('pg').PoolClient} client
 */
export async function migrateOrganizationPermissions(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS organization_permissions (
      id UUID PRIMARY KEY,
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      permission_key VARCHAR(64) NOT NULL,
      source VARCHAR(32) NOT NULL DEFAULT 'individual',
      granted_by UUID NOT NULL REFERENCES users(id),
      granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      revoked_at TIMESTAMPTZ,
      revoked_by UUID REFERENCES users(id)
    )
  `);

  await client.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_org_permissions_active
      ON organization_permissions (organization_id, user_id, permission_key)
      WHERE revoked_at IS NULL
  `);

  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_org_permissions_org_user
      ON organization_permissions (organization_id, user_id)
  `);

  await client.query(`
    ALTER TABLE organization_users DROP CONSTRAINT IF EXISTS organization_users_role_check
  `);

  await client.query(`
    ALTER TABLE organization_users ADD CONSTRAINT organization_users_role_check
      CHECK (role IN (
        'associate',
        'foster',
        'admin',
        'super_admin',
        'pending_associate',
        'pending_foster',
        'pending_admin',
        'pending_super_admin'
      ))
  `);

  await client.query(`
    ALTER TABLE document_templates
      ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT false
  `);

  const { rows: distribution } = await client.query(`
    SELECT COALESCE(NULLIF(TRIM(role), ''), '<empty>') AS role, COUNT(*)::int AS count
    FROM organization_users
    GROUP BY 1
    ORDER BY 1
  `);
  console.log(
    '036_organization_permissions: organization_users.role distribution:',
    JSON.stringify(distribution)
  );

  const { rowCount } = await client.query(`
    UPDATE organization_users
    SET role = 'associate', updated_at = NOW()
    WHERE role IS NULL OR TRIM(role) = ''
  `);
  if (rowCount > 0) {
    console.log(
      `036_organization_permissions: backfilled ${rowCount} membership row(s) to associate`
    );
  }
}
