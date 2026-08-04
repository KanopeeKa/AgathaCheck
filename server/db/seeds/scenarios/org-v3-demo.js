import { seedConnections } from './connections.js';
import { seedOrgClinic } from './org-clinic.js';
import { seedRescueHeartsOrgShell } from './rescue-hearts.js';

/** Org UX v3 subset: discoverable clinic + connected charity (no hero photos). */
export async function seedOrgV3Demo(client) {
  await seedOrgClinic(client);
  await seedRescueHeartsOrgShell(client);
  await seedConnections(client);
  console.log('seed: org-v3-demo scenario ready (discoverable Happy Paws + Rescue Hearts)');
}
