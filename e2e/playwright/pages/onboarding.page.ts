import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { refreshFlutterAccessibility } from '../support/flutter';

/**
 * Guardian and organisation onboarding wizards.
 * Maps to: flutter_app/test/bdd/features/guardian_onboarding.feature
 *          flutter_app/test/bdd/features/org_onboarding.feature
 */
export class OnboardingPage {
  constructor(private readonly page: Page) {}

  async expectGuardianVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByText('Welcome to Agatha Track')).toBeVisible({
      timeout: 30_000,
    });
    await expect(
      this.page.getByRole('button', { name: /skip for now/i }),
    ).toBeVisible();
  }

  async expectOrgVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByText('Welcome to your organisation workspace'),
    ).toBeVisible({
      timeout: 30_000,
    });
    await expect(
      this.page.getByRole('button', { name: /skip for now/i }),
    ).toBeVisible();
  }

  /** @deprecated Use expectGuardianVisible */
  async expectVisible(): Promise<void> {
    await this.expectGuardianVisible();
  }
}
