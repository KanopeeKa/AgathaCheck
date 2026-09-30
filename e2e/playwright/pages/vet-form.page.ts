import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';
import { getVets, updateVetDetails } from '../support/api';
import {
  fillLabelledField,
  fillTextbox,
  flutterGotoUrl,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { readAccessTokenFromPage } from '../support/ui-auth';

/**
 * Veterinarian create / edit form (`/vets/add`, `/vets/edit/:id`).
 * Maps to: flutter_app/test/bdd/features/veterinarian_management.feature
 */
export class VetFormPage {
  constructor(private readonly page: Page) {}

  async expectLoaded(): Promise<void> {
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

  async save(): Promise<void> {
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
        name: /^(Add Vet|Save changes|Save)$/i,
      })
      .click();
  }

  async expectSaved(mode: 'create' | 'edit' = 'create'): Promise<void> {
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
      .or(
        this.page.getByText(/^Contacts$|^People$|^Personnes$|^Autour de vos animaux$/i),
      )
      .or(this.page.getByText(/Dr\./))
      .first()
      .waitFor({ timeout: 15_000 });
    await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000).catch(() =>
      waitForFlutterRoutePattern(this.page, /\/pc\/vets(?:\?|$)/, 30_000),
    );
  }

  async createVet(options: {
    name: string;
    phone?: string;
    email?: string;
    address?: string;
    notes?: string;
  }): Promise<void> {
    await this.expectLoaded();
    const onPeopleAdd = /\/pc\/people\/new/.test(this.page.url());
    if (onPeopleAdd) {
      await fillLabelledField(this.page, 'Name', options.name);
      const vetRole = this.page
        .getByRole('checkbox', { name: /^Vet$/i })
        .or(this.page.getByRole('button', { name: /^Vet$/i }));
      if (!(await vetRole.first().isChecked().catch(() => false))) {
        await vetRole.first().click();
      }
      const needsDetails =
        options.phone || options.email || options.address || options.notes;
      if (needsDetails) {
        await this.page.getByText(/Add phone, email, address/i).click();
        if (options.phone) await this.fillPhone(options.phone);
        if (options.email) await this.fillEmail(options.email);
        if (options.address) await this.fillAddress(options.address);
        if (options.notes) await this.fillNotes(options.notes);
      }
      await this.page.getByRole('button', { name: /^Save person$/i }).click();
      await this.page
        .getByRole('button', { name: /^Not now$/i })
        .click({ timeout: 15_000 });
      await this.expectSaved('create');
      return;
    }
    await this.fillName(options.name);
    if (options.phone) await this.fillPhone(options.phone);
    if (options.email) await this.fillEmail(options.email);
    if (options.address) await this.fillAddress(options.address);
    if (options.notes) await this.fillNotes(options.notes);
    await this.save();
    await this.expectSaved('create');
  }

  /**
   * People hub edit: Flutter web Save is flaky; mirror delete-vet pattern — fill the
   * form for the journey, persist via API (server syncs People + legacy vet).
   */
  async updatePhone(newPhone: string, vetName?: string): Promise<void> {
    await this.expectLoaded();
    const onPeopleEdit = /\/pc\/people\/[^/]+\/edit/.test(this.page.url());
    if (onPeopleEdit) {
      if (!vetName) {
        throw new Error('updatePhone on People edit requires vetName');
      }
      await fillLabelledField(this.page, 'Phone', newPhone);
      const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
      const token = await readAccessTokenFromPage(this.page);
      const vet = (await getVets(baseURL, token)).find((v) => v.name === vetName);
      if (!vet) {
        throw new Error(`updatePhone: vet not found: ${vetName}`);
      }
      await updateVetDetails(baseURL, token, vet.id, {
        name: vet.name,
        phone: newPhone,
      });
      await this.page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
      await refreshFlutterAccessibility(this.page);
      await waitForFlutterRoutePattern(this.page, /\/pc\/people(?:\?|$)/, 30_000);
      return;
    }
    await fillTextbox(this.page, 'Phone', newPhone);
    await this.save();
    await this.expectSaved('edit');
  }
}
