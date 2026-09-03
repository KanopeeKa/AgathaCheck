/**
 * Add users.pinned_organization_id (nullable FK → organizations, ON DELETE SET NULL)
 * and clear pin when org membership is removed or becomes pending.
 * @param {import('pg').PoolClient} client
 */
export async function migratePinnedOrganizationId(client) {
  await client.query(`
    ALTER TABLE users
      ADD COLUMN IF NOT EXISTS pinned_organization_id UUID
        REFERENCES organizations(id) ON DELETE SET NULL
  `);

  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_users_pinned_organization_id
      ON users (pinned_organization_id)
      WHERE pinned_organization_id IS NOT NULL
  `);

  await client.query(`
    CREATE OR REPLACE FUNCTION clear_pinned_org_on_membership_loss()
    RETURNS TRIGGER AS $$
    BEGIN
      IF TG_OP = 'DELETE' THEN
        UPDATE users
           SET pinned_organization_id = NULL,
               updated_at = NOW()
         WHERE id = OLD.user_id
           AND pinned_organization_id = OLD.organization_id;
        RETURN OLD;
      END IF;

      IF TG_OP = 'UPDATE'
         AND NEW.role LIKE 'pending_%'
         AND (OLD.role IS NULL OR OLD.role NOT LIKE 'pending_%') THEN
        UPDATE users
           SET pinned_organization_id = NULL,
               updated_at = NOW()
         WHERE id = NEW.user_id
           AND pinned_organization_id = NEW.organization_id;
      END IF;

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
  `);

  await client.query(`
    DROP TRIGGER IF EXISTS trg_clear_pinned_org_on_membership_loss
      ON organization_users
  `);

  await client.query(`
    CREATE TRIGGER trg_clear_pinned_org_on_membership_loss
    AFTER DELETE OR UPDATE OF role ON organization_users
    FOR EACH ROW
    EXECUTE FUNCTION clear_pinned_org_on_membership_loss()
  `);
}
