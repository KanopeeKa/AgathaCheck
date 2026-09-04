import { ORG_ROLE_ASSOCIATE, ORG_ROLE_SUPER_ADMIN } from '../../../lib/orgRoles.js';
import { DEMO_IDS, DEMO_USERS } from '../demo-constants.js';
import {
  calendarDaysFromToday,
  upsertOrgMember,
  upsertOrgPet,
  upsertOrganization,
  upsertPersonalPet,
  upsertUser,
} from '../helpers.js';

/** Minimal Rescue Hearts org row for org-v3-demo / connections (no pets or fosters). */
export async function seedRescueHeartsOrgShell(client) {
  await upsertUser(client, DEMO_USERS.alice);

  await upsertOrganization(client, {
    id: DEMO_IDS.rescueHeartsOrg,
    name: 'Rescue Hearts',
    type: 'charity',
    bio: 'UAT demo connected rescue charity',
    email: 'rescue@demo.agathatrack.test',
    phone: '+44 161 496 0123',
    town: 'Riverside',
    administrative_area: 'Demo County',
    description: 'Partner charity for connections and discover demos',
    is_discoverable: true,
    photo_url: '',
    logo_url: '',
  });

  await upsertOrgMember(client, {
    id: DEMO_IDS.aliceRescueOrgUser,
    orgId: DEMO_IDS.rescueHeartsOrg,
    userId: DEMO_IDS.alice,
    role: ORG_ROLE_SUPER_ADMIN,
  });
}

export async function seedRescueHearts(client) {
  await upsertUser(client, DEMO_USERS.eve);
  await upsertUser(client, DEMO_USERS.dave);
  await upsertUser(client, DEMO_USERS.grace);

  await seedRescueHeartsOrgShell(client);

  await upsertOrgMember(client, {
    id: DEMO_IDS.eveRescueOrgUser,
    orgId: DEMO_IDS.rescueHeartsOrg,
    userId: DEMO_IDS.eve,
    role: ORG_ROLE_ASSOCIATE,
  });

  await upsertOrgMember(client, {
    id: DEMO_IDS.daveRescueOrgUser,
    orgId: DEMO_IDS.rescueHeartsOrg,
    userId: DEMO_IDS.dave,
    role: ORG_ROLE_ASSOCIATE,
  });

  await upsertPersonalPet(client, {
    id: DEMO_IDS.davePersonalPet,
    userId: DEMO_IDS.dave,
    name: 'Pip',
    species: 'dog',
    breed: 'Terrier mix',
    dateOfBirth: calendarDaysFromToday(-365 * 2),
    weight: 8.5,
    gender: 'male',
    bio: 'Dave personal pet — dual-role demo user',
  });

  await upsertOrgPet(client, {
    id: DEMO_IDS.maxPet,
    userId: DEMO_IDS.alice,
    orgId: DEMO_IDS.rescueHeartsOrg,
    name: 'Max',
    species: 'dog',
    breed: 'Border Collie',
    dateOfBirth: calendarDaysFromToday(-365 * 2),
    weight: 18.0,
    gender: 'male',
    bio: 'Active foster placement with Eve',
  });

  await upsertOrgPet(client, {
    id: DEMO_IDS.lunaPet,
    userId: DEMO_IDS.alice,
    orgId: DEMO_IDS.rescueHeartsOrg,
    name: 'Luna',
    species: 'cat',
    breed: 'Tabby',
    dateOfBirth: calendarDaysFromToday(-365),
    weight: 3.8,
    gender: 'female',
    bio: 'Available for adoption — scheduled visit with prospect',
  });

  await upsertOrgPet(client, {
    id: DEMO_IDS.rockyPet,
    userId: DEMO_IDS.alice,
    orgId: DEMO_IDS.rescueHeartsOrg,
    name: 'Rocky',
    species: 'dog',
    breed: 'Staffordshire Bull Terrier',
    dateOfBirth: calendarDaysFromToday(-365 * 3),
    weight: 16.5,
    gender: 'male',
    bio: 'Foster-to-adopt journey in progress',
  });

  await upsertOrgPet(client, {
    id: DEMO_IDS.mittensPet,
    userId: DEMO_IDS.alice,
    orgId: DEMO_IDS.rescueHeartsOrg,
    name: 'Mittens',
    species: 'cat',
    breed: 'Domestic Longhair',
    dateOfBirth: calendarDaysFromToday(-365 * 5),
    weight: 4.5,
    gender: 'female',
    bio: 'Completed foster placement — historical record',
  });

  await client.query(
    `INSERT INTO document_templates (
       id, organization_id, template_key, template_type, label, description,
       sort_order, is_required, is_public
     )
     VALUES
       ($1, $3, 'home_check', 'adoption_milestone', 'Home check completed',
        'Confirm home environment is suitable', 1, true, false),
       ($2, $3, 'intake_checklist', 'session_checklist', 'Foster intake checklist',
        'Initial foster session checklist items', 1, false, false)
     ON CONFLICT (id) DO UPDATE SET
       label = EXCLUDED.label,
       description = EXCLUDED.description,
       sort_order = EXCLUDED.sort_order,
       is_required = EXCLUDED.is_required,
       updated_at = NOW()`,
    [
      DEMO_IDS.rescueAdoptionChecklist,
      DEMO_IDS.rescueSessionChecklist,
      DEMO_IDS.rescueHeartsOrg,
    ],
  );

  console.log('seed: rescue-hearts scenario ready (Rescue Hearts charity)');
}
