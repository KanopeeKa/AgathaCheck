import { ORG_ROLE_ADMIN, ORG_ROLE_SUPER_ADMIN } from '../../../lib/orgRoles.js';
import { DEMO_IDS, DEMO_USERS } from '../demo-constants.js';
import { upsertOrgMember, upsertOrgPet, upsertOrganization, upsertUser } from '../helpers.js';

export async function seedOrgClinic(client) {
  await upsertUser(client, DEMO_USERS.alice);
  await upsertUser(client, DEMO_USERS.bob);

  await upsertOrganization(client, {
    id: DEMO_IDS.happyPawsOrg,
    name: 'Happy Paws Clinic',
    type: 'professional',
    bio: 'UAT demo veterinary clinic — professional organisation with admin team',
    email: 'clinic@demo.agathatrack.test',
    phone: '+44 20 7946 0958',
    town: 'Springfield',
    administrative_area: 'Demo County',
    description: 'UAT demo veterinary clinic (discoverable)',
    is_discoverable: true,
    photo_url: '',
    logo_url: '',
  });

  await upsertOrgMember(client, {
    id: DEMO_IDS.aliceHappyPawsOrgUser,
    orgId: DEMO_IDS.happyPawsOrg,
    userId: DEMO_IDS.alice,
    role: ORG_ROLE_SUPER_ADMIN,
  });

  await upsertOrgMember(client, {
    id: DEMO_IDS.bobHappyPawsOrgUser,
    orgId: DEMO_IDS.happyPawsOrg,
    userId: DEMO_IDS.bob,
    role: ORG_ROLE_ADMIN,
  });

  await upsertOrgPet(client, {
    id: DEMO_IDS.clinicPet,
    userId: DEMO_IDS.alice,
    orgId: DEMO_IDS.happyPawsOrg,
    name: 'Clinic Cat',
    species: 'Cat',
    breed: 'British Shorthair',
    gender: 'Female',
    bio: 'Organisation-held clinic patient for org pet management demos',
  });

  await client.query(
    `INSERT INTO organization_permissions (
       id, organization_id, user_id, permission_key, source, granted_by
     )
     VALUES ($1, $2, $3, $4, 'individual', $5)
     ON CONFLICT (id) DO UPDATE SET
       revoked_at = NULL,
       granted_at = NOW()`,
    [
      DEMO_IDS.bobManagePetsPermission,
      DEMO_IDS.happyPawsOrg,
      DEMO_IDS.bob,
      'manage_pets',
      DEMO_IDS.alice,
    ],
  );

  console.log('seed: org-clinic scenario ready (Happy Paws Clinic)');
}
