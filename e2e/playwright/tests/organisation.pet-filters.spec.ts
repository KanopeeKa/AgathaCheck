/**
 * @bdd pet_screen_filters.feature
 * Scenario: A pet with no foster placement needs attention
 * Scenario: A pet with a foster placement ending soon needs attention
 * Scenario: In foster tab shows pets currently in foster care
 * Scenario: Name filter narrows pets on the All tab
 * Scenario: Shadow filter shows adopted shadow pets on the All tab
 * Scenario: Need attention info icon explains care criteria
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import {
  confirmAdoption,
  createFosterPlacement,
  createOrgPet,
  acceptFosterPlacement,
  initiateDirectAdoption,
  seedHappyPawsClinic,
  seedRescueHearts,
} from '../support/api';
import { enableFlutterAccessibility, refreshFlutterAccessibility, waitForFlutterRoutePattern, escapeRegExp, semanticsByName } from '../support/flutter';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';

const ORG_NAME = 'Happy Paws Clinic';

function isoDay(offsetDays: number): string {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

async function openOrgPetsScreen(
  page: import('@playwright/test').Page,
  baseURL: string,
  alice: { accessToken: string },
  org: { id: string },
  orgName: string,
) {
  await loginAs(page, alice, { experience: 'organization' });
  const orgList = new OrganizationListPage(page);
  await orgList.openOrganizations();
  await orgList.openOrg(orgName, org.id);

  const detail = new OrganizationDetailPage(page);
  await detail.expectLoaded(orgName);
  await detail.openPetsSection();
  await waitForFlutterRoutePattern(page, /\/o\/orgs\/[^/]+\/pets/, 30_000);
  await enableFlutterAccessibility(page);
  await refreshFlutterAccessibility(page);
}

async function expectOrgPetVisible(page: import('@playwright/test').Page, petName: string) {
  const petPattern = new RegExp(`Pet:\\s*${escapeRegExp(petName)}`, 'i');
  const shadowPattern = new RegExp(`${escapeRegExp(petName)}.*frozen shadow`, 'i');
  await expect(
    semanticsByName(page, petPattern)
      .or(page.getByRole('button', { name: shadowPattern }))
      .first(),
  ).toBeVisible();
}

async function expectAttentionReasonVisible(
  page: import('@playwright/test').Page,
  reason: string,
) {
  await expect(
    page
      .getByRole('group', { name: new RegExp(escapeRegExp(reason), 'i') })
      .or(page.getByText(reason, { exact: true }))
      .first(),
  ).toBeVisible();
}

const ORG_PETS_TAB_KEYS: Record<string, string> = {
  'Need attention': 'org_pets_tab_needAttention',
  'In foster': 'org_pets_tab_inFoster',
  Adopted: 'org_pets_tab_adopted',
  All: 'org_pets_tab_all',
};

async function selectOrgPetsTab(
  page: import('@playwright/test').Page,
  tabLabel: string,
) {
  const tabKey = ORG_PETS_TAB_KEYS[tabLabel];
  if (tabKey) {
    const chip = page.locator(`[flt-semantics-identifier="${tabKey}"]`);
    if (await chip.count()) {
      await chip.click();
      await refreshFlutterAccessibility(page);
      return;
    }
  }
  const tab = page
    .getByRole('button', { name: tabLabel })
    .or(page.getByRole('checkbox', { name: tabLabel }));
  await tab.first().click();
  await refreshFlutterAccessibility(page);
}

test.describe('Organisation pet filters', () => {
  test('Need attention tab shows pet with no foster placement', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });

    await openOrgPetsScreen(page, baseURL, alice, org, ORG_NAME);
    await selectOrgPetsTab(page, 'Need attention');

    await expectOrgPetVisible(page, 'Max');
    await expectAttentionReasonVisible(page, 'Not in foster');
  });

  test('Need attention tab shows foster finishing soon message', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Bella',
      species: 'dog',
    });
    const placement = await createFosterPlacement(
      baseURL,
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
      { startDate: isoDay(-20), endDate: isoDay(5) },
    );
    await acceptFosterPlacement(baseURL, eve.accessToken, placement.id);

    await openOrgPetsScreen(page, baseURL, alice, org, 'Rescue Hearts');
    await selectOrgPetsTab(page, 'Need attention');

    await expectOrgPetVisible(page, 'Bella');
    await expectAttentionReasonVisible(page, 'Foster finishing soon');
  });

  test('In foster tab lists pets currently in foster care', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Bella',
      species: 'dog',
    });
    const placement = await createFosterPlacement(
      baseURL,
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );
    await acceptFosterPlacement(baseURL, eve.accessToken, placement.id);

    await openOrgPetsScreen(page, baseURL, alice, org, 'Rescue Hearts');
    await selectOrgPetsTab(page, 'In foster');

    await expectOrgPetVisible(page, 'Bella');
  });

  test('Name filter narrows pets on the All tab', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, { name: 'Max', species: 'dog' });
    await createOrgPet(baseURL, alice.accessToken, org.id, { name: 'Bella', species: 'dog' });

    await openOrgPetsScreen(page, baseURL, alice, org, ORG_NAME);
    await selectOrgPetsTab(page, 'All');

    await page.getByRole('checkbox', { name: 'Name' }).click();
    await refreshFlutterAccessibility(page);
    await page.getByLabel('Search by pet name').fill('Max');
    await refreshFlutterAccessibility(page);

    await expectOrgPetVisible(page, 'Max');
    await expect(page.getByText('Bella', { exact: true })).toHaveCount(0);
  });

  test('Shadow filter shows adopted shadow pets on the All tab', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, eve, org } = await seedRescueHearts(baseURL);
    const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Shadow',
      species: 'dog',
    });
    const placement = await initiateDirectAdoption(
      baseURL,
      alice.accessToken,
      org.id,
      pet.id,
      eve.userId,
    );
    await confirmAdoption(baseURL, eve.accessToken, placement.id);

    await openOrgPetsScreen(page, baseURL, alice, org, 'Rescue Hearts');
    await selectOrgPetsTab(page, 'All');
    await page.getByRole('checkbox', { name: 'Shadow' }).click();
    await refreshFlutterAccessibility(page);

    await expectOrgPetVisible(page, 'Shadow');
  });

  test('Need attention info icon is visible with guidance', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });

    await openOrgPetsScreen(page, baseURL, alice, org, ORG_NAME);
    await selectOrgPetsTab(page, 'Need attention');

    await expect(page.locator('[flt-semantics-identifier="org_pets_need_attention_tooltip"]')).toBeVisible();
  });
});
