/**
 * Foster portal route guards — blocked org routes redirect to home.
 */
import { test, expect } from '../fixtures/auth.fixture';
import { ExperiencePage } from '../pages/experience.page';
import { LandingPage } from '../pages/landing.page';
import { seedRescueHearts } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function loginFosterOnly(
  page: import('@playwright/test').Page,
  email: string,
  password: string,
): Promise<void> {
  const landing = new LandingPage(page);
  await landing.goto();
  await landing.login(email, password);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);
  await waitForFlutterRoutePattern(page, /\/o\/home/, 60_000);
}

test.describe('Foster portal route guards', () => {
  test('direct navigation to org invite redirects foster portal user home', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { eve } = await seedRescueHearts(baseURL());
    await loginFosterOnly(page, eve.email, eve.password);

    await page.goto(flutterGotoUrl('/o/invite'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /\/o\/home/, 15_000);
    const experience = new ExperiencePage(page);
    await experience.expectOrgShell();
    await expect(page.getByText('Invite', { exact: true })).not.toBeVisible();
  });

  test('direct navigation to org events redirects foster portal user home', async ({
    page,
  }) => {
    await prepareLiveApiAccess(page, baseURL());
    const { eve } = await seedRescueHearts(baseURL());
    await loginFosterOnly(page, eve.email, eve.password);

    await page.goto(flutterGotoUrl('/o/events'));
    await refreshFlutterAccessibility(page);
    await waitForFlutterRoutePattern(page, /\/o\/home/, 15_000);
    const experience = new ExperiencePage(page);
    await experience.expectOrgShell();
    await expect(page.getByRole('button', { name: 'Add Health Event' })).not.toBeVisible();
  });
});
