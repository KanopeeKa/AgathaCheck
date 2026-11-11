import { seedGuardian } from './guardian.js';
import { seedCareItemModelFixture } from './care-item-model-fixture.js';
import { seedCareOccurrences } from './care-occurrences.js';
import { seedAwayPlanning } from './away-planning.js';
import { seedCareScheduleFixture } from './care-schedule-fixture.js';
import { seedHealthCare } from './health-care.js';
import { seedSharingNotifications } from './sharing-notifications.js';
import { ORG_ROLE_ADMIN, ORG_ROLE_SUPER_ADMIN } from '../../../lib/orgRoles.js';
import { DEMO_IDS, DEMO_USERS } from '../demo-constants.js';
import {
  upsertOrgMember,
  upsertOrgPet,
  upsertOrganization,
  upsertUser,
} from '../helpers.js';

/**
 * Minimal org rows still referenced by active scenarios (health-care timeline,
 * sharing-notifications admin notification FK). Replaces deleted frozen seed scenarios.
 */
export async function seedActiveDemoOrgFixtures(client) {
  await upsertUser(client, DEMO_USERS.bob);

  await upsertOrganization(client, {
    id: DEMO_IDS.happyPawsOrg,
    name: 'Happy Paws Clinic',
    type: 'professional',
    bio: 'UAT demo veterinary clinic',
    email: 'clinic@demo.agathatrack.test',
    phone: '+44 20 7946 0958',
    town: 'Springfield',
    administrative_area: 'Demo County',
    description: 'UAT demo veterinary clinic',
    is_discoverable: false,
    photo_url: '',
    logo_url: '',
  });

  await upsertOrganization(client, {
    id: DEMO_IDS.rescueHeartsOrg,
    name: 'Rescue Hearts',
    type: 'charity',
    bio: 'Legacy demo org row for notification fixtures',
    email: 'rescue@demo.agathatrack.test',
    phone: '+44 161 496 0123',
    town: 'Riverside',
    administrative_area: 'Demo County',
    description: 'Legacy demo org row for notification fixtures',
    is_discoverable: false,
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
    bio: 'Organisation-held clinic patient for health-care timeline fixture',
  });

  console.log('seed: active-demo-org-fixtures ready (Happy Paws + Rescue Hearts shell)');
}

/** Ordered scenario registry — dependencies flow top to bottom. */
export const SCENARIOS = {
  guardian: seedGuardian,
  'active-demo-org-fixtures': seedActiveDemoOrgFixtures,
  'health-care': seedHealthCare,
  'care-occurrences': seedCareOccurrences,
  'care-schedule-fixture': seedCareScheduleFixture,
  'away-planning': seedAwayPlanning,
  'care-item-model-fixture': seedCareItemModelFixture,
  'sharing-notifications': seedSharingNotifications,
};

/** Composite scenarios excluded from ALL_SCENARIOS. */
export const ALL_SCENARIOS_EXCLUSIONS = [];

/** Full rich demo dataset for UAT and demos. */
export const ALL_SCENARIOS = [
  'guardian',
  'active-demo-org-fixtures',
  'health-care',
  'care-occurrences',
  'care-schedule-fixture',
  'away-planning',
  'care-item-model-fixture',
  'sharing-notifications',
];
