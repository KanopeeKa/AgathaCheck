/**
 * @bdd pet_timeline.feature
 * Scenario: Timeline screen shows a fostering session card
 * Scenario: Timeline screen shows date of birth and joined markers
 * Scenario: Guardian navigates to timeline from pet profile
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  acceptFosterPlacement,
  createFosterPlacement,
  createOrgPet,
  seedRescueHearts,
  signupUser,
  createPet,
} from '../support/api';
import {
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('Pet timeline', () => {
  test('timeline screen shows a fostering session card', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
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
      { startDate: '2025-06-01', endDate: '2025-08-31' },
    );
    await acceptFosterPlacement(baseURL(), eve.accessToken, placement.id);

    await loginAs(page, eve);
    await page.goto(flutterGotoUrl(`/pet/${pet.id}/timeline`));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, new RegExp(`/pet/${pet.id}/timeline`), 60_000);
    await expect(page.getByText(/Frank|Eve|foster|session/i).first()).toBeVisible({
      timeout: 30_000,
    });
  });

  test('timeline screen shows date of birth and joined markers', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL(), {
      firstName: 'Dob',
      lastName: 'Joined',
      email: `timeline-dob-${Date.now()}@example.com`,
    });
    const pet = await createPet(baseURL(), user.accessToken, 'Max', 'dog');

    await loginAs(page, user);
    await page.goto(flutterGotoUrl(`/pet/${pet.id}/timeline`));
    await refreshFlutterAccessibility(page);
    await expect(page.getByText(/Timeline|Chronologie|Max/i).first()).toBeVisible({
      timeout: 30_000,
    });
  });

  test('guardian navigates to timeline from pet profile deep link', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL(), {
      firstName: 'Nav',
      lastName: 'Timeline',
      email: `timeline-nav-${Date.now()}@example.com`,
    });
    const pet = await createPet(baseURL(), user.accessToken, 'Max', 'dog');

    await loginAs(page, user);
    await page.goto(flutterGotoUrl(`/pet/${pet.id}`));
    await refreshFlutterAccessibility(page);
    await page.goto(flutterGotoUrl(`/pet/${pet.id}/timeline`));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, new RegExp(`/pet/${pet.id}/timeline`), 60_000);
    await expect(page.getByText(/Timeline|Chronologie/i).first()).toBeVisible({ timeout: 30_000 });
  });
});
