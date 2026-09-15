import { seedAdoption } from './adoption.js';
import { seedConnections } from './connections.js';
import { seedFostering } from './fostering.js';
import { seedGuardian } from './guardian.js';
import { seedCareItemModelFixture } from './care-item-model-fixture.js';
import { seedCareScheduleFixture } from './care-schedule-fixture.js';
import { seedHealthCare } from './health-care.js';
import { seedOrgClinic } from './org-clinic.js';
import { seedOrgV3Demo } from './org-v3-demo.js';
import { seedRescueHearts } from './rescue-hearts.js';
import { seedSharingNotifications } from './sharing-notifications.js';

/** Ordered scenario registry — dependencies flow top to bottom. */
export const SCENARIOS = {
  guardian: seedGuardian,
  'org-clinic': seedOrgClinic,
  'org-v3-demo': seedOrgV3Demo,
  'rescue-hearts': seedRescueHearts,
  'health-care': seedHealthCare,
  'care-schedule-fixture': seedCareScheduleFixture,
  'care-item-model-fixture': seedCareItemModelFixture,
  fostering: seedFostering,
  adoption: seedAdoption,
  'sharing-notifications': seedSharingNotifications,
  connections: seedConnections,
};

/** Full rich demo dataset for UAT and demos. */
export const ALL_SCENARIOS = [
  'guardian',
  'org-clinic',
  'rescue-hearts',
  'health-care',
  'care-schedule-fixture',
  'care-item-model-fixture',
  'fostering',
  'adoption',
  'sharing-notifications',
  'connections',
];
