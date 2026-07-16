import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { refreshFlutterAccessibility } from '../support/flutter';

/**
 * Guardian onboarding wizard (`/g/onboarding`).
 * Maps to: flutter_app/test/bdd/features/guardian_onboarding.feature
 */
export class OnboardingPage {
  constructor(private readonly page: Page) {}

  async expectVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.getByText('Welcome to Agatha Track')).toBeVisible({
      timeout: 30_000,
    });
    await expect(
      this.page.getByRole('button', { name: /skip for now/i }),
    ).toBeVisible();
  }
}
