/**
 * @bdd org_onboarding.feature
 * Scenario: New org super-admin sees onboarding wizard after first login
 * Scenario: Org super-admin completes onboarding with inventory pet and reminder
 */
import { test } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { ExperiencePage } from '../pages/experience.page';
import { OnboardingPage } from '../pages/onboarding.page';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { seedRescueHearts } from '../support/api';
import {
  completeOrgOnboarding,
  dismissConsentBannerIfPresent,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  skipGuardianOnboardingIfPresent,
  waitForPostLoginRoute,
  waitForFlutterRoutePattern,
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
    await skipGuardianOnboardingIfPresent(page);

    const experience = new ExperiencePage(page);
    await experience.switchToShelterWorkspace();

    // D-v5-WORKSPACE-2: login lands on guardian onboarding when the account has no owned pets.
    await waitForFlutterRoutePattern(page, /\/pc\/onboarding/, 60_000);
    const onboarding = new OnboardingPage(page);
    await onboarding.expectGuardianVisible();
  });

  test('org super-admin completes onboarding with inventory pet and reminder', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { alice, org } = await seedRescueHearts(baseURL());

    const landing = new LandingPage(page);
    await landing.goto();
    await landing.login(alice.email, alice.password);
    await dismissConsentBannerIfPresent(page);
    await waitForPostLoginRoute(page);
    await skipGuardianOnboardingIfPresent(page);

    const experience = new ExperiencePage(page);
    await experience.switchToShelterWorkspace();

    await completeOrgOnboarding(page, 'Max', 'Vaccine booster');

    await experience.expectOrgShell();

    // Organization home is intentionally a shelter switcher. The inventory
    // created during onboarding belongs in the selected shelter's Pets view.
    await page.goto(flutterGotoUrl(`/o/orgs/${org.id}`));
    const organization = new OrganizationDetailPage(page);
    await organization.expectLoaded(org.name);
    await organization.expectPetVisible('Max');
    await refreshFlutterAccessibility(page);
  });
});
