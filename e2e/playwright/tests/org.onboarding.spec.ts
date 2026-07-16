/**
 * @bdd org_onboarding.feature
 * Scenario: New org super-admin sees onboarding wizard after first login
 * Scenario: Org super-admin completes onboarding with inventory pet and reminder
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { OnboardingPage } from '../pages/onboarding.page';
import { seedRescueHearts } from '../support/api';
import {
  completeOrgOnboarding,
  dismissConsentBannerIfPresent,
  refreshFlutterAccessibility,
  waitForPostLoginRoute,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('Organisation onboarding', () => {
  test('new org super-admin sees onboarding wizard after first login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { alice } = await seedRescueHearts(baseURL());

    const landing = new LandingPage(page);
    await landing.goto();
    await landing.login(alice.email, alice.password);
    await dismissConsentBannerIfPresent(page);
    await waitForPostLoginRoute(page);

    await page.waitForURL(/\/o\/onboarding/, { timeout: 60_000 });
    const onboarding = new OnboardingPage(page);
    await onboarding.expectOrgVisible();
  });

  test('org super-admin completes onboarding with inventory pet and reminder', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { alice } = await seedRescueHearts(baseURL());

    const landing = new LandingPage(page);
    await landing.goto();
    await landing.login(alice.email, alice.password);
    await dismissConsentBannerIfPresent(page);
    await waitForPostLoginRoute(page);

    await completeOrgOnboarding(page, 'Max', 'Vaccine booster');

    const experience = new ExperiencePage(page);
    await experience.expectOrgShell();
    await expect(page.getByText('Max')).toBeVisible();
    await refreshFlutterAccessibility(page);
  });
});
