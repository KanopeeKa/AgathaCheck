/**
 * Stable demo identities for UAT and demos.
 * Credential table: docs/e2e/uat-demo-personas.md (validated by server/test/seed.test.js).
 */

/** Shared demo password — acceptable only on isolated non-prod databases. */
export const DEMO_PASSWORD = 'PassTest';
export const DEMO_PASSWORD_HASH =
  '$2b$10$hvdaHaNIByRvzJR99.3B4O1eVrBrCfdxJRqHeXaeTBpVdwvjUj9xm';

export const DEMO_IDS = {
  // Users
  alice: 'a1000001-0001-4001-8001-000000000001',
  bob: 'a1000001-0001-4001-8001-000000000002',
  carol: 'a1000001-0001-4001-8001-000000000003',
  eve: 'a1000001-0001-4001-8001-000000000004',
  dave: 'a1000001-0001-4001-8001-000000000005',
  grace: 'a1000001-0001-4001-8001-000000000006',

  // Organizations
  happyPawsOrg: 'a2000001-0001-4001-8001-000000000001',
  rescueHeartsOrg: 'a2000001-0001-4001-8001-000000000002',
  /** @deprecated Use rescueHeartsOrg — kept for org-v3-demo compatibility */
  partnerPawsOrg: 'a2000001-0001-4001-8001-000000000002',

  // Organization memberships
  aliceHappyPawsOrgUser: 'a3000001-0001-4001-8001-000000000001',
  bobHappyPawsOrgUser: 'a3000001-0001-4001-8001-000000000002',
  /** @deprecated Use aliceHappyPawsOrgUser */
  aliceOrgUser: 'a3000001-0001-4001-8001-000000000001',
  /** @deprecated Use bobHappyPawsOrgUser */
  bobOrgUser: 'a3000001-0001-4001-8001-000000000002',
  aliceRescueOrgUser: 'a3000001-0001-4001-8001-000000000003',
  eveRescueOrgUser: 'a3000001-0001-4001-8001-000000000004',
  daveRescueOrgUser: 'a3000001-0001-4001-8001-000000000005',

  // Pets
  buddyPet: 'a4000001-0001-4001-8001-000000000001',
  clinicPet: 'a4000001-0001-4001-8001-000000000002',
  whiskersPet: 'a4000001-0001-4001-8001-000000000003',
  maxPet: 'a4000001-0001-4001-8001-000000000004',
  lunaPet: 'a4000001-0001-4001-8001-000000000005',
  rockyPet: 'a4000001-0001-4001-8001-000000000006',
  mittensPet: 'a4000001-0001-4001-8001-000000000007',
  davePersonalPet: 'a4000001-0001-4001-8001-000000000008',

  // Vets
  aliceVet: 'a5000001-0001-4001-8001-000000000001',

  // Health entries
  buddyVaccine: 'a6000001-0001-4001-8001-000000000001',
  buddyMedication: 'a6000001-0001-4001-8001-000000000002',
  buddyOverduePreventive: 'a6000001-0001-4001-8001-000000000003',
  whiskersVetVisit: 'a6000001-0001-4001-8001-000000000004',
  maxFleaTreatment: 'a6000001-0001-4001-8001-000000000005',

  // Health issues
  buddySkinIssue: 'a6100001-0001-4001-8001-000000000001',

  // Weight entries
  buddyWeight1: 'a6200001-0001-4001-8001-000000000001',
  buddyWeight2: 'a6200001-0001-4001-8001-000000000002',
  whiskersWeight: 'a6200001-0001-4001-8001-000000000003',

  // Foster parents / profiles
  eveFosterProfile: 'a7000001-0001-4001-8001-000000000001',
  eveOrgFosterParent: 'a7000001-0001-4001-8001-000000000002',

  // Foster placements
  maxActivePlacement: 'a7100001-0001-4001-8001-000000000001',
  rockyAdoptionPlacement: 'a7100001-0001-4001-8001-000000000002',
  mittensCompletedPlacement: 'a7100001-0001-4001-8001-000000000003',

  // Adoption
  rockyAdoptionJourney: 'a7200001-0001-4001-8001-000000000001',
  lunaProspect: 'a7200001-0001-4001-8001-000000000002',
  lunaAdoptionVisit: 'a7200001-0001-4001-8001-000000000003',

  // Foster requests
  rescueFosterRequest: 'a7300001-0001-4001-8001-000000000001',
  rescueFosterRequestResponse: 'a7300001-0001-4001-8001-000000000002',

  // Sharing
  whiskersShareLink: 'a8000001-0001-4001-8001-000000000001',
  carolPetAccess: 'a8000001-0001-4001-8001-000000000002',
  carolSharedPet: 'a8000001-0001-4001-8001-000000000003',

  // Notifications
  buddyOverdueNotification: 'a8100001-0001-4001-8001-000000000001',
  rescueAdminNotification: 'a8100001-0001-4001-8001-000000000002',
  aliceHealthReminderPref: 'a8110001-0001-4001-8001-000000000001',
  aliceFosterUpdatePref: 'a8110001-0001-4001-8001-000000000002',

  // Foster request targets
  rescueFosterRequestTarget: 'a7300001-0001-4001-8001-000000000003',

  // Pet activity
  clinicPetActivityEvent: 'a8800001-0001-4001-8001-000000000001',

  // Legacy alias
  /** @deprecated Use whiskersShareLink */
  buddyShareLink: 'a8000001-0001-4001-8001-000000000001',

  // Org connections
  orgConnection: 'a8200001-0001-4001-8001-000000000001',

  // Document templates
  rescueAdoptionChecklist: 'a8300001-0001-4001-8001-000000000001',
  rescueSessionChecklist: 'a8300001-0001-4001-8001-000000000002',

  // Family events
  aliceHolidayEvent: 'a8400001-0001-4001-8001-000000000001',

  // Timeline
  buddyTimelineEntry: 'a8500001-0001-4001-8001-000000000001',

  // Custody transfer (pending)
  lunaCustodyTransfer: 'a8600001-0001-4001-8001-000000000001',

  // Permissions
  bobManagePetsPermission: 'a8700001-0001-4001-8001-000000000001',
};

export const DEMO_USERS = {
  alice: {
    id: DEMO_IDS.alice,
    email: 'frederique.prevost@gmail.com',
    first_name: 'Frederique',
    last_name: 'Prevost',
    display_name: 'Frederique',
    category: 'pet_carer',
    bio: 'Primary demo guardian and clinic super admin',
    role_description:
      'Main test user — pet carer + super admin (Happy Paws Clinic & Rescue Hearts)',
  },
  bob: {
    id: DEMO_IDS.bob,
    email: 'bob@demo.agathatrack.test',
    first_name: 'Bob',
    last_name: 'Member',
    display_name: 'Bob',
    category: 'pet_carer',
    bio: 'Demo clinic admin',
    role_description: 'Org admin at Happy Paws Clinic',
  },
  carol: {
    id: DEMO_IDS.carol,
    email: 'carol@demo.agathatrack.test',
    first_name: 'Carol',
    last_name: 'Guardian',
    display_name: 'Carol',
    category: 'pet_carer',
    bio: 'Demo guardian with shared pet access',
    role_description: 'Pet carer with shared access to Buddy',
  },
  eve: {
    id: DEMO_IDS.eve,
    email: 'eve@demo.agathatrack.test',
    first_name: 'Eve',
    last_name: 'Foster',
    display_name: 'Eve',
    category: 'pet_carer',
    bio: 'Demo foster parent at Rescue Hearts',
    role_description: 'Foster parent at Rescue Hearts',
  },
  dave: {
    id: DEMO_IDS.dave,
    email: 'dave@demo.agathatrack.test',
    first_name: 'Dave',
    last_name: 'Dual',
    display_name: 'Dave',
    category: 'pet_carer',
    bio: 'Demo dual-role user — personal pet plus org member',
    role_description: 'Dual-role user (personal pet + Rescue Hearts foster)',
  },
  grace: {
    id: DEMO_IDS.grace,
    email: 'grace@demo.agathatrack.test',
    first_name: 'Grace',
    last_name: 'Prospect',
    display_name: 'Grace',
    category: 'pet_carer',
    bio: 'Demo adopter prospect',
    role_description: 'Adoption prospect for Luna',
  },
};
