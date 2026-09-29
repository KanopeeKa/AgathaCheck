/**
 * Veterinarian list screen (`/pc/vets`, `/o/vets`).
 * Maps to: flutter_app/test/bdd/features/veterinarian_management.feature
 */
import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { getVets } from '../support/api';
import {
  dismissConsentBannerIfPresent,
  escapeRegExp,
  flutterGotoUrl,
  flutterRoutePath,
  refreshFlutterAccessibility,
  semanticsByName,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { readAccessTokenFromPage } from '../support/ui-auth';

export class VetListPage {
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

  private async resolveContactIdByVetName(name: string): Promise<string> {
    let contactId: string | undefined;
    await expect(async () => {
      const token = await readAccessTokenFromPage(this.page);
      const vetId = await this.resolveVetIdByName(name);
      const res = await fetch(`${this.baseURL()}/backend/api/people/contacts`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.ok).toBeTruthy();
      const contacts = (await res.json()) as Array<{ id: string; legacy_vet_id?: string | null }>;
      contactId = contacts.find((c) => c.legacy_vet_id === vetId)?.id;
      expect(contactId).toBeTruthy();
    }).toPass({ timeout: 30_000 });
    return contactId!;
  }

  private async openPeopleEditForVet(name: string): Promise<void> {
    const contactId = await this.resolveContactIdByVetName(name);
    await this.page.goto(flutterGotoUrl(`/pc/people/${contactId}/edit`));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/[^/]+\/edit/, 30_000);
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
    await this.page
      .getByText(/no pet professionals yet|no veterinarians yet/i)
      .first()
      .waitFor({ timeout: 30_000 });
  }

  async openAddForm(): Promise<void> {
    await this.page.goto(flutterGotoUrl('/pc/people/new?roles=vet'));
    await refreshFlutterAccessibility(this.page);
    await waitForFlutterRoutePattern(this.page, /\/pc\/people\/new(?:\?|$)/, 30_000);
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
      const res = await fetch(`${this.baseURL()}/backend/api/vets/${vetId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.ok).toBeTruthy();
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
      const name = this.vetDeleteCandidate;
      await this.openPeopleEditForVet(name);
      await this.page.getByRole('button', { name: /^Remove contact$/i }).click();
      await this.page.getByRole('button', { name: 'Cancel' }).click();
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

  async expectVetLinkedPetCount(vetName: string, _count: number): Promise<void> {
    await this.openVetDetail(vetName);
    await expect(
      this.page.getByText(
        /Related pets|Pets cared for|Animaux concernés|Animaux pris en charge/i,
      ),
    ).toBeVisible({ timeout: 15_000 });
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
    for (const name of names) {
      await this.page
        .getByRole('button', { name: new RegExp(name, 'i') })
        .or(this.page.getByText(name, { exact: true }))
        .first()
        .waitFor({ timeout: 15_000 });
    }
  }

  async expectPhoneVisible(phone: string, vetName?: string): Promise<void> {
    if (!vetName) {
      throw new Error('expectPhoneVisible: vetName required for guardian compact-row list');
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
      const onDetail = /\/(pc|g|o)\/vets\/[^/]+$/.test(route);
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
        await waitForFlutterRoutePattern(this.page, /\/(pc|g|o)\/vets\/[^/]+$/, 30_000);
        await refreshFlutterAccessibility(this.page);
      }

      await expect(phoneLocator.first()).toBeVisible({ timeout: 15_000 });
    }).toPass({ timeout: 45_000 });
  }
}
