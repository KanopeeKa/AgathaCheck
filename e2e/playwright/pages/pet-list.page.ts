import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectAppBarTitle,
  expectHomeShellVisible,
  homeShellLocator,
  isExperienceShellVisible,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoute,
} from '../support/flutter';
import { isLiveHostingTarget } from '../support/hosting';

/**
 * Home / pet list screen (`/`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await expectHomeShellVisible(
      this.page,
      isLiveHostingTarget() ? 60_000 : 30_000,
    );
  }

  async openHealthDashboard(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const addEvent = this.page.getByRole('button', { name: 'Add Health Event' });
    const eventsNav = this.page.getByRole('button', { name: 'Events' });
    if (await eventsNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await eventsNav.click();
    } else if (await isExperienceShellVisible(this.page)) {
      const path = this.page.url().includes('/o/') ? '/o/events' : '/g/events';
      await this.page.goto(path);
      await refreshFlutterAccessibility(this.page);
    } else {
      await this.page.getByRole('button', { name: 'To Do' }).click();
    }
    if (await addEvent.isVisible({ timeout: 3_000 }).catch(() => false)) {
      return;
    }
    if (await isExperienceShellVisible(this.page)) {
      const path = this.page.url().includes('/o/') ? '/o/events' : '/g/events';
      await this.page.goto(path);
      await refreshFlutterAccessibility(this.page);
    }
    await addEvent.waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText('No pets yet').waitFor();
    await homeShellLocator(this.page).first().waitFor();
  }

  async openAddPet(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Add Pet' }).click();
    await this.page.getByRole('button', { name: 'Save Pet' }).waitFor({ timeout: 30_000 });
  }

  async expectPetVisible(name: string): Promise<void> {
    await semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i'),
    ).waitFor({ timeout: 30_000 });
  }

  async expectPetCount(n: number): Promise<void> {
    await expect(
      this.page
        .getByRole('button', { name: /Pet:/i })
        .or(this.page.getByRole('group', { name: /Pet:/i })),
    ).toHaveCount(n, { timeout: 30_000 });
  }

  async openPet(name: string): Promise<void> {
    await this.expectPetVisible(name);
    await semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i'),
    ).click();
    await this.page.waitForTimeout(1000);
  }

  async openOrganizations(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const orgNav = this.page.getByRole('button', { name: 'Organizations' });
    if (await orgNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await orgNav.click();
    } else {
      await this.page.goto('/organizations');
      await refreshFlutterAccessibility(this.page);
    }
    await this.page
      .getByRole('button', { name: 'Create' })
      .or(this.page.getByRole('button', { name: /Rescue Hearts|Partner Shelter/i }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openVets(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    const vetsNav = this.page.getByRole('button', { name: 'Veterinarians' });
    if (await vetsNav.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await vetsNav.click();
    } else {
      await this.page.goto('/vets');
      await refreshFlutterAccessibility(this.page);
    }
    await expectAppBarTitle(this.page, 'Veterinarians');
  }

  /**
   * Simulate a left swipe on a shared-pet card to trigger the hide-pet
   * Dismissible action (DismissDirection.endToStart).
   */
  async swipeLeftPetCard(name: string): Promise<void> {
    const card = semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i'),
    );
    const box = await card.boundingBox();
    if (!box) throw new Error(`Pet card "${name}" not found`);
    const startX = box.x + box.width * 0.92;
    const endX = box.x + box.width * 0.02;
    const midY = box.y + box.height / 2;
    await this.page.mouse.move(startX, midY);
    await this.page.mouse.down();
    for (let i = 1; i <= 24; i++) {
      await this.page.mouse.move(startX + (endX - startX) * (i / 24), midY);
      await this.page.waitForTimeout(15);
    }
    await this.page.waitForTimeout(300);
    await this.page.mouse.up();
    await this.page.waitForTimeout(500);
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByText(new RegExp(`Hide\\s+${escapeRegExp(name)}`, 'i'))
      .or(this.page.getByText(/Hide Pet/i))
      .first()
      .waitFor({ timeout: 15_000 });
  }

  async confirmHidePet(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.page.getByRole('button', { name: 'Hide', exact: true }).last().click();
    await this.page
      .getByText(/pet hidden|animal masqué|hidden from your list/i)
      .first()
      .waitFor({ timeout: 15_000 })
      .catch(() => undefined);
    await this.page.waitForTimeout(1000);
    await refreshFlutterAccessibility(this.page);
  }

  async expectPetHidden(name: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      await expect(
        this.page
          .getByRole('button', { name: new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i') })
          .or(this.page.getByRole('group', { name: new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i') })),
      ).toHaveCount(0);
    }).toPass({ timeout: 20_000 });
  }

  async expectSectionHeader(title: string): Promise<void> {
    await this.page.getByText(title, { exact: true }).first().waitFor({ timeout: 30_000 });
  }

  /** Org pets show aria-label "Pet: Name, OrgName, …" on the home list. */
  async expectPetUnderOrganization(petName: string, orgName: string): Promise<void> {
    await semanticsByName(
      this.page,
      new RegExp(`Pet:\\s*${escapeRegExp(petName)}.*${escapeRegExp(orgName)}`, 'i'),
    ).waitFor({ timeout: 30_000 });
  }

  async goHome(): Promise<void> {
    await waitForFlutterRoute(this.page, '/g/home');
    await this.expectLoaded();
  }
}
