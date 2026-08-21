import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillTextbox,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const VALIDATED_PANEL =
  /Home visit validated|Visit outcome recorded|Home visit approved/i;

/**
 * Admin foster home visit schedule and validate flow.
 * Route contract for flutter-home-visit agent: /o/orgs/:orgId/foster-home-visits/:fosterParentId
 */
export class FosterHomeVisitAdminPage {
  constructor(private readonly page: Page) {}

  async goto(orgId: string, fosterParentId: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await this.page.goto(
      `${baseURL.replace(/\/$/, '')}/o/orgs/${orgId}/foster-home-visits/${fosterParentId}`,
    );
    await waitForFlutterRoutePattern(
      this.page,
      new RegExp(`/o/orgs/${orgId}/foster-home-visits/${fosterParentId}`),
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
          .locator('[flt-semantics-identifier="foster_home_visit_admin_screen"]')
          .or(this.page.getByRole('banner', { name: /Foster home visit/i }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async scheduleVisit(options: {
    address?: string;
    notes?: string;
  } = {}): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .locator('[flt-semantics-identifier="foster_home_visit_open_schedule"]')
      .or(this.page.getByRole('button', { name: /Schedule home visit/i }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);

    await this.pickVisitDate();
    await fillTextbox(
      this.page,
      /Visit address/i,
      options.address ?? '42 Foster Lane, Test Town',
    );
    if (options.notes) {
      await fillTextbox(this.page, /Visit notes/i, options.notes);
    }

    const scheduleResponse = this.page.waitForResponse(
      (response) =>
        response.request().method() === 'POST'
        && response.url().includes('/foster-home-visits/')
        && response.url().includes('/schedule')
        && response.status() === 201,
    );

    await this.page
      .locator('[flt-semantics-identifier="foster_home_visit_schedule_submit"]')
      .or(this.page.getByRole('button', { name: /Save schedule|Schedule visit/i }))
      .first()
      .click();

    const response = await scheduleResponse;
    const body = await response.json();
    expect(body.visit?.status).toBe('scheduled');
    await refreshFlutterAccessibility(this.page);
  }

  async validateYes(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await this.page
      .locator('[flt-semantics-identifier="foster_home_visit_outcome_yes"]')
      .or(this.page.getByRole('radio', { name: /Yes.*home suitable|Outcome yes/i }))
      .first()
      .scrollIntoViewIfNeeded();
    await this.page
      .locator('[flt-semantics-identifier="foster_home_visit_outcome_yes"]')
      .or(this.page.getByRole('radio', { name: /Yes.*home suitable|Outcome yes/i }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);

    const validateResponse = this.page.waitForResponse(
      (response) =>
        response.request().method() === 'POST'
        && response.url().includes('/foster-home-visits/')
        && response.url().includes('/validate')
        && response.status() === 200,
    );

    await this.page
      .locator('[flt-semantics-identifier="foster_home_visit_validate_submit"]')
      .or(this.page.getByRole('button', { name: /Record visit outcome|Validate visit/i }))
      .first()
      .click();

    const response = await validateResponse;
    const body = await response.json();
    expect(body.visit?.outcome).toBe('yes');
    expect(body.visit?.status).toBe('validated');
    await this.expectValidated();
  }

  async expectValidated(): Promise<void> {
    await expect(
      this.page
        .locator('[flt-semantics-identifier="foster_home_visit_validated_panel"]')
        .or(this.page.getByText(VALIDATED_PANEL))
        .first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  private async pickVisitDate(): Promise<void> {
    await this.page
      .locator('[flt-semantics-identifier="foster_home_visit_schedule_date"]')
      .or(this.page.getByRole('button', { name: /Visit date/i }))
      .or(this.page.getByText(/Visit date/i))
      .first()
      .click();
    const ok = this.page.getByRole('button', { name: /^OK$/i });
    if (await ok.isVisible().catch(() => false)) {
      await ok.click();
      return;
    }
    await this.page.getByRole('button', { name: /^15$/ }).first().click();
    await this.page.getByRole('button', { name: /^OK$/i }).click();
  }
}
