/**
 * @bdd experience_navigation.feature
 * Scenario: Guardian-only user lands on guardian home after login
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { dismissConsentBannerIfPresent, refreshFlutterAccessibility } from '../support/flutter';

test.describe('Experience navigation', () => {
  test('guardian-only user lands on guardian home after login', async ({
    page,
    testUser,
    landingPage,
  }) => {
    await landingPage.goto();
    await landingPage.login(testUser.email, testUser.password);
    await dismissConsentBannerIfPresent(page);
    await refreshFlutterAccessibility(page);
    await page.waitForURL(/\/g\/home/, { timeout: 60_000 });
    await expect(page.getByRole('button', { name: 'Home' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Events' })).toBeVisible();
  });
});
