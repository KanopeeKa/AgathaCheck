/**
 * @bdd people.feature
 * Scenario: Back from person detail returns to People hub
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { VetListPage } from '../pages/vet-list.page';
import { createPet, createVetFull, signupUser, updatePetVet } from '../support/api';
import {
  enableFlutterAccessibility,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('People detail back navigation @people', () => {
  test('@P2 back from person detail returns to People hub', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const user = await signupUser(baseURL());
    const vet = await createVetFull(baseURL(), user.accessToken, { name: 'BackNav Vet' });
    const pet = await createPet(baseURL(), user.accessToken, 'BackNavPet');
    await updatePetVet(baseURL(), user.accessToken, pet.id, {
      name: pet.name,
      species: 'Dog',
      vetId: vet.id,
    });
    await loginAs(page, {
      email: user.email,
      password: user.password,
      accessToken: user.accessToken,
    });

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.openBottomNavTab('People');
    await waitForFlutterRoutePattern(page, /\/pc\/people(?:\?|$)/, 30_000);

    const people = new VetListPage(page);
    await people.expectLoaded();
    await people.openVetDetail('BackNav Vet');
    await waitForFlutterRoutePattern(page, /\/pc\/people\/[^/?]+$/, 30_000);
    await expect(page.getByText(/BackNav Vet/i).first()).toBeVisible();

    await enableFlutterAccessibility(page);
    await page
      .locator('[flt-semantics-identifier="experience_back_button"]')
      .or(page.getByRole('button', { name: /Back|Retour/i }))
      .first()
      .click();

    await waitForFlutterRoutePattern(page, /\/pc\/people(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(page);
    await people.expectLoaded();
    await people.expectVetVisible('BackNav Vet');
  });
});
