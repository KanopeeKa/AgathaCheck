/**
 * Stable demo identities for UAT and demos.
 * Documented in docs/e2e/uat-demo-personas.md
 */

/** Documented demo password — acceptable only on isolated non-prod databases. */
export const DEMO_PASSWORD = 'UatDemoPass1!';
export const DEMO_PASSWORD_HASH =
  '$2b$10$BgtLHM4jS8/oSsNAjYDzfueZv0kk.qRH1fqS.AUvqqfKiKO6M6Atm';

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
    email: 'alice@demo.agathatrack.test',
    first_name: 'Alice',
    last_name: 'Super',
    category: 'pet_carer',
    bio: 'Demo guardian and clinic super admin',
  },
  bob: {
    id: DEMO_IDS.bob,
    email: 'bob@demo.agathatrack.test',
    first_name: 'Bob',
    last_name: 'Member',
    category: 'pet_carer',
    bio: 'Demo clinic admin',
  },
  carol: {
    id: DEMO_IDS.carol,
    email: 'carol@demo.agathatrack.test',
    first_name: 'Carol',
    last_name: 'Guardian',
    category: 'pet_carer',
    bio: 'Demo guardian with shared pet access',
  },
  eve: {
    id: DEMO_IDS.eve,
    email: 'eve@demo.agathatrack.test',
    first_name: 'Eve',
    last_name: 'Foster',
    category: 'pet_carer',
    bio: 'Demo foster parent at Rescue Hearts',
  },
  dave: {
    id: DEMO_IDS.dave,
    email: 'dave@demo.agathatrack.test',
    first_name: 'Dave',
    last_name: 'Dual',
    category: 'pet_carer',
    bio: 'Demo dual-role user — personal pet plus org member',
  },
  grace: {
    id: DEMO_IDS.grace,
    email: 'grace@demo.agathatrack.test',
    first_name: 'Grace',
    last_name: 'Prospect',
    category: 'pet_carer',
    bio: 'Demo adopter prospect',
  },
};
