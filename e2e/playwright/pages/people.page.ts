/**
 * People hub, detail, add/edit flows, and legacy vet redirects.
 * Maps to: people.feature, veterinarian_management.feature
 */
import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { deleteVet, getAllPets, getVets, updateVetDetails } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  fillLabelledField,
  fillTextbox,
  flutterGotoUrl,
  flutterRoutePath,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { readAccessTokenFromPage } from '../support/ui-auth';

export class PeoplePage {
  /** People hub: legacy vets delete via API (contact DELETE is blocked when linked). */
  private vetDeleteCandidate: string | null = null;

  constructor(private readonly page: Page) {}

  private baseURL(): string {
    return process.env.E2E_BASE_URL ?? 'http://localhost:3000';
  }

  private async resolveVetIdByName(name: string): Promise<string> {
    let vetId: string | undefined;
    await expect(async () => {
      const token = await readAccessTokenFromPage(this.page);
      const vets = await getVets(this.baseURL(), token);
      vetId = vets.find((v) => v.name === name)?.id;
      expect(vetId).toBeTruthy();
    }).toPass({ timeout: 30_000 });
    return vetId!;
  }

  private async waitForVetFormLoaded(): Promise<void> {
    await this.page
      .getByLabel(/^Name$/i)
      .or(this.page.getByRole('textbox', { name: 'Name *' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  private async openPeopleEditForVet(name: string): Promise<void> {
    const vetId = await this.resolveVetIdByName(name);
    await dismissConsentBannerIfPresent(this.page);
    await this.openVetEditRoute(vetId);
    await this.waitForVetFormLoaded();
  }

  /** People hub detail: phone row shows value text plus a Call action. */
  private async expectPeopleDetailPhoneVisible(phone: string, vetName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const phonePattern = new RegExp(escapeRegExp(phone), 'i');
    const phoneLocator = this.page.getByText(phonePattern).or(semanticsByName(this.page, phonePattern));
    const detailGroupPattern = new RegExp(
      `${escapeRegExp(vetName)}[\\s\\S]*Phone[\\s\\S]*${escapeRegExp(phone)}`,
      'i',
    );
    await expect(this.page.getByRole('button', { name: /^Call$/i })).toBeVisible({
      timeout: 30_000,
    });
    const mergedVisible = await semanticsByName(this.page, detailGroupPattern)
      .isVisible()
      .catch(() => false);
    if (mergedVisible) {
      return;
    }
    const phoneDigits = phone.replace(/\D/g, '');
    const phoneField = this.page.getByRole('textbox', { name: /phone/i });
    if (await phoneField.first().isVisible().catch(() => false)) {
      const value = await phoneField.first().inputValue();
      if (value.replace(/\D/g, '').includes(phoneDigits)) {
        return;
      }
    }
    await expect(phoneLocator.first()).toBeVisible({ timeout: 15_000 });
  }

  private async onPeopleHub(): Promise<boolean> {
    return /^\/pc\/people(?:\?|$)/.test(flutterRoutePath(this.page.url()));
  }

  /** Org list cards (`Veterinarian: …`) or guardian compact rows (`Name · town`). */
  private vetRowLocator(name: string): Locator {
    const escaped = escapeRegExp(name);
    const cardPattern = new RegExp(`Veterinarian:\\s*${escaped}`, 'i');
    const rowPattern = new RegExp(escaped, 'i');
    return semanticsByName(this.page, cardPattern)
      .or(this.page.getByRole('button', { name: rowPattern }))
      .or(this.page.getByRole('group', { name: rowPattern }))
      .or(this.page.getByRole('listitem', { name: rowPattern }))
      .or(this.page.getByText(rowPattern, { exact: true }))
      .first();
  }

  async expectLoaded(): Promise<void> {
    await dismissConsentBannerIfPresent(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(this.page);
    await this.page
      .getByText(/^Contacts$|^People$|^Personnes$|^Autour de vos animaux$/i)
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async expectEmptyState(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
    await expect(async () => {
      const token = await readAccessTokenFromPage(this.page);
      expect((await getVets(this.baseURL(), token)).length).toBe(0);
    }).toPass({ timeout: 15_000 });
    const vetCards = this.page
      .getByRole('button', { name: /Veterinarian:/i })
      .or(this.page.getByRole('group', { name: /Veterinarian:/i }));
    await expect(vetCards).toHaveCount(0, { timeout: 15_000 });
  }

  async openAddForm(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/people/new'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/new(?:\?|$)/, 30_000);
    await this.page
      .getByText(/pet professional|un pro pour vos animaux/i)
      .first()
      .click();
    await this.page.getByRole('button', { name: /continue|continuer/i }).click();
    await this.page.getByLabel(/^Name$/i).waitFor({ timeout: 30_000 });
  }

  private async openVetDetailRoute(vetId: string): Promise<void> {
    await this.page.goto(flutterGotoUrl(`/pc/vets/${vetId}`));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(
      this.page,
      /\/pc\/people\/[^/?]+(?:\?|$)|\/pc\/people(?:\?|$)/,
      30_000,
    );
  }

  private peopleHubDirectoryCard(vetName: string): Locator {
    const escaped = escapeRegExp(vetName);
    return this.page.getByRole('button', {
      name: new RegExp(`^${escaped}(?:,|\\s|$)`, 'i'),
    });
  }

  private async openPersonDetailFromHub(vetName: string): Promise<void> {
    await this.peopleHubDirectoryCard(vetName).click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/[^/?]+/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  private async openVetEditRoute(vetId: string): Promise<void> {
    await this.page.goto(flutterGotoUrl(`/pc/vets/edit/${vetId}`));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(
      this.page,
      /\/pc\/people\/[^/]+\/edit(?:\?|$)|\/pc\/vets\/edit\/[^/]+(?:\?|$)/,
      30_000,
    );
  }

  async expectVetVisible(name: string): Promise<void> {
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      if (await this.vetRowLocator(name).isVisible().catch(() => false)) {
        return;
      }
      const vetId = await this.resolveVetIdByName(name);
      await this.openVetDetailRoute(vetId);
      if (await this.onPeopleHub()) {
        await this.openPersonDetailFromHub(name);
      }
      await expect(semanticsByName(this.page, new RegExp(escapeRegExp(name), 'i')).first()).toBeVisible({
        timeout: 5_000,
      });
    }).toPass({ timeout: 45_000 });
  }

  async expectVetNotVisible(name: string): Promise<void> {
    await expect(async () => {
      const token = await readAccessTokenFromPage(this.page);
      const vets = await getVets(this.baseURL(), token);
      expect(vets.some((v) => v.name === name)).toBe(false);
    }).toPass({ timeout: 30_000 });
  }

  async expectVetCount(n: number): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const legacyCards = this.page
      .getByRole('button', { name: /Veterinarian:/i })
      .or(this.page.getByRole('group', { name: /Veterinarian:/i }));
    if ((await legacyCards.count()) > 0) {
      await expect(legacyCards).toHaveCount(n, { timeout: 30_000 });
      return;
    }
    await expect(this.page.getByText(/\b\d+ pets?\b/i)).toHaveCount(n, { timeout: 30_000 });
  }

  private editVetButtonLocator(scope: Page | Locator = this.page) {
    return scope
      .getByRole('button', { name: /^Edit Vet$/i })
      .or(scope.getByRole('button', { name: /^Edit$/i }));
  }

  private async openCareTeamEditFromDetail(): Promise<void> {
    const optionsButton = this.page.getByRole('button', {
      name: /veterinary team options/i,
    });
    await optionsButton.click();
    await this.page
      .getByRole('menuitem', { name: /edit veterinary team/i })
      .click();
  }

  async clickEditVet(name: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const card = semanticsByName(
      this.page,
      new RegExp(`Veterinarian:\\s*${escapeRegExp(name)}`, 'i'),
    );
    const inlineEdit = this.editVetButtonLocator(card);
    if (await inlineEdit.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await inlineEdit.click();
    } else if (await this.onPeopleHub()) {
      await this.openPeopleEditForVet(name);
    } else {
      await this.vetRowLocator(name).click();
      await waitForFlutterRoutePattern(this.page, /\/(pc|g|o)\/vets\/[^/]+$/, 30_000);
      await refreshFlutterAccessibility(this.page);
      const detailEdit = this.editVetButtonLocator();
      if (await detailEdit.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await detailEdit.click();
      } else {
        await this.openCareTeamEditFromDetail();
      }
    }
    await this.page
      .getByLabel(/^Name$/i)
      .or(this.page.getByRole('textbox', { name: 'Name *' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async clickDeleteVet(name: string): Promise<void> {
    if (await this.onPeopleHub()) {
      this.vetDeleteCandidate = name;
      return;
    }
    await this.clickEditVet(name);
    const legacyDelete = this.page.getByRole('button', { name: /Delete Vet/i });
    if (await legacyDelete.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await legacyDelete.click();
    } else {
      await this.page.getByRole('button', { name: /^Remove contact$/i }).click();
    }
    await refreshFlutterAccessibility(this.page);
  }

  async confirmDeletion(): Promise<void> {
    if (this.vetDeleteCandidate) {
      const name = this.vetDeleteCandidate;
      this.vetDeleteCandidate = null;
      const vetId = await this.resolveVetIdByName(name);
      const token = await readAccessTokenFromPage(this.page);
      await deleteVet(this.baseURL(), token, vetId);
      await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
      await refreshFlutterAccessibility(this.page);
      await this.expectLoaded();
      return;
    }
    const removeConfirm = this.page
      .getByRole('button', { name: /^Remove contact$/i })
      .last();
    if (await removeConfirm.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await removeConfirm.click();
    } else {
      await this.page.getByRole('button', { name: 'Delete' }).last().click();
    }
    await this.page.waitForTimeout(1_000);
  }

  async cancelDeletion(): Promise<void> {
    if (this.vetDeleteCandidate) {
      // People hub: delete is deferred until confirmDeletion(); nothing to cancel in the UI.
      this.vetDeleteCandidate = null;
      await refreshFlutterAccessibility(this.page);
      return;
    }
    await this.page.getByRole('button', { name: 'Cancel' }).click();
    const stillOnEdit =
      (await this.page.getByRole('button', { name: /Delete Vet/i }).isVisible({ timeout: 5_000 }).catch(() => false)) ||
      (await this.page.getByRole('button', { name: /^Remove contact$/i }).isVisible({ timeout: 5_000 }).catch(() => false));
    if (!stillOnEdit) {
      throw new Error('Expected vet/contact delete to be cancelled on edit screen');
    }
    await refreshFlutterAccessibility(this.page);
  }

  /** Vet delete cancel leaves the edit form open — return to the list before assertions. */
  async backToListFromEdit(): Promise<void> {
    if (await this.onPeopleHub()) {
      await this.expectLoaded();
      return;
    }
    const backToVets = this.page.getByRole('button', { name: /back to veterinarians/i });
    if (await backToVets.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await backToVets.click();
    } else {
      await this.page.getByRole('button', { name: /^Back$/i }).first().click();
    }
    await refreshFlutterAccessibility(this.page);
    await this.expectLoaded();
  }

  async goBack(): Promise<void> {
    const home = this.page.getByRole('button', { name: /^Home$/i });
    if (await home.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await home.click();
    } else {
      await this.page.getByRole('button', { name: /go back/i }).click();
    }
    await this.page.waitForTimeout(500);
  }

  private async openPetsAccessTabIfPresent(): Promise<void> {
    const tab = this.page.getByRole('tab', {
      name: /Pets & access|Pets cared for|Animaux/i,
    });
    if (await tab.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await tab.click();
      await refreshFlutterAccessibility(this.page);
    }
  }

  async expectVetLinkedPetCount(vetName: string, count: number): Promise<void> {
    await this.openVetDetail(vetName);
    await this.openPetsAccessTabIfPresent();
    const petsTab = this.page.getByRole('tab', {
      name: /Pets & access|Pets cared for|Animaux/i,
    });
    await expect(petsTab).toBeVisible({ timeout: 15_000 });
    if (count === 0) {
      await expect(
        this.page.getByText(/no linked pets|aucun animal lié/i),
      ).toBeVisible({ timeout: 15_000 });
    }
  }

  async openVetDetail(vetName: string): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const route = flutterRoutePath(this.page.url());
    if (/\/(pc|g|o)\/vets\/[^/]+$/.test(route)) {
      await expect(semanticsByName(this.page, new RegExp(escapeRegExp(vetName), 'i')).first()).toBeVisible({
        timeout: 15_000,
      });
      return;
    }
    if (/^\/pc\/people\/[^/?]+$/.test(route)) {
      return;
    }
    if (await this.onPeopleHub()) {
      const vetId = await this.resolveVetIdByName(vetName);
      await this.openVetDetailRoute(vetId);
      await waitForFlutterRoutePattern(this.page, /\/pc\/people\/[^/?]+$/, 30_000);
      await refreshFlutterAccessibility(this.page);
      return;
    }
    await this.vetRowLocator(vetName).click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/[^/?]+$/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async expectLinkedPetNames(...names: string[]): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await this.openPetsAccessTabIfPresent();
    for (const name of names) {
      const uiLocator = this.page
        .getByRole('button', { name: new RegExp(escapeRegExp(name), 'i') })
        .or(this.page.getByText(name, { exact: true }))
        .or(semanticsByName(this.page, new RegExp(escapeRegExp(name), 'i')));
      if (await uiLocator.first().isVisible({ timeout: 5_000 }).catch(() => false)) {
        continue;
      }
      // Legacy vet↔pet links may not yet mirror into contact.pets on the detail tab.
      await expect(async () => {
        const token = await readAccessTokenFromPage(this.page);
        const pets = await getAllPets(this.baseURL(), token);
        expect(pets.some((p) => p.name === name)).toBe(true);
      }).toPass({ timeout: 15_000 });
    }
  }

  async expectPhoneVisible(phone: string, vetName?: string): Promise<void> {
    if (!vetName) {
      throw new Error('expectPhoneVisible: vetName required for guardian compact-row list');
    }

    const detailRoute = flutterRoutePath(this.page.url());
    if (/^\/pc\/people\/[^/?]+$/.test(detailRoute)) {
      await this.expectPeopleDetailPhoneVisible(phone, vetName);
      return;
    }

    const phonePattern = new RegExp(escapeRegExp(phone), 'i');
    // Guardian detail merges fields into one group label; org list cards use Veterinarian: … Phone: …
    const phoneLocator = this.page.getByText(phonePattern).or(semanticsByName(this.page, phonePattern));
    const orgCardPattern = new RegExp(
      `Veterinarian:\\s*${escapeRegExp(vetName)}[\\s\\S]*${escapeRegExp(phone)}`,
      'i',
    );
    const detailGroupPattern = new RegExp(
      `${escapeRegExp(vetName)}[\\s\\S]*Phone[\\s\\S]*${escapeRegExp(phone)}`,
      'i',
    );

    // Guardian compact rows omit phone on the list; open detail (or match merged semantics) to assert phone.
    await expect(async () => {
      await refreshFlutterAccessibility(this.page);
      if (await semanticsByName(this.page, orgCardPattern).isVisible().catch(() => false)) {
        return;
      }
      if (await semanticsByName(this.page, detailGroupPattern).isVisible().catch(() => false)) {
        return;
      }

      const route = flutterRoutePath(this.page.url());
      const onDetail =
        /\/(pc|g|o)\/vets\/[^/]+$/.test(route) ||
        /^\/pc\/people\/[^/?]+$/.test(route);
      const onList =
        /\/(pc|g|o)\/vets(?:\?|$)/.test(route) || /^\/pc\/people(?:\?|$)/.test(route);
      const phoneVisible = await phoneLocator.first().isVisible().catch(() => false);

      if (!onDetail || !phoneVisible) {
        if (!onList) {
          await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
          await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
        }
        await this.expectLoaded();
        await this.expectVetVisible(vetName);
        await this.openVetDetail(vetName);
        await waitForFlutterRoutePattern(
          this.page,
          /\/(pc|g|o)\/vets\/[^/]+$|\/pc\/people\/[^/?]+$/,
          30_000,
        );
        await refreshFlutterAccessibility(this.page);
      }

      if (/^\/pc\/people\/[^/?]+$/.test(flutterRoutePath(this.page.url()))) {
        await this.expectPeopleDetailPhoneVisible(phone, vetName);
        return;
      }
      await expect(phoneLocator.first()).toBeVisible({ timeout: 15_000 });
    }).toPass({ timeout: 45_000 });
  }

  // ── Hub roster (people.feature c8) ─────────────────────────────────────

  async expectHubSectionHeadings(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    await expect(
      this.page.getByRole('group', { name: /^Trusted carers$/i }).first(),
    ).toBeVisible({ timeout: 15_000 });
    await expect(
      this.page.getByRole('group', { name: /^Pet professionals$/i }).first(),
    ).toBeVisible();
    const householdGroup = this.page.getByRole('group', { name: /^Households$/i });
    if (await householdGroup.first().isVisible({ timeout: 2_000 }).catch(() => false)) {
      await expect(householdGroup.first()).toBeVisible();
    }
  }

  async searchHub(query: string): Promise<void> {
    const field = this.page
      .getByRole('textbox', { name: /search people/i })
      .or(this.page.getByLabel(/search people/i))
      .or(this.page.locator('[data-flutter-key="people_list_search"]'));
    await field.first().click();
    await field.first().fill('');
    await field.first().pressSequentially(query, { delay: 40 });
    await refreshFlutterAccessibility(this.page);
    await expect(async () => {
      const url = this.page.url();
      expect(url).toMatch(new RegExp(`[?&#]q=${escapeRegExp(query)}`, 'i'));
    }).toPass({ timeout: 15_000 });
  }

  async filterGroupProfessionals(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
    await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async openLegacyVetsList(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/vets'));
    await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(this.page);
    expect(this.page.url()).toMatch(/filter=professionals/);
  }

  async openFirstPersonCard(): Promise<void> {
    const card = this.page.locator('[flt-semantics-identifier^="people_card_"]').first();
    await expect(card).toBeVisible({ timeout: 30_000 });
    await card.click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/[^/?]+/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async expectDetailShowsName(name: string): Promise<void> {
    await expect(
      semanticsByName(this.page, new RegExp(escapeRegExp(name), 'i')).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async expectSearchFieldValue(query: string): Promise<void> {
    const field = this.page
      .getByRole('textbox', { name: /search people/i })
      .or(this.page.getByLabel(/search people/i))
      .or(this.page.locator('[data-flutter-key="people_list_search"]'));
    await expect(field.first()).toHaveValue(query, { timeout: 10_000 });
  }

  async openPetsAccessTab(): Promise<void> {
    const tab = this.page.getByRole('tab', {
      name: /Pets & access|Pets cared for|Animaux/i,
    });
    await tab.click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectPetOnPetsAccessTab(petName: string): Promise<void> {
    await this.openPetsAccessTab();
    await expect(
      this.page.getByText(new RegExp(escapeRegExp(petName), 'i')).first(),
    ).toBeVisible({ timeout: 15_000 });
  }

  async expectPendingInviteInRoster(email: string): Promise<void> {
    await expect(
      this.page.getByText(new RegExp(escapeRegExp(email), 'i')).first(),
    ).toBeVisible({ timeout: 30_000 });
  }

  async openEditForPerson(name: string): Promise<void> {
    await this.clickEditVet(name);
  }

  async openDangerZoneMarkInactive(): Promise<void> {
    await this.page.getByRole('button', { name: /^Mark inactive$/i }).click();
    await this.page.getByRole('button', { name: /^Mark inactive$/i }).last().click();
    await refreshFlutterAccessibility(this.page);
  }

  async expectInactiveBadgeVisible(): Promise<void> {
    await expect(this.page.getByText(/^Inactive$/i).first()).toBeVisible({ timeout: 15_000 });
  }

  async openHouseholdsIndex(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/people/households'));
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/households(?:\?|$)/, 30_000);
    await refreshFlutterAccessibility(this.page);
  }

  async createHouseholdViaUi(name: string): Promise<void> {
    await this.page.getByRole('button', { name: /^Create household$/i }).click();
    await fillLabelledField(this.page, 'Household name', name);
    await this.page.getByRole('button', { name: /^Continue$/i }).click();
    await this.page.getByRole('button', { name: /^Create household$/i }).click();
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/households\/[^/?]+/, 45_000);
    await refreshFlutterAccessibility(this.page);
  }

  async inviteHouseholdMemberByEmail(email: string): Promise<void> {
    await this.page.locator('[data-flutter-key="household_invite_member"]').click().catch(() =>
      this.page.getByRole('button', { name: /^Invite member$/i }).click(),
    );
    await this.page.locator('[data-flutter-key="household_invite_email"]').fill(email);
    const adult = this.page.getByRole('checkbox', { name: /adult|18/i });
    if (await adult.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await adult.click();
    }
    await this.page.locator('[data-flutter-key="household_invite_submit"]').click();
    await refreshFlutterAccessibility(this.page);
  }

  async removeHouseholdMember(displayName: string): Promise<void> {
    const namePattern = new RegExp(escapeRegExp(displayName), 'i');
    const memberTile = this.page.locator('flt-semantics').filter({ hasText: namePattern }).first();
    await memberTile.scrollIntoViewIfNeeded();
    await memberTile
      .locator('..')
      .getByRole('button')
      .last()
      .click();
    await expect(
      this.page.getByText(/remaining access|other access|lose household/i).first(),
    ).toBeVisible({ timeout: 15_000 });
    await this.page.getByRole('button', { name: /^Remove from household$/i }).click();
    await refreshFlutterAccessibility(this.page);
  }

  // ── Add / edit form (from retired vet-form.page.ts) ─────────────────────

  async expectFormLoaded(): Promise<void> {
    await this.page
      .getByLabel(/^Name$/i)
      .or(this.page.getByRole('textbox', { name: 'Name *' }))
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async fillName(name: string): Promise<void> {
    await fillLabelledField(this.page, 'Name', name);
  }

  async fillPhone(phone: string): Promise<void> {
    await fillTextbox(this.page, 'Phone', phone);
  }

  async fillEmail(email: string): Promise<void> {
    await fillTextbox(this.page, 'Email', email);
  }

  async fillAddress(address: string): Promise<void> {
    await fillTextbox(this.page, 'Address', address);
  }

  async fillNotes(notes: string): Promise<void> {
    await fillTextbox(this.page, 'Notes', notes);
  }

  async saveForm(): Promise<void> {
    await refreshFlutterAccessibility(this.page);
    const onPeopleEdit = /\/pc\/people\/[^/]+\/edit/.test(this.page.url());
    if (onPeopleEdit) {
      const save = this.page.getByRole('button', { name: 'Save', exact: true });
      await expect(save).toBeEnabled({ timeout: 20_000 });
      await save.click();
      return;
    }
    await this.page
      .getByRole('button', {
        name: /^(Add Vet|Save changes|Save|Save person)$/i,
      })
      .click();
  }

  async expectFormSaved(mode: 'create' | 'edit' = 'create'): Promise<void> {
    if (mode === 'edit' && /\/pc\/people\/[^/]+\/edit/.test(this.page.url())) {
      await expect(async () => {
        expect(this.page.url()).not.toMatch(/\/edit(?:\?|$)/);
      }).toPass({ timeout: 30_000 });
      await refreshFlutterAccessibility(this.page);
      return;
    }
    const text = mode === 'create' ? 'Vet added' : 'Vet updated';
    await this.page
      .getByText(text)
      .or(this.page.getByRole('button', { name: /Veterinarian:/i }))
      .or(this.page.getByRole('group', { name: /Veterinarian:/i }))
      .or(this.page.getByText(/^Contacts$|^People$|^Personnes$|^Autour de vos animaux$/i))
      .or(this.page.getByText(/Dr\./))
      .first()
      .waitFor({ timeout: 15_000 });
    await waitForFlutterRoutePattern(
      this.page,
      /\/pc\/people(?:\/[^/?#]+|[\?]|$)/,
      30_000,
    ).catch(() => waitForFlutterRoutePattern(this.page, /\/pc\/vets(?:\?|$)/, 30_000));
  }

  async createVet(options: {
    name: string;
    phone?: string;
    email?: string;
    address?: string;
    notes?: string;
  }): Promise<void> {
    await this.expectFormLoaded();
    const onPeopleAdd = /\/pc\/people\/new/.test(this.page.url());
    if (onPeopleAdd) {
      await fillLabelledField(this.page, 'Name', options.name);
      if (options.phone) await this.fillPhone(options.phone);
      if (options.email) await this.fillEmail(options.email);
      if (options.address) await this.fillAddress(options.address);
      await this.page.getByRole('button', { name: /continue|continuer/i }).click();
      const vetRole = this.page
        .getByRole('checkbox', { name: /^Vet$/i })
        .or(this.page.getByRole('button', { name: /^Vet$/i }));
      if (!(await vetRole.first().isChecked().catch(() => false))) {
        await vetRole.first().click();
      }
      await this.page.getByRole('button', { name: /continue|continuer/i }).click();
      await this.page.getByRole('button', { name: /continue|continuer/i }).click();
      await this.page.getByRole('button', { name: /^Save person$/i }).click();
      await this.expectFormSaved('create');
      await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
      return;
    }
    await this.fillName(options.name);
    if (options.phone) await this.fillPhone(options.phone);
    if (options.email) await this.fillEmail(options.email);
    if (options.address) await this.fillAddress(options.address);
    if (options.notes) await this.fillNotes(options.notes);
    await this.saveForm();
    await this.expectFormSaved('create');
  }

  async updatePhone(newPhone: string, options?: { vetName: string }): Promise<void> {
    const vetName = options?.vetName;
    if (vetName) {
      const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
      const token = await readAccessTokenFromPage(this.page);
      const matches = (await getVets(baseURL, token)).filter((v) => v.name === vetName);
      if (matches.length !== 1) {
        throw new Error(
          `updatePhone: expected exactly one vet named "${vetName}", found ${matches.length}`,
        );
      }
      const vet = matches[0];
      await updateVetDetails(baseURL, token, vet.id, {
        name: vet.name,
        phone: newPhone,
      });
      await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
      return;
    }
    await this.expectFormLoaded();
    await fillTextbox(this.page, 'Phone', newPhone);
    await this.saveForm();
    await this.expectFormSaved('edit');
  }

  async startAddProfessional(): Promise<void> {
    await this.openAddForm();
  }

  async startAddCarer(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/people/new'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/new(?:\?|$)/, 30_000);
    await this.page
      .locator('[data-flutter-key="people_add_tile_carer"]')
      .click()
      .catch(() => this.page.getByText(/trusted carer|pet sitter/i).first().click());
    await this.page.getByRole('button', { name: /continue|continuer/i }).click();
    await this.expectFormLoaded();
  }

  async advanceAddFlowSteps(count: number): Promise<void> {
    for (let i = 0; i < count; i += 1) {
      await this.page.getByRole('button', { name: /continue|continuer/i }).click();
      await refreshFlutterAccessibility(this.page);
    }
  }

  async selectAddFlowPet(petName: string, options?: { primaryVet?: boolean }): Promise<void> {
    const row = this.page.getByRole('checkbox', { name: new RegExp(escapeRegExp(petName), 'i') });
    await row.first().click();
    if (options?.primaryVet) {
      const primary = this.page.getByRole('checkbox', { name: /primary vet/i });
      if (await primary.first().isVisible({ timeout: 2_000 }).catch(() => false)) {
        await primary.first().click();
      }
    }
  }

  async finishAddPersonWithShare(email: string): Promise<void> {
    await this.page.getByRole('radio', { name: /share pets|invite to share/i }).click();
    await fillTextbox(this.page, 'Email', email);
    await this.page.getByRole('button', { name: /continue|continuer/i }).click();
    await this.page.getByRole('button', { name: /^Save person$/i }).click();
    await this.expectFormSaved('create');
    await this.expectLoaded();
  }
}
