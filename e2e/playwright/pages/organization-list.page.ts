import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  escapeRegExp,
  flutterRoutePath,
  isExperienceShellVisible,
  navigateWithShellFallback,
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

function isOrgDetailRoute(page: Page): boolean {
  return /\/o\/orgs\/[^/?#]+/.test(flutterRoutePath(page.url()));
}

/** Read org id from OrgCard semantics identifier (`org_membership_<id>`). */
async function resolveMembershipOrgId(page: Page, name: string): Promise<string | undefined> {
  await refreshFlutterAccessibility(page);
  const card = membershipOrgCardLocator(page, name);
  if (!(await card.count())) {
    return undefined;
  }
  return card
    .evaluate((button) => {
      const match = (el: Element | null): string | undefined => {
        while (el) {
          const raw =
            el.getAttribute('flt-semantics-identifier') ??
            el.getAttribute('identifier') ??
            (el.id.startsWith('org_membership_') ? el.id : null);
          if (raw?.startsWith('org_membership_')) {
            return raw.slice('org_membership_'.length);
          }
          el = el.parentElement;
        }
        return undefined;
      };
      return match(button);
    })
    .catch(() => undefined);
}

/** Flutter web often misses InkWell when Playwright clicks the semantics node. */
async function activateMembershipCard(page: Page, name: string): Promise<void> {
  await refreshFlutterAccessibility(page);
  const card = membershipOrgCardLocator(page, name);
  await card.scrollIntoViewIfNeeded();
  const box = await card.boundingBox();
  if (box) {
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    return;
  }
  await card.click({ force: true });
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

  /**
   * Open an organisation detail screen from the membership list.
   * @param orgId — when set, hash-route fallback is used if the card click does not navigate
   *   (Flutter web hit-testing on org experience shell; see PR #425 remedial).
   */
  async openOrg(name: string, orgId?: string): Promise<void> {
    await this.expectOrgVisible(name);

    const resolvedOrgId = orgId ?? (await resolveMembershipOrgId(this.page, name));

    await activateMembershipCard(this.page, name);
    if (!isOrgDetailRoute(this.page)) {
      try {
        await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 8_000);
      } catch (navErr) {
        if (!isOrgDetailRoute(this.page)) {
          await refreshFlutterAccessibility(this.page);
          const card = membershipOrgCardLocator(this.page, name);
          if (await card.isVisible().catch(() => false)) {
            await card.focus();
            await this.page.keyboard.press('Enter');
            try {
              await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 8_000);
            } catch {
              if (!resolvedOrgId) {
                throw navErr;
              }
            }
          } else if (!resolvedOrgId) {
            throw navErr;
          }
        }
      }
    }

    if (!isOrgDetailRoute(this.page)) {
      if (!resolvedOrgId) {
        await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 30_000);
      } else {
        await navigateWithShellFallback(
          this.page,
          /\/o\/orgs\/[^/?#]+/,
          `/o/orgs/${resolvedOrgId}`,
          async () => {
            await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/[^/?#]+/, 30_000);
            await refreshFlutterAccessibility(this.page);
          },
          { helper: 'OrganizationListPage.openOrg', testTitle: name },
        );
      }
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
