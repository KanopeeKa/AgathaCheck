/**
 * Retire foster / pending_foster wire roles on organization_users (org v4 Phase C).
 * @param {import('pg').PoolClient} client
 */
export async function migrateRetireFosterWireRole(client) {
  const { rowCount: fosterCount } = await client.query(`
    UPDATE organization_users
    SET role = 'associate', updated_at = NOW()
    WHERE role = 'foster'
  `);
  if (fosterCount > 0) {
    console.log(
      `044_org_retire_foster_wire_role: migrated ${fosterCount} foster row(s) to associate`,
    );
  }

  const { rowCount: pendingCount } = await client.query(`
    UPDATE organization_users
    SET role = 'pending_associate', updated_at = NOW()
    WHERE role = 'pending_foster'
  `);
  if (pendingCount > 0) {
    console.log(
      `044_org_retire_foster_wire_role: migrated ${pendingCount} pending_foster row(s) to pending_associate`,
    );
  }

  await client.query(`
    ALTER TABLE organization_users DROP CONSTRAINT IF EXISTS organization_users_role_check
  `);

  await client.query(`
    ALTER TABLE organization_users ADD CONSTRAINT organization_users_role_check
      CHECK (role IN (
        'associate',
        'admin',
        'super_admin',
        'pending_associate',
        'pending_admin',
        'pending_super_admin'
      ))
  `);
}
