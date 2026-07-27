/**
 * @bdd pet_screen_filters.feature
 * Scenario: A pet with no foster placement needs attention
 * Scenario: A pet with a foster placement ending soon needs attention
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { createOrgPet, seedHappyPawsClinic } from '../support/api';
import { enableFlutterAccessibility, refreshFlutterAccessibility } from '../support/flutter';
import { OrganizationDetailPage } from '../pages/organization-detail.page';
import { OrganizationListPage } from '../pages/organization-list.page';

const ORG_NAME = 'Happy Paws Clinic';

test.describe('Organisation pet filters', () => {
  test('Need attention tab shows pet with no foster placement', async ({ page }) => {
    const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:3000';
    const { alice, org } = await seedHappyPawsClinic(baseURL);
    await createOrgPet(baseURL, alice.accessToken, org.id, {
      name: 'Max',
      species: 'dog',
    });

    const petList = await loginAs(page, alice, { experience: 'organization' });
    await petList.openOrganizations();

    const orgList = new OrganizationListPage(page);
    await orgList.openOrg(ORG_NAME, org.id);

    const detail = new OrganizationDetailPage(page);
    await detail.expectLoaded(ORG_NAME);

    await page.goto(`${baseURL}/o/orgs/${org.id}/pets`);
    await enableFlutterAccessibility(page);
    await refreshFlutterAccessibility(page);

    const needAttentionTab = page.getByRole('button', { name: 'Need attention' });
    await needAttentionTab.click();
    await refreshFlutterAccessibility(page);

    await expect(page.getByText('Max', { exact: true }).first()).toBeVisible();
    await expect(page.getByText('Not in foster').first()).toBeVisible();
  });
});
