/**
 * @bdd guardian_dashboard.feature
 * Scenario: Dashboard shows exactly three sections
 * Scenario: My Pets preview is capped at four
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { createPet, signupUser } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  refreshFlutterAccessibility,
  skipGuardianOnboardingIfPresent,
  waitForPostLoginRoute,
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
  await dismissConsentBannerIfPresent(page);
  await waitForPostLoginRoute(page);
  await skipGuardianOnboardingIfPresent(page);
  await refreshFlutterAccessibility(page);
}

test.describe('Guardian dashboard', () => {
  test('dashboard shows exactly three sections', async ({ page, testUser }) => {
    await loginGuardian(page, testUser.email, testUser.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);

    await expect(page.getByText('My Pets', { exact: true })).toBeVisible();
    await expect(page.getByText('Upcoming Pet Events', { exact: true })).toBeVisible();
    await expect(page.getByText('My Vets', { exact: true })).toBeVisible();

    await expect(page.getByText('Pending foster placements')).not.toBeVisible();
    await expect(page.getByText('Pending Shares')).not.toBeVisible();
  });

  test('My Pets preview is capped at four with All Pets link', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL());
    for (let i = 0; i < 6; i += 1) {
      await createPet(baseURL(), user.token, { name: `DashPet${i}` });
    }

    await loginGuardian(page, user.email, user.password);
    await waitForFlutterRoutePattern(page, /\/g\/home/, 60_000);
    await refreshFlutterAccessibility(page);

    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();

    const petCards = page.locator('[flt-semantics-identifier="pet_card"]');
    const cardCount = await petCards.count();
    expect(cardCount).toBeLessThanOrEqual(4);
    await expect(page.getByText('All Pets', { exact: true })).toBeVisible();
  });
});
