import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  expectAppBarTitle,
  escapeRegExp,
  flutterGotoUrl,
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
/** OrgCard semantics include type + member/pet counts. */
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

  /** Navigate to the membership org list (`/o/orgs`) from org or guardian shell. */
  async openOrganizations(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const route = flutterRoutePath(this.page.url());
    if (/\/o\/orgs(?:\?|$)/.test(route) || route === '/organizations') {
      await this.expectLoaded();
      return;
    }
    await this.page.goto(flutterGotoUrl('/o/orgs'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)/, 30_000);
    await this.expectLoaded();
  }

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)|\/organizations/, 30_000);
    await refreshFlutterAccessibility(this.page);
    if (await isExperienceShellVisible(this.page)) {
      // Embedded shell has no app bar; the section header is always near the top.
      // The Create button sits at the bottom of a ListView and is often absent from
      // the Flutter web semantics tree until scrolled (UAT shard 1/11, PR #471).
      await expect(async () => {
        await refreshFlutterAccessibility(this.page);
        await expect(
          this.page.getByText(/My Organizations|Mes organisations/i).first(),
        ).toBeVisible({ timeout: 3_000 });
      }).toPass({ timeout: 30_000 });
      return;
    }
    await refreshFlutterAccessibility(this.page);
    await expectAppBarTitle(this.page, 'My Organizations');
  }

  async openCreateForm(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const createBtn = this.page
      .getByRole('button', { name: /^Create$|^Créer$/i })
      .or(this.page.getByRole('checkbox', { name: /^Create$|^Créer$/i }))
      .first();
    if (await createBtn.isVisible({ timeout: 5_000 }).catch(() => false)) {
      await createBtn.scrollIntoViewIfNeeded();
      await createBtn.click();
    } else {
      // FilledButton at list bottom — hash-route when discovery section delays scroll.
      await this.page.goto(flutterGotoUrl('/o/orgs/new'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/new/, 30_000);
    }
    await this.page
      .getByRole('button', { name: /Create Organization|Créer une organisation/i })
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
    // Accept pushes the org profile in-app, but the hash URL Playwright reads often
    // stays `/o/orgs` (same class of drift as OrganizationListPage.openOrg fallback).
    // Prefer shell back when visible; always re-enter My Orgs via goto for asserts.
    await refreshFlutterAccessibility(this.page);
    const back = this.page
      .locator('[flt-semantics-identifier="experience_back_button"]')
      .or(this.page.getByRole('button', { name: /go back|retour|^back$/i }))
      .first();
    if (await back.isVisible({ timeout: 8_000 }).catch(() => false)) {
      await back.click();
    }
    await this.page.goto(flutterGotoUrl('/o/orgs'));
    await waitForFlutterRoutePattern(this.page, /\/o\/orgs(?:\?|$)/, 30_000);
    await this.expectLoaded();
    await refreshFlutterAccessibility(this.page);
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

  discoverNavRow() {
    return this.page
      .locator('[flt-semantics-identifier="org_discover_nav_row"]')
      .or(
        this.page.getByRole('button', {
          name: /Discover Organisations|Découvrir des organisations/i,
        }),
      )
      .first();
  }

  async expectDiscoverNavRowVisible(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.discoverNavRow()).toBeVisible({ timeout: 30_000 });
  }

  async expectNoInlineDiscoverTiles(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(this.page.locator('[flt-semantics-identifier^="org_discovery_"]')).toHaveCount(0);
  }

  async openDiscoverScreen(): Promise<void> {
    await this.expectDiscoverNavRowVisible();
    const row = this.discoverNavRow();
    await row.scrollIntoViewIfNeeded();
    await row.click();
    try {
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 12_000);
    } catch {
      // Flutter web hash can lag behind the painted route; fall back to direct hash nav.
      await this.page.evaluate(() => {
        window.location.hash = '#/o/orgs/discover?from=dashboard';
      });
      await waitForFlutterRoutePattern(this.page, /\/o\/orgs\/discover/, 20_000);
    }
    await refreshFlutterAccessibility(this.page);
  }
}
