/**
 * Household lifecycle E2E (execute-plan household-cleanup-609f phase 7).
 * Playwright coverage for leave-with-pets, last-member close, tier change, owner unshare.
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { PeoplePage } from '../pages/people.page';
import {
  acceptHouseholdInviteByCode,
  createHealthEntry,
  createHousehold,
  createHouseholdInvite,
  createPet,
  createVetFull,
  getHealthEntry,
  getHouseholdDetail,
  getPeopleContactIdForVetName,
  listHouseholds,
  patchHouseholdMember,
  removeHouseholdMember,
  setHouseholdPets,
  setPetPeopleSlot,
  signupUser,
} from '../support/api';
import { flutterGotoUrl, refreshFlutterAccessibility } from '../support/flutter';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

test.describe('Household lifecycle journeys @people', () => {
  test('@P1 A household member leaves and their own pet is no longer listed in the household', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const owner = await signupUser(root);
    const member = await signupUser(root, {
      email: `hh-leaver-${Date.now()}@example.com`,
      firstName: 'Pat',
      lastName: 'Leaver',
    });
    const ownerPet = await createPet(root, owner.accessToken, 'OwnerDog');
    const household = await createHousehold(root, owner.accessToken, 'Shared Home', [
      ownerPet.id,
    ]);
    const invite = await createHouseholdInvite(
      root,
      owner.accessToken,
      household.id,
      member.email,
      { accessTier: 'can_log_care' },
    );
    await acceptHouseholdInviteByCode(root, member.accessToken, invite.code);
    const memberPet = await createPet(root, member.accessToken, 'LeaverDog');
    await setHouseholdPets(root, member.accessToken, household.id, [memberPet.id]);

    await loginAs(page, member);
    const people = new PeoplePage(page);
    await people.openHouseholdDetail(household.id);
    await removeHouseholdMember(root, member.accessToken, household.id, member.userId);

    await expect(async () => {
      const detail = await getHouseholdDetail(root, owner.accessToken, household.id);
      expect(detail.members.some((m) => m.user_id === member.userId)).toBe(false);
      const petIds = (detail.pets ?? []).map((p) => p.pet_id);
      expect(petIds).toContain(ownerPet.id);
      expect(petIds).not.toContain(memberPet.id);
    }).toPass({ timeout: 30_000 });
  });

  test('@P1 The last member leaves, the household closes, and the pet keeps its vet and care provider', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const user = await signupUser(root);
    const pet = await createPet(root, user.accessToken, 'SoloPet', 'Dog');
    await createVetFull(root, user.accessToken, { name: 'Household Vet' });
    const vetContactId = await getPeopleContactIdForVetName(
      root,
      user.accessToken,
      'Household Vet',
    );
    await setPetPeopleSlot(root, user.accessToken, pet.id, 'primary_vet', vetContactId);
    const entry = await createHealthEntry(root, user.accessToken, pet.id, {
      name: 'Monthly tablet',
      nextDueDate: dateOffset(30),
      providerContactId: vetContactId,
    });
    const household = await createHousehold(root, user.accessToken, 'Solo Home', [pet.id]);

    await loginAs(page, user);
    const people = new PeoplePage(page);
    await people.openHouseholdDetail(household.id);
    await removeHouseholdMember(root, user.accessToken, household.id, user.userId);

    await expect(async () => {
      const { households } = await listHouseholds(root, user.accessToken);
      expect(households.some((h) => h.id === household.id)).toBe(false);
    }).toPass({ timeout: 30_000 });

    const loaded = await getHealthEntry(root, user.accessToken, entry.id);
    expect(loaded.provider_contact_id).toBe(vetContactId);
    await expect(async () => {
      const id = await getPeopleContactIdForVetName(root, user.accessToken, 'Household Vet');
      expect(id).toBe(vetContactId);
    }).toPass({ timeout: 15_000 });
  });

  test('@P1 An organiser changes a member from Full access to Can log care', async ({ page }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const owner = await signupUser(root);
    const member = await signupUser(root, {
      email: `hh-tier-${Date.now()}@example.com`,
      firstName: 'Tier',
      lastName: 'Member',
    });
    const pet = await createPet(root, owner.accessToken, 'TierPet');
    const household = await createHousehold(root, owner.accessToken, 'Tier Home', [pet.id]);
    const invite = await createHouseholdInvite(
      root,
      owner.accessToken,
      household.id,
      member.email,
      { accessTier: 'full_access' },
    );
    await acceptHouseholdInviteByCode(root, member.accessToken, invite.code);

    await loginAs(page, owner);
    const people = new PeoplePage(page);
    await people.openHouseholdDetail(household.id);
    await patchHouseholdMember(root, owner.accessToken, household.id, member.userId, {
      access_tier: 'can_log_care',
    });

    await expect(async () => {
      const detail = await getHouseholdDetail(root, owner.accessToken, household.id);
      const row = detail.members.find((m) => m.user_id === member.userId);
      expect(row?.access_tier).toBe('can_log_care');
    }).toPass({ timeout: 30_000 });
  });

  test('@P1 The record owner removes their pet from the household on the household detail page', async ({ page }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    const owner = await signupUser(root);
    const pet = await createPet(root, owner.accessToken, 'SharedOut');
    const household = await createHousehold(root, owner.accessToken, 'Unshare Home', [pet.id]);

    await loginAs(page, owner);
    await page.goto(flutterGotoUrl(`/pc/people/households/${household.id}`));
    await refreshFlutterAccessibility(page);
    const people = new PeoplePage(page);
    await people.setHouseholdPetShared('SharedOut', false);

    await expect(async () => {
      const detail = await getHouseholdDetail(root, owner.accessToken, household.id);
      expect((detail.pets ?? []).map((p) => p.pet_id)).not.toContain(pet.id);
    }).toPass({ timeout: 30_000 });
  });
});
