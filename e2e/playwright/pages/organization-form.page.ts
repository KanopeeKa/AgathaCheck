import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  enableFlutterAccessibility,
  fillSemanticsField,
  fillTextbox,
  selectDropdownOption,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { OrganizationListPage } from './organization-list.page';

/**
 * Create / edit organization form (`/organizations/new`, `/organizations/:id/edit`).
 */
export class OrganizationFormPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await enableFlutterAccessibility(this.page);
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('heading', { name: /Create Organisation|Edit Organisation|Créer une organisation|Modifier l'organisation/i })
      .or(this.page.getByRole('button', { name: /^(Create|Save)$/ }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async fillName(name: string): Promise<void> {
    // Phase A hero field has no labelText; Key('org_name_field') → semantics identifier.
    await fillSemanticsField(this.page, 'org_name_field', name);
  }

  async selectType(type: 'Professional' | 'Charity'): Promise<void> {
    await selectDropdownOption(this.page, 'Type', type);
  }

  async fillBio(bio: string): Promise<void> {
    await fillTextbox(this.page, 'Bio', bio);
  }

  async save(): Promise<void> {
    await this.page
      .getByRole('button', { name: /^(Create|Save)$/ })
      .click();
  }

  async createOrganization(
    name: string,
    type: 'Professional' | 'Charity' = 'Professional',
  ): Promise<void> {
    await this.expectLoaded();
    await this.selectType(type);
    await this.fillName(name);
    await this.save();
    await this.page
      .getByText('Organisation created')
      .first()
      .or(this.page.getByRole('button', { name: 'Save' }))
      .first()
      .waitFor({ timeout: 30_000 });
    try {
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 8_000);
    } catch {
      // Flutter web sometimes stays on /o/orgs after create; list card + hash fallback.
      const list = new OrganizationListPage(this.page);
      await list.openOrg(name);
    }
  }

  async attemptSaveWithoutName(): Promise<void> {
    await this.expectLoaded();
    const field = this.page.locator('[flt-semantics-identifier="org_name_field"]');
    await field.waitFor({ state: 'visible' });
    await field.click();
    await this.page.keyboard.press('Control+a');
    await this.page.keyboard.press('Backspace');
    await this.save();
  }

  async expectNameRequiredError(): Promise<void> {
    await expect(this.page.getByText('Organisation name is required').first()).toBeVisible();
  }

  async updateBio(bio: string): Promise<void> {
    await this.expectLoaded();
    await this.fillBio(bio);
    await this.save();
    await this.page.getByText('Organisation updated').first().waitFor({ timeout: 30_000 });
  }
}
