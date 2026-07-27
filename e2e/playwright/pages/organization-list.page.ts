import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  escapeRegExp,
  isExperienceShellVisible,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';

/**
 * Organization list screen (`/o/orgs`, legacy `/organizations`).
 * Maps to: flutter_app/test/bdd/features/organisation_management.feature
 */
/** OrgCard semantics include type + member/pet counts; discovery tiles are name-only and not tappable. */
function membershipOrgCardPattern(name: string): RegExp {
  const escaped = escapeRegExp(name);
  return new RegExp(
    `${escaped},\\s*(?:Professional|Charity|Professionnel|Association).*(?:members?|pets?|membres?)`,
    'i',
  );
}

function membershipOrgCardLocator(page: Page, name: string) {
  // OrgCard exposes role=button (Semantics.onTap). Avoid group fallback — a
  // parent group with the same label is not activated by Playwright click.
  return page
    .getByRole('button', { name: membershipOrgCardPattern(name) })
    .filter({ visible: true })
    .first();
}

export class OrganizationListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)|\/organizations/, 30_000);
    await refreshFlutterAccessibility(this.page);
    if (await isExperienceShellVisible(this.page)) {
      await expect(this.page.getByRole('button', { name: 'Create' })).toBeVisible({
        timeout: 30_000,
      });
      return;
    }
    await expectAppBarTitle(this.page, 'My Organizations');
  }

  async openCreateForm(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Create' }).click();
    await this.page
      .getByRole('button', { name: 'Create Organization' })
      .waitFor({ timeout: 30_000 });
  }

  async expectOrgVisible(name: string): Promise<void> {
    await membershipOrgCardLocator(this.page, name).waitFor({
      state: 'visible',
      timeout: 30_000,
    });
  }

  async openOrg(name: string): Promise<void> {
    await this.expectOrgVisible(name);
    await refreshFlutterAccessibility(this.page);
    const card = membershipOrgCardLocator(this.page, name);
    await card.scrollIntoViewIfNeeded();
    await card.click();
    try {
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 5_000);
    } catch {
      // Semantics activation (Enter) when pointer hit-testing misses InkWell on web.
      await refreshFlutterAccessibility(this.page);
      await card.focus();
      await this.page.keyboard.press('Enter');
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 30_000);
    }
    await refreshFlutterAccessibility(this.page);
  }

  async acceptInviteForOrg(orgName: string): Promise<void> {
    await this.page
      .getByText(new RegExp(escapeRegExp(orgName), 'i'))
      .or(this.page.getByRole('group', { name: new RegExp(escapeRegExp(orgName), 'i') }))
      .first()
      .waitFor({ timeout: 30_000 })
      .catch(() => undefined);
    await this.page.getByRole('button', { name: /^Accept$/i }).first().click();
    await this.page.getByText(/Invitation accepted/i).first().waitFor({ timeout: 30_000 });
    await refreshFlutterAccessibility(this.page);
    // Accept navigates to org detail; return to the list for card assertions.
    const back = this.page.getByRole('button', { name: /^Back$/i });
    if (await back.count()) {
      await back.first().click();
      await this.expectLoaded();
      await refreshFlutterAccessibility(this.page);
    }
  }

  async declineInviteForOrg(orgName: string): Promise<void> {
    await this.page
      .getByText(new RegExp(escapeRegExp(orgName), 'i'))
      .or(this.page.getByRole('group', { name: new RegExp(escapeRegExp(orgName), 'i') }))
      .first()
      .waitFor({ timeout: 30_000 })
      .catch(() => undefined);
    await this.page.getByRole('button', { name: /^Decline$/i }).first().click();
    await this.page.getByText(/Invitation declined/i).first().waitFor({ timeout: 30_000 });
    await refreshFlutterAccessibility(this.page);
  }

  async expectNoPendingInvite(orgName: string): Promise<void> {
    await expect(this.page.getByRole('button', { name: /^Accept$/i })).toHaveCount(0);
    await expect(
      this.page.getByText(new RegExp(`invited to join.*${escapeRegExp(orgName)}`, 'i')),
    ).toHaveCount(0);
  }
}
