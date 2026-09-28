/**
 * @bdd people.feature
 * Scenario: Today desk shows Vet team sub-block
 * Scenario: Pet parent opens People from Account
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { createPet, createVetFull, signupUser, updatePetVet } from '../support/api';
import {
  reachAuthenticatedHome,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function loginGuardian(
  page: import('@playwright/test').Page,
  email: string,
  password: string,
): Promise<void> {
  const landing = new LandingPage(page);
  await landing.goto();
  await landing.login(email, password);
  await reachAuthenticatedHome(page);
}

test.describe('People hub remodel @people', () => {
  test('@P2 desk module labels Vet team sub-block', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    const vet = await createVetFull(baseURL(), user.accessToken, { name: 'Desk Vet' });
    const pet = await createPet(baseURL(), user.accessToken, 'DeskPet');
    await updatePetVet(baseURL(), user.accessToken, pet.id, {
      name: pet.name,
      species: 'Dog',
      vetId: vet.id,
    });
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.expectLoaded();
    // Vet team sub-block: professional row on desk (subheading Text is not always a separate a11y node on web).
    await dashboard.expectVetVisible('Desk Vet');
  });

  test('@P2 bottom nav opens People hub', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    await createPet(baseURL(), user.accessToken, 'PeoplePet');
    await loginGuardian(page, user.email, user.password);

    const dashboard = new GuardianDashboardPage(page);
    await dashboard.openBottomNavTab('People');
    await waitForFlutterRoutePattern(page, /\/pc\/people(?:\?|$)/, 30_000);
    await expect(page.getByText(/^People$|^Autour de vos animaux$/i).first()).toBeVisible();
  });
});
