/**
 * Backfill organization_users privacy columns from legacy foster prefs.
 * @param {import('pg').PoolClient} client
 */
import { v4 as uuidv4 } from 'uuid';
import {
  defaultPrivacyForRole,
  enforceCardVisibilityFloor,
  mapLegacyFosterVisibility,
  normaliseAddressVisibility,
  normaliseContactVisibility,
} from '../../lib/orgMemberPrivacy.js';
import { normaliseRole } from '../../lib/orgRoles.js';

/**
 * @param {import('pg').PoolClient} client
 */
export async function migrateOrgMemberPrivacy(client) {
  const { rows: memberships } = await client.query(`
    SELECT ou.id,
           ou.organization_id,
           ou.user_id,
           ou.role,
           ou.card_visibility,
           ou.phone_visibility,
           ou.email_visibility,
           ou.address_visibility,
           ofp.visible_to,
           ofp.contact_visibility,
           ofp.address_visibility AS foster_address_visibility
    FROM organization_users ou
    LEFT JOIN org_foster_parents ofp
      ON ofp.organization_id = ou.organization_id
     AND ofp.user_id = ou.user_id
  `);

  let updated = 0;
  for (const row of memberships) {
    const role = normaliseRole(row.role);
    const defaults = defaultPrivacyForRole(role);
    let cardVisibility = row.card_visibility || defaults.card_visibility;
    let phoneVisibility = row.phone_visibility || defaults.phone_visibility;
    let emailVisibility = row.email_visibility || defaults.email_visibility;
    let addressVisibility = row.address_visibility || defaults.address_visibility;

    if (row.visible_to || row.contact_visibility || row.foster_address_visibility) {
      const mapped = mapLegacyFosterVisibility({
        visible_to: row.visible_to,
        contact_visibility: row.contact_visibility,
        address_visibility: row.foster_address_visibility,
      });
      if (!row.card_visibility || row.card_visibility === defaults.card_visibility) {
        cardVisibility = mapped.card_visibility;
      }
      if (!row.phone_visibility || row.phone_visibility === defaults.phone_visibility) {
        phoneVisibility = mapped.phone_visibility;
      }
      if (!row.email_visibility || row.email_visibility === defaults.email_visibility) {
        emailVisibility = mapped.email_visibility;
      }
      if (!row.address_visibility || row.address_visibility === defaults.address_visibility) {
        addressVisibility = mapped.address_visibility;
      }
    }

    cardVisibility = enforceCardVisibilityFloor(cardVisibility, role);
    phoneVisibility = normaliseContactVisibility(phoneVisibility, defaults.phone_visibility);
    emailVisibility = normaliseContactVisibility(emailVisibility, defaults.email_visibility);
    addressVisibility = normaliseAddressVisibility(addressVisibility);

    const needsUpdate =
      cardVisibility !== row.card_visibility
      || phoneVisibility !== row.phone_visibility
      || emailVisibility !== row.email_visibility
      || addressVisibility !== row.address_visibility;

    if (!needsUpdate) continue;

    await client.query(
      `UPDATE organization_users
       SET card_visibility = $1,
           phone_visibility = $2,
           email_visibility = $3,
           address_visibility = $4,
           updated_at = NOW()
       WHERE id = $5`,
      [cardVisibility, phoneVisibility, emailVisibility, addressVisibility, row.id],
    );
    updated += 1;
  }

  if (updated > 0) {
    console.log(`042_org_member_privacy: backfilled ${updated} membership privacy row(s)`);
  }

  // Ensure grants table exists when SQL stub-only migrations run in tests.
  await client.query(`
    CREATE TABLE IF NOT EXISTS organization_visibility_grants (
      id UUID PRIMARY KEY,
      organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      subject_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      grantee_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      field TEXT NOT NULL CHECK (field IN ('card', 'phone', 'email', 'address')),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (organization_id, subject_user_id, grantee_user_id, field)
    )
  `);

  // Placeholder for future admin-phone column if added — no-op today.
  void uuidv4;
}
