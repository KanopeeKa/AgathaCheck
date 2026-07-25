/**
 * @bdd fostering_platform.feature
 * Scenario: Foster request targets respect approved capacity filters
 * Scenario: Manage Fosters tabs use fostering activity summary
 * Scenario: Positive adoption visit outcome gates journey start on visit path
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  acceptFosterPlacement,
  addManualFoster,
  approveFosterParent,
  createAdoptionVisit,
  createOrgPet,
  createViewToAdoptSession,
  getAdoptionJourney,
  getEligibleFosterTargets,
  getFosterParents,
  recordAdoptionVisitOutcome,
  seedRescueHearts,
  setFosterCapacity,
  startAdoptionJourney,
} from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('Fostering platform journeys', () => {
  test('foster request targets respect approved capacity filters', async () => {
    const { alice, org } = await seedRescueHearts(baseURL());
    const pet = await createOrgPet(baseURL(), alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });

    const eligibleBob = await addManualFoster(baseURL(), alice.accessToken, org.id, {
      displayName: 'Bob Capacity',
      email: `bob-cap-${Date.now()}@example.com`,
    });
    await approveFosterParent(baseURL(), alice.accessToken, org.id, eligibleBob.id);
    if (eligibleBob.foster_profile_id) {
      await setFosterCapacity(eligibleBob.foster_profile_id, [
        { species: 'dog', declared: 2 },
      ]);
    }

    const blockedCarol = await addManualFoster(baseURL(), alice.accessToken, org.id, {
      displayName: 'Carol Zero',
      email: `carol-zero-${Date.now()}@example.com`,
    });
    await approveFosterParent(baseURL(), alice.accessToken, org.id, blockedCarol.id);
    if (blockedCarol.foster_profile_id) {
      await setFosterCapacity(blockedCarol.foster_profile_id, [
        { species: 'dog', declared: 0 },
      ]);
    }

    const targets = await getEligibleFosterTargets(
      baseURL(),
      alice.accessToken,
      org.id,
      [pet.id],
    );
    const names = targets.map((row) => row.display_name);
    expect(names).toContain('Bob Capacity');
    expect(names).not.toContain('Carol Zero');
  });

  test('manage fosters tabs use fostering activity summary', async () => {
    const { alice, eve, org } = await seedRescueHearts(baseURL());
    const pet = await createOrgPet(baseURL(), alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const placement = await createViewToAdoptSession(
      baseURL(),
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );
    await acceptFosterPlacement(baseURL(), eve.accessToken, placement.id);

    const parents = await getFosterParents(baseURL(), alice.accessToken, org.id);
    const eveParent = parents.find((row) => row.display_name.includes('Eve'));
    expect(eveParent?.fostering_activity_summary).toBe('actively_fostering');
  });

  test('positive adoption visit outcome gates journey start on visit path', async () => {
    const { alice, eve, org } = await seedRescueHearts(baseURL());
    const pet = await createOrgPet(baseURL(), alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const placement = await createViewToAdoptSession(
      baseURL(),
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );
    const accepted = await acceptFosterPlacement(
      baseURL(),
      eve.accessToken,
      placement.id,
    );

    await expect(
      startAdoptionJourney(baseURL(), alice.accessToken, org.id, accepted.id),
    ).rejects.toThrow(/visit/i);

    const visit = await createAdoptionVisit(baseURL(), alice.accessToken, org.id, {
      petId: pet.id,
      fosteringSessionId: accepted.id,
    });
    await recordAdoptionVisitOutcome(
      baseURL(),
      alice.accessToken,
      org.id,
      visit.id,
      'positive',
    );

    const started = await startAdoptionJourney(
      baseURL(),
      alice.accessToken,
      org.id,
      accepted.id,
    );
    expect(started.adoption_journey?.status).toBe('awaiting_foster_confirmation');

    const journey = await getAdoptionJourney(
      baseURL(),
      alice.accessToken,
      org.id,
      accepted.id,
    );
    expect(journey.adoption_journey.status).toBe('awaiting_foster_confirmation');
  });
});
