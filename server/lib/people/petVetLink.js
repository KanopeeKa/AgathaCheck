import { rebuildAll } from './vetProjection.js';

export async function reconcilePeopleVets(pool) {
  await rebuildAll(pool);
}
