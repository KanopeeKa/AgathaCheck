import { rebuildAll } from './vetProjection.js';
import { setPrimaryVetFromLegacyVetId } from './relationships.js';

export const syncPetPrimaryVetFromLegacyVetId = setPrimaryVetFromLegacyVetId;

export async function reconcilePeopleVets(pool) {
  await rebuildAll(pool);
}
