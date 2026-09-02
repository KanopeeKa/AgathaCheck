/**
 * @bdd pet_profiles.feature
 * Scenario: Pet detail back navigation returns to All Pets
 * Scenario: Pet detail back navigation returns to Pet Care dashboard
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createPet } from '../support/api';
import { PetDetailPage } from '../pages/pet-detail.page';
import { PetListPage } from '../pages/pet-list.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import {
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

test.describe('Pet detail back navigation', () => {
  test('back from pet detail returns to All Pets when opened from /pc/pets', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'BackPet', 'Dog');

    await loginAs(page, testUser);
    await page.goto(flutterGotoUrl('/pc/pets'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /\/pc\/pets(?:\?|$)/, 30_000);

    const petList = new PetListPage(page);
    await petList.expectManagePetsLoaded();
    await petList.openPet('BackPet', pet.id);

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('BackPet');
    await waitForFlutterRoutePattern(page, /\/pet\/[^/?]+/, 30_000);

    await detail.goBack();
    await waitForFlutterRoutePattern(page, /\/pc\/pets(?:\?|$)/, 30_000);
    await petList.expectManagePetsLoaded();
  });

  test('back from pet detail returns to dashboard when opened from home preview', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await createPet(baseURL, testUser.accessToken, 'DashPet', 'Cat');

    await loginAs(page, testUser);
    const dashboard = new GuardianDashboardPage(page);
    await dashboard.open();

    await page.getByRole('button', { name: /DashPet/i }).first().click();
    await waitForFlutterRoutePattern(page, /\/pet\/[^/?]+/, 30_000);

    const detail = new PetDetailPage(page);
    await detail.expectLoaded('DashPet');
    await detail.goBack();

    await waitForFlutterRoutePattern(page, /\/pc\/home(?:\?|$)/, 30_000);
    await dashboard.expectTodayCareRegions();
  });
});
