import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const VALIDATED_STATUS =
  /Home visit approved|Visit validated|Outcome:\s*Yes|Home visit recorded/i;

/**
 * Candidate foster home visit status (address excluded from exports).
 * Route contract for flutter-home-visit agent:
 * /o/orgs/:orgId/foster-home-visits/:fosterParentId/status
 */
export class FosterHomeVisitStatusPage {
  constructor(private readonly page: Page) {}

  async goto(orgId: string, fosterParentId: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await this.page.goto(
      `${baseURL.replace(/\/$/, '')}/o/orgs/${orgId}/foster-home-visits/${fosterParentId}/status`,
    );
    await waitForFlutterRoutePattern(
      this.page,
      new RegExp(`/o/orgs/${orgId}/foster-home-visits/${fosterParentId}/status`),
      60_000,
    );
    await enableFlutterAccessibility(this.page);
    await this.expectLoaded();
  }

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .locator('[flt-semantics-identifier="foster_home_visit_status_screen"]')
          .or(this.page.getByRole('banner', { name: /Your home visit|Home visit status/i }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async expectValidatedYes(): Promise<void> {
    await expect(
      this.page
        .locator('[flt-semantics-identifier="foster_home_visit_status_validated"]')
        .or(this.page.getByText(VALIDATED_STATUS))
        .first(),
    ).toBeVisible({ timeout: 30_000 });
    await expect(this.page.getByText(/Visit address|42 Foster Lane/i)).toHaveCount(0);
  }
}
