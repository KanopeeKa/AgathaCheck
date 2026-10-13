/**
 * @bdd agatha_care_journey.feature
 * Scenario: ACJ-FB-01 — chip save clears welfare suggestion
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createPet } from '../support/api';
import { PetDetailPage } from '../pages/pet-detail.page';
import {
  listPendingWelfareSuggestions,
  updatePetFields,
} from '../pages/pet-profile.seed';
import { enableFlutterAccessibility } from '../support/flutter';

test.describe('Agatha care journey', () => {
  test('@smoke-uat @P1 ACJ-FB-01 — chip save clears welfare suggestion', async ({
    page,
    testUser,
  }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const pet = await createPet(baseURL, testUser.accessToken, 'ChipTest', 'Dog');

    await updatePetFields(baseURL, testUser.accessToken, pet.id, {
      name: 'ChipTest',
      species: 'Dog',
      identificationStatus: 'no',
      chipId: '',
    });

    const before = await listPendingWelfareSuggestions(
      baseURL,
      testUser.accessToken,
      pet.id,
    );
    expect(before.some((s) => s.subject_key === 'microchip_welfare')).toBe(true);

    await updatePetFields(baseURL, testUser.accessToken, pet.id, {
      name: 'ChipTest',
      species: 'Dog',
      identificationStatus: 'yes',
      chipId: '982000123456789',
    });

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
});
