/**
 * @bdd guardian_onboarding.feature
 * Scenario: New guardian user sees onboarding wizard after first login
 * Scenario: Guardian completes onboarding with pet
 */
import { test, expect } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { ExperiencePage } from '../pages/experience.page';
import { OnboardingPage } from '../pages/onboarding.page';
import { signupUser } from '../support/api';
import {
  completeExperienceChooserIfPresent,
  completeGuardianOnboarding,
  dismissConsentBannerIfPresent,
  petCardByName,
  refreshFlutterAccessibility,
  waitForPostLoginRoute,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

test.describe('Guardian onboarding', () => {
  test('new guardian user sees onboarding wizard after first login', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL(), {
      email: `onboard-${Date.now()}@example.com`,
      password: 'secret123',
    });

    const landing = new LandingPage(page);
    await landing.goto();
    await landing.login(user.email, user.password);
    await dismissConsentBannerIfPresent(page);
    await waitForPostLoginRoute(page);
    await completeExperienceChooserIfPresent(page, 'guardian', undefined, {
      skipGuardianOnboarding: false,
    });

    await waitForFlutterRoutePattern(page, /\/g\/onboarding/, 60_000);
    const onboarding = new OnboardingPage(page);
    await onboarding.expectGuardianVisible();
  });

  test('guardian completes onboarding with pet', async ({ page }) => {
    await prepareLiveApiAccess(page, baseURL());
    const user = await signupUser(baseURL(), {
      email: `setup-${Date.now()}@example.com`,
      password: 'secret123',
    });

    const landing = new LandingPage(page);
    await landing.goto();
    await landing.login(user.email, user.password);
    await dismissConsentBannerIfPresent(page);
    await waitForPostLoginRoute(page);
    await completeExperienceChooserIfPresent(page, 'guardian', undefined, {
      skipGuardianOnboarding: false,
    });

    await completeGuardianOnboarding(page, 'Bella');

    const experience = new ExperiencePage(page);
    await experience.expectGuardianShell();
    await expect(petCardByName(page, 'Bella')).toBeVisible();
    await refreshFlutterAccessibility(page);
  });
});
