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
import { enableFlutterAccessibility, refreshFlutterAccessibility } from '../support/flutter';
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

  await page.goto(`${baseURL}/o/orgs/${org.id}/pets`);
  await enableFlutterAccessibility(page);
  await refreshFlutterAccessibility(page);
}

async function selectOrgPetsTab(
  page: import('@playwright/test').Page,
  tabLabel: string,
) {
  await page.getByRole('button', { name: tabLabel }).click();
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

    await expect(page.getByText('Max', { exact: true }).first()).toBeVisible();
    await expect(page.getByText('Not in foster').first()).toBeVisible();
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

    await expect(page.getByText('Bella', { exact: true }).first()).toBeVisible();
    await expect(page.getByText('Foster finishing soon').first()).toBeVisible();
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

    await expect(page.getByText('Bella', { exact: true }).first()).toBeVisible();
  });

  test('Name filter narrows pets on the All tab', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, { name: 'Max', species: 'dog' });
    await createOrgPet(baseURL, alice.accessToken, org.id, { name: 'Bella', species: 'dog' });

    await openOrgPetsScreen(page, baseURL, alice, org, ORG_NAME);
    await selectOrgPetsTab(page, 'All');

    await page.getByRole('button', { name: 'Name' }).click();
    await refreshFlutterAccessibility(page);
    await page.getByLabel('Search by pet name').fill('Max');
    await refreshFlutterAccessibility(page);

    await expect(page.getByText('Max', { exact: true }).first()).toBeVisible();
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
    await page.getByRole('button', { name: 'Shadow' }).click();
    await refreshFlutterAccessibility(page);

    await expect(page.getByText('Shadow', { exact: true }).first()).toBeVisible();
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
