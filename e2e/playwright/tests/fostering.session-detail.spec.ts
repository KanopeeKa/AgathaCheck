/**
 * @bdd fostering_session_detail.feature
 * Scenario: Foster carer opens session detail from pending invite
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  createFosterPlacement,
  createOrgPet,
  getFosterPlacementDetail,
  getPendingFosterPlacements,
  seedRescueHearts,
} from '../support/api';

test.describe('Fostering session detail (foster lens)', () => {
  test('@P1 foster participant can load session aggregate with invite actions', async () => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Buddy',
      species: 'dog',
    });
    const placement = await createFosterPlacement(
      baseURL,
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );

    const pending = await getPendingFosterPlacements(baseURL, eve.accessToken);
    expect(pending.some((row) => row.id === placement.id)).toBe(true);

    const detail = await getFosterPlacementDetail(
      baseURL,
      eve.accessToken,
      placement.id,
    );
    expect(detail.pet?.name).toBe('Buddy');
    expect(detail.viewer?.role).toBe('foster_participant');
    expect(detail.viewer?.allowed_actions).toEqual(
      expect.arrayContaining(['accept_invite', 'decline_invite']),
    );
  });
});
