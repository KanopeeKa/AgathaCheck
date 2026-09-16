/**
 * @bdd care_suggestion.feature
 * Scenario: A care suggestion surfaces on the pet profile contextual slot
 * Scenario: A care suggestion never appears in the Actions (/pc/events) list
 * Scenario: Accepting a suggestion creates a rhythm and removes the card
 */
import { test, loginAs } from '../fixtures/auth.fixture';
import { CareSuggestionPage } from '../pages/care-suggestion.page';
import { createPet, updatePetProfile } from '../support/api';
import { isLiveHostingTarget } from '../support/hosting';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

function dateOfBirthMonthsAgo(months: number): string {
  const d = new Date();
  d.setUTCMonth(d.getUTCMonth() - months);
  return d.toISOString().slice(0, 10);
}

test.describe('Care suggestion (CIM)', () => {
  test('suggestion card appears on pet profile for an eligible pet', async ({
    page,
    testUser,
  }) => {
    const url = baseURL();
    const pet = await createPet(url, testUser.accessToken, 'CimDog');
    await updatePetProfile(url, testUser.accessToken, pet.id, {
      name: 'CimDog',
      species: 'Dog',
      dateOfBirth: dateOfBirthMonthsAgo(12),
    });

    await loginAs(page, testUser, { experience: 'guardian' });
    const suggestion = new CareSuggestionPage(page);
    await suggestion.openPetDetail(pet.id);
    const timeout = isLiveHostingTarget(url) ? 60_000 : 30_000;
    await suggestion.expectSuggestionCardVisible(timeout);
    await suggestion.expectAcceptAndNotRelevantVisible();
  });

  test('suggestion card does not appear in the Actions (/pc/events) list', async ({
    page,
    testUser,
  }) => {
    const url = baseURL();
    const pet = await createPet(url, testUser.accessToken, 'CimDog2');
    await updatePetProfile(url, testUser.accessToken, pet.id, {
      name: 'CimDog2',
      species: 'Dog',
      dateOfBirth: dateOfBirthMonthsAgo(12),
    });
    await loginAs(page, testUser, { experience: 'guardian' });
    const suggestion = new CareSuggestionPage(page);
    await suggestion.openEvents();
    await suggestion.expectSuggestionNotInEvents();
  });

  test('accepting the suggestion removes the card', async ({ page, testUser }) => {
    const url = baseURL();
    const pet = await createPet(url, testUser.accessToken, 'CimDog3');
    await updatePetProfile(url, testUser.accessToken, pet.id, {
      name: 'CimDog3',
      species: 'Dog',
      dateOfBirth: dateOfBirthMonthsAgo(12),
    });

    await loginAs(page, testUser, { experience: 'guardian' });
    const suggestion = new CareSuggestionPage(page);
    await suggestion.openPetDetail(pet.id);
    const timeout = isLiveHostingTarget(url) ? 60_000 : 30_000;
    await suggestion.expectSuggestionCardVisible(timeout);
    await suggestion.acceptSuggestion();
    await suggestion.expectSuggestionCardNotVisible();
  });
});
