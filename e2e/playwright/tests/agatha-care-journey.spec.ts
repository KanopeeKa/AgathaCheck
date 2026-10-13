/**
 * @bdd agatha_care_journey.feature
 * Scenario: ACJ-FB-01 — chip save clears welfare suggestion
 * Scenario: ACJ-CO-01 — same-day date header
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createPet } from '../support/api';
import { CareAgendaPage } from '../pages/care-agenda.page';
import { GuardianDashboardPage } from '../pages/guardian-dashboard.page';
import { PetDetailPage } from '../pages/pet-detail.page';
import { createCareItem, withCareClock } from '../support/care-api';
import {
  listPendingWelfareSuggestions,
  saveMicrochipOnProfile,
  seedMicrochipWelfarePending,
} from '../pages/agatha-care-journey.seed';
import { enableFlutterAccessibility } from '../support/flutter';

test.describe('Agatha care journey', () => {
  test('@smoke-uat @P1 ACJ-FB-01 — chip save clears welfare suggestion', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'ChipTest', 'Dog');

    await seedMicrochipWelfarePending(
      baseURL,
      testUser.accessToken,
      pet.id,
      'ChipTest',
      'Dog',
    );

    const before = await listPendingWelfareSuggestions(
      baseURL,
      testUser.accessToken,
      pet.id,
    );
    expect(before.some((s) => s.subject_key === 'microchip_welfare')).toBe(true);

    await saveMicrochipOnProfile(
      baseURL,
      testUser.accessToken,
      pet.id,
      'ChipTest',
      'Dog',
      '982000123456789',
    );

    const after = await listPendingWelfareSuggestions(
      baseURL,
      testUser.accessToken,
      pet.id,
    );
    expect(after.some((s) => s.subject_key === 'microchip_welfare')).toBe(false);

    const petList = await loginAs(page, testUser);
    await petList.openPet('ChipTest', pet.id);
    const detail = new PetDetailPage(page);
    await detail.expectLoaded('ChipTest');
    await enableFlutterAccessibility(page);
    await expect(
      page.locator('[flt-semantics-identifier="welfare_suggestion_card_microchip"]'),
    ).toHaveCount(0, { timeout: 15_000 });
  });

  test('@smoke-uat @P1 ACJ-CO-01 — same-day date header', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-10';
    const dueSoonDay = '2026-06-13';
    await withCareClock(`${today}T10:00`, page);
    try {
      const pet = await createPet(baseURL, testUser.accessToken, 'AgendaPet', 'Dog');
      await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Groom A',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: dueSoonDay,
      });
      await createCareItem(baseURL, testUser.accessToken, pet.id, {
        name: 'Groom B',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: dueSoonDay,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.expectRowVisible('Groom A');
      await agenda.expectSameDayDateHeader(dueSoonDay);
    } finally {
      await withCareClock(null, page);
    }
  });

  test('@smoke-ci @smoke-uat ACJ-CO-02 — coordination banner links only', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const today = '2026-06-10';
    const dueSoonDay = '2026-06-13';
    await withCareClock(`${today}T10:00`, page);
    try {
      const petA = await createPet(baseURL, testUser.accessToken, 'Bella', 'Dog');
      const petB = await createPet(baseURL, testUser.accessToken, 'Max', 'Dog');
      await createCareItem(baseURL, testUser.accessToken, petA.id, {
        name: 'Bella groom',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: dueSoonDay,
      });
      await createCareItem(baseURL, testUser.accessToken, petB.id, {
        name: 'Max groom',
        careFamily: 'grooming',
        frequency: 'once',
        dueDate: dueSoonDay,
      });
      await loginAs(page, testUser, { experience: 'guardian' });
      const dashboard = new GuardianDashboardPage(page);
      await dashboard.open();
      const agenda = new CareAgendaPage(page);
      await agenda.expectRowVisible('Bella groom');
      await agenda.expectRowVisible('Max groom');
      await agenda.expectCoordinationLinks([petA.id, petB.id], dueSoonDay);
      await agenda.coordinationPetLink(petB.id).click();
      await page.waitForURL(new RegExp(`/pet/${petB.id}`), { timeout: 30_000 });
    } finally {
      await withCareClock(null, page);
    }
  });
});
