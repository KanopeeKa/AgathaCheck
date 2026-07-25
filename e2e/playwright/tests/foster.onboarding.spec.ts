/**
 * @bdd foster_onboarding.feature
 * Scenario: Opening Manage Fosters from organisation menu
 * Scenario: Viewing fosters currently fostering
 * Scenario: Adding a foster manually
 */
import { test, expect } from '../fixtures/auth.fixture';
import {
  acceptFosterPlacement,
  addManualFoster,
  createFosterPlacement,
  createOrgPet,
  getFosterParents,
  seedRescueHearts,
} from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('Foster onboarding and approval', () => {
  test('opening manage fosters from organisation menu', async () => {
    const { alice, org } = await seedRescueHearts(baseURL());
    const parents = await getFosterParents(baseURL(), alice.accessToken, org.id);
    expect(parents.length).toBeGreaterThan(0);
    const summaries = parents
      .map((row) => row.fostering_activity_summary)
      .filter(Boolean);
    expect(summaries.length).toBeGreaterThan(0);
  });

  test('viewing fosters currently fostering', async () => {
    const { alice, eve, org } = await seedRescueHearts(baseURL());
    const pet = await createOrgPet(baseURL(), alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });
    const placement = await createFosterPlacement(
      baseURL(),
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );
    await acceptFosterPlacement(baseURL(), eve.accessToken, placement.id);

    const parents = await getFosterParents(baseURL(), alice.accessToken, org.id);
    const fostering = parents.filter(
      (row) => row.fostering_activity_summary === 'actively_fostering',
    );
    expect(fostering.some((row) => row.display_name.includes('Eve'))).toBe(true);
  });

  test('adding a foster manually', async () => {
    const { alice, org } = await seedRescueHearts(baseURL());
    await addManualFoster(baseURL(), alice.accessToken, org.id, {
      displayName: 'Bob',
      email: 'bob@example.com',
    });

    const parents = await getFosterParents(baseURL(), alice.accessToken, org.id);
    expect(parents.some((row) => row.display_name === 'Bob')).toBe(true);
  });
});
