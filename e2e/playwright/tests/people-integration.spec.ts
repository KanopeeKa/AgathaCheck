/**
 * @bdd pet_profiles.feature
 * @bdd health_tracking.feature
 * @bdd away_planning.feature
 * Scenario: Buddy's emergency card shows the primary vet set from Contacts, with a call action
 * Scenario: Set Buddy's out-of-hours vet from People around Buddy
 * Scenario: Pick a care provider and add a new one inline from the Care Item form
 * Scenario: An inactive contact isn't offered in the care provider picker but stays visible on items already using it
 * Scenario: Assign an absence carer with the picker; the handover lists emergency contacts and vets
 */
import { readFileSync } from 'node:fs';

import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { AwayPlanningPage } from '../pages/away-planning.page';
import { CareItemPage } from '../pages/care-item.page';
import { HealthDashboardPage } from '../pages/health-dashboard.page';
import { HealthEntryFormPage } from '../pages/health-entry-form.page';
import { PeoplePage } from '../pages/people.page';
import { PetListPage } from '../pages/pet-list.page';
import {
  addPetPeopleRelationship,
  createHealthEntry,
  createPeopleContact,
  createPet,
  createPlannedAbsence,
  createVetFull,
  getPetPeopleRelationships,
  getPeopleContactIdForVetName,
  patchPeopleContact,
  setPetPeopleSlot,
  signupUser,
} from '../support/api';
import { enableFlutterAccessibility, flutterGotoUrl } from '../support/flutter';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe('People client integration journeys', () => {
  test("@P1 Buddy's emergency card shows primary vet from Contacts with call action", async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'Buddy', 'Dog');
    await createVetFull(root, user.accessToken, {
      name: 'Buddy Primary Vet',
      phone: '555-0199',
    });
    const primaryContactId = await getPeopleContactIdForVetName(
      root,
      user.accessToken,
      'Buddy Primary Vet',
    );
    await setPetPeopleSlot(root, user.accessToken, pet.id, 'primary_vet', primaryContactId);

    const petList = await loginAs(page, user, { experience: 'guardian' });
    const peopleLoaded = page.waitForResponse(
      (res) => res.url().includes(`/pets/${pet.id}/people`) && res.ok(),
    );
    await petList.openPet('Buddy', pet.id);
    await peopleLoaded;

    const people = new PeoplePage(page);
    await people.expectPeopleAroundPetSection('Buddy');
    await people.expectEmergencyCardShowsContact('Buddy Primary Vet');
    await people.expectEmergencyPrimaryVetCallAction();
  });

  test("@P1 set Buddy's out-of-hours vet from People around Buddy", async ({ page }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'Buddy', 'Dog');
    await createVetFull(root, user.accessToken, { name: 'Day Vet' });
    const dayContactId = await getPeopleContactIdForVetName(root, user.accessToken, 'Day Vet');
    await setPetPeopleSlot(root, user.accessToken, pet.id, 'primary_vet', dayContactId);
    const oohContact = await createPeopleContact(root, user.accessToken, {
      name: 'Night Vet Clinic',
      kind: 'organisation',
      roles: ['vet'],
      phone: '555-0200',
    });
    const oohContactId = oohContact.id;
    await addPetPeopleRelationship(root, user.accessToken, pet.id, oohContactId, 'care_provider');

    await loginAs(page, user, { experience: 'guardian' });
    await page.goto(flutterGotoUrl('/pc/people?filter=professionals'));
    await expect(page.getByText('Night Vet Clinic').first()).toBeVisible({ timeout: 30_000 });

    const peopleLoaded = page.waitForResponse(
      (res) => res.url().includes(`/pets/${pet.id}/people`) && res.ok(),
    );
    await page.goto(flutterGotoUrl(`/pet/${pet.id}`));
    await peopleLoaded;

    const people = new PeoplePage(page);
    await people.expectPeopleAroundPetSection('Buddy');
    await people.openPetEmergencyManage();
    await people.setPetSlotFromManageSheet(
      'pet_slot_out_of_hours_vet',
      oohContactId,
      'Night Vet Clinic',
    );
    await people.expectEmergencyCardShowsContact('Night Vet Clinic');
  });

  test('@P1 pick care provider and add inline from care item form', async ({ page }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const user = await signupUser(root);
    await createPet(root, user.accessToken, 'Buddy', 'Dog');
    const existing = await createPeopleContact(root, user.accessToken, {
      name: 'Grooming Pro',
      roles: ['groomer'],
    });

    await loginAs(page, user, { experience: 'guardian' });
    await enableFlutterAccessibility(page);
    await page.goto(`${root}/pc/events`);

    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.openAddHealthCareForm();

    const form = new HealthEntryFormPage(page);
    await form.expectLoaded();
    await form.selectPet('Buddy');
    await form.fillEntryName('Integration Groom');
    await form.selectCareFamily('Grooming');

    const people = new PeoplePage(page);
    await form.openCareProviderPicker();
    await people.selectPeoplePickerOption(existing.id);
    await form.expectCareProviderFieldShows('Grooming Pro');

    await form.openCareProviderPicker();
    const inlineName = 'Inline Sitter';
    await people.searchPeoplePicker(inlineName);
    await people.quickAddContactFromPicker(inlineName);
    await form.expectCareProviderFieldShows(inlineName);
  });

  test('@P1 inactive care provider hidden in picker but visible on existing item', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'Buddy', 'Dog');
    const provider = await createPeopleContact(root, user.accessToken, {
      name: 'Inactive Provider',
      roles: ['groomer'],
    });
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Provider Lock-in Groom',
      nextDueDate: dateOffset(14),
      careFamily: 'grooming',
      providerContactId: provider.id,
    });
    await patchPeopleContact(root, user.accessToken, provider.id, { active: false });

    await loginAs(page, user, { experience: 'guardian' });
    await enableFlutterAccessibility(page);

    const careItem = new CareItemPage(page);
    await careItem.open(pet.id, entry.id);
    await careItem.expectCareProviderVisible('Inactive Provider');

    await page.goto(flutterGotoUrl('/pc/events'));
    const dashboard = new HealthDashboardPage(page);
    await dashboard.expectLoaded();
    await dashboard.openAddHealthCareForm();

    const form = new HealthEntryFormPage(page);
    await form.expectLoaded();
    await form.selectPet('Buddy');
    await form.fillEntryName('New Groom');
    await form.selectCareFamily('Grooming');
    await form.openCareProviderPicker();

    const people = new PeoplePage(page);
    await people.expectPeoplePickerOptionHidden(provider.id);
    await page.keyboard.press('Escape');
  });

  test('@P1 assign absence carer; handover lists emergency contacts and vets', async ({
    page,
  }) => {
    test.setTimeout(180_000);
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'Buddy', 'Dog');
    const primaryVet = await createVetFull(root, user.accessToken, {
      name: 'Handover Primary Vet',
      phone: '555-0301',
    });
    const primaryContactId = await getPeopleContactIdForVetName(
      root,
      user.accessToken,
      'Handover Primary Vet',
    );
    await setPetPeopleSlot(root, user.accessToken, pet.id, 'primary_vet', primaryContactId);

    const oohVet = await createVetFull(root, user.accessToken, {
      name: 'Handover Night Vet',
      phone: '555-0302',
    });
    const oohContactId = await getPeopleContactIdForVetName(
      root,
      user.accessToken,
      'Handover Night Vet',
    );
    await setPetPeopleSlot(root, user.accessToken, pet.id, 'out_of_hours_vet', oohContactId);

    const carer = await createPeopleContact(root, user.accessToken, {
      name: 'Trip Carer Sam',
      roles: ['sitter'],
    });

    const absence = await createPlannedAbsence(root, user.accessToken, {
      startsOn: dateOffset(7),
      endsOn: dateOffset(14),
      petIds: [pet.id],
    });

    await loginAs(page, user, { experience: 'guardian' });
    const away = new AwayPlanningPage(page);
    await away.openPlan(absence.id);
    await away.assignContactCarer(pet.id, 'Buddy', carer.id);
    await away.expectPetCarerRow(pet.id, 'Buddy', 'Trip Carer Sam');

    const relationships = await getPetPeopleRelationships(root, user.accessToken, pet.id);
    expect(
      relationships
        .filter((r) => r.active)
        .map((r) => r.relationship_kind)
        .sort(),
    ).toEqual(expect.arrayContaining(['out_of_hours_vet', 'primary_vet']));

    const download = await away.downloadPetHandover('Buddy');
    const downloadPath = await download.path();
    expect(downloadPath).toBeTruthy();

    const pdfBytes = readFileSync(downloadPath!);
    expect(pdfBytes.subarray(0, 5).toString('utf8')).toBe('%PDF-');
    expect(pdfBytes.length).toBeGreaterThan(500);
    const suggested = await download.suggestedFilename();
    expect(suggested.toLowerCase()).toContain('buddy');
  });
});
