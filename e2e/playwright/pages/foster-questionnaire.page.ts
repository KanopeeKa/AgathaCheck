import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

const AUTO_GO_SCREENING_OPTION_IDS = [
  'Q01_A',
  'Q02_A',
  'Q03_A',
  'Q04_A',
  'Q05_A',
  'Q06_A',
  'Q07_A',
  'Q08_A',
] as const;

const AUTO_GO_CONFIRMATION =
  /Thank you for completing the questionnaire\. Based on your screening answers, no immediate concern was identified\./i;

/**
 * Foster candidate questionnaire (form v1.3).
 * Route contract for flutter-candidate agent: /o/orgs/:orgId/foster-questionnaire
 */
export class FosterQuestionnairePage {
  constructor(private readonly page: Page) {}

  async goto(orgId: string): Promise<void> {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    await this.page.goto(`${baseURL.replace(/\/$/, '')}/o/orgs/${orgId}/foster-questionnaire`);
    await waitForFlutterRoutePattern(
      this.page,
      new RegExp(`/o/orgs/${orgId}/foster-questionnaire`),
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
          .locator('[flt-semantics-identifier="foster_questionnaire_screen"]')
          .or(this.page.getByRole('banner', { name: /Foster candidate questionnaire/i }))
          .first(),
      ).toBeVisible();
    }).toPass({ timeout: 30_000 });
  }

  async completeMatchingProfile(): Promise<void> {
    await enableFlutterAccessibility(this.page);

    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_PF01_CAT"]')
      .or(this.page.getByRole('button', { name: 'Cats' }))
      .first()
      .click();
    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_PF02_ADULT"]')
      .or(this.page.getByRole('button', { name: 'Adult animals' }))
      .first()
      .click();

    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_PF03_NEW"]')
      .or(this.page.getByRole('radio', { name: /New: little or no relevant experience/i }))
      .first()
      .click();
    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_PF04_ANIMAL_HEALTH_EASY"]')
      .or(this.page.getByRole('radio', { name: /Easy health needs/i }))
      .first()
      .click();

    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_pf05_CAT"]')
      .or(this.page.getByRole('textbox', { name: /Capacity for Cats/i }))
      .first()
      .fill('1');

    await this.pickAvailabilityDate('foster_questionnaire_pf06_start', 'Available from');
    await this.pickAvailabilityDate('foster_questionnaire_pf06_end', 'Available until');

    await refreshFlutterAccessibility(this.page);
    await this.clickContinue();
  }

  async answerAllScreeningWithGo(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    for (const optionId of AUTO_GO_SCREENING_OPTION_IDS) {
      const option = this.page
        .locator(`[flt-semantics-identifier="foster_questionnaire_${optionId}"]`)
        .or(this.page.getByRole('radio', { name: new RegExp(this.goOptionPattern(optionId)) }));
      await option.first().scrollIntoViewIfNeeded();
      await option.first().click();
      await refreshFlutterAccessibility(this.page);
    }
    await this.clickContinue();
  }

  async acknowledgeAndSubmit(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    const acknowledgement = this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_ack_checkbox"]')
      .or(this.page.getByRole('checkbox', { name: /I confirm the acknowledgement above/i }));
    await acknowledgement.first().scrollIntoViewIfNeeded();
    await acknowledgement.first().focus();
    await this.page.keyboard.press('Space');
    await refreshFlutterAccessibility(this.page);

    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_submit"]')
      .or(this.page.getByRole('button', { name: 'Submit questionnaire' }))
      .first()
      .click();
  }

  async expectAutoGoConfirmation(): Promise<void> {
    await expect(
      this.page
        .locator('[flt-semantics-identifier="foster_questionnaire_success_panel"]')
        .or(this.page.getByText(AUTO_GO_CONFIRMATION))
        .first(),
    ).toBeVisible({ timeout: 30_000 });
    await expect(this.page.getByText('Questionnaire submitted')).toBeVisible();
  }

  private async clickContinue(): Promise<void> {
    await this.page
      .locator('[flt-semantics-identifier="foster_questionnaire_next"]')
      .or(this.page.getByRole('button', { name: 'Continue' }))
      .first()
      .click();
    await refreshFlutterAccessibility(this.page);
  }

  private async pickAvailabilityDate(
    semanticsId: string,
    label: string,
  ): Promise<void> {
    await this.page
      .locator(`[flt-semantics-identifier="${semanticsId}"]`)
      .or(this.page.getByRole('button', { name: label }))
      .or(this.page.getByText(label))
      .first()
      .click();
    const ok = this.page.getByRole('button', { name: /^OK$/i });
    if (await ok.isVisible().catch(() => false)) {
      await ok.click();
      return;
    }
    await this.page.getByRole('button', { name: /^1$/ }).first().click();
    await this.page.getByRole('button', { name: /^OK$/i }).click();
  }

  private goOptionPattern(optionId: string): string {
    const patterns: Record<string, string> = {
      Q01_A: 'Yes, I meet the applicable minimum age',
      Q02_A: 'Yes, the relevant household members agree',
      Q03_A: 'No known circumstance would prevent a suitable placement',
      Q04_A: 'Yes, I can provide suitable daily care and supervision',
      Q05_A: 'Yes, I have suitable transport or a reliable arrangement',
      Q06_A: 'Yes, I am willing to follow guidance, learn and ask for help',
      Q07_A: "Yes, I can follow the shelter's emergency and escalation process",
      Q08_A: 'Yes, I understand and agree to follow them',
    };
    return patterns[optionId] ?? optionId;
  }
}
