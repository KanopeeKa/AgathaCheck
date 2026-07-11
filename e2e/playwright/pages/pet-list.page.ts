import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  expectAppBarTitle,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoute,
} from '../support/flutter';

/**
 * Home / pet list screen (`/`).
 * Maps to: flutter_app/test/bdd/features/pet_profiles.feature
 */
export class PetListPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page
      .getByRole('button', { name: 'To Do' })
      .or(this.page.getByRole('button', { name: 'Add Pet' }))
      .or(this.page.getByText('No pets yet'))
      .or(this.page.getByRole('banner', { name: /Agatha Track/i }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openHealthDashboard(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'To Do' }).click();
    await this.page.getByRole('button', { name: 'Add Health Event' }).waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.getByText('No pets yet').waitFor();
    await this.page.getByRole('button', { name: 'Add Pet' }).waitFor();
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
    await this.page.getByRole('button', { name: 'Organizations' }).click();
    await this.page
      .getByRole('button', { name: 'Create' })
      .or(this.page.getByRole('button', { name: /Rescue Hearts|Partner Shelter/i }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openVets(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await this.page.getByRole('button', { name: 'Veterinarians' }).click();
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
    const startX = box.x + box.width * 0.88;
    const endX = box.x + box.width * 0.05;
    const midY = box.y + box.height / 2;
    await this.page.mouse.move(startX, midY);
    await this.page.mouse.down();
    for (let i = 1; i <= 20; i++) {
      await this.page.mouse.move(startX + (endX - startX) * (i / 20), midY);
    }
    await this.page.mouse.up();
    await this.page.waitForTimeout(750);
  }

  async confirmHidePet(): Promise<void> {
    // AlertDialog title "Hide Pet", buttons: "Cancel", "Hide"
    await this.page.getByRole('button', { name: 'Hide' }).last().click();
    await this.page.waitForTimeout(1_000);
  }

  async expectPetHidden(name: string): Promise<void> {
    await expect(
      this.page
        .getByRole('button', { name: new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i') })
        .or(this.page.getByRole('group', { name: new RegExp(`Pet:\\s*${escapeRegExp(name)}`, 'i') })),
    ).toHaveCount(0);
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
    await waitForFlutterRoute(this.page, '/');
    await this.expectLoaded();
  }
}
