/**
 * @bdd foster_onboarding.feature
 * Scenario: Admin schedules and validates home visit yes
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { FosterHomeVisitAdminPage } from '../pages/foster-home-visit-admin.page';
import { FosterHomeVisitStatusPage } from '../pages/foster-home-visit-status.page';
import { seedRescueHearts } from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function resolveFosterParentId(
  page: import('@playwright/test').Page,
  adminToken: string,
  orgId: string,
  fosterUserId: string,
): Promise<string> {
  const base = baseURL().replace(/\/$/, '');
  const membersRes = await page.request.get(
    `${base}/backend/api/organizations/${orgId}/members`,
    { headers: { Authorization: `Bearer ${adminToken}` } },
  );
  expect(membersRes.ok()).toBeTruthy();
  const members: Array<{ id: string; user_id: string }> = await membersRes.json();
  const fosterMember = members.find((member) => member.user_id === fosterUserId);
  expect(fosterMember).toBeTruthy();

  const detailRes = await page.request.get(
    `${base}/backend/api/organizations/${orgId}/people/member/${fosterMember!.id}`,
    { headers: { Authorization: `Bearer ${adminToken}` } },
  );
  expect(detailRes.ok()).toBeTruthy();
  const detail: {
    foster_onboarding?: { resource_id?: string; steps?: Array<{ key: string; state: string }> };
  } = await detailRes.json();
  expect(detail.foster_onboarding?.resource_id).toBeTruthy();
  return detail.foster_onboarding!.resource_id!;
}

async function expectHomeVisitStepComplete(
  page: import('@playwright/test').Page,
  adminToken: string,
  orgId: string,
  fosterUserId: string,
): Promise<void> {
  const base = baseURL().replace(/\/$/, '');
  const membersRes = await page.request.get(
    `${base}/backend/api/organizations/${orgId}/members`,
    { headers: { Authorization: `Bearer ${adminToken}` } },
  );
  expect(membersRes.ok()).toBeTruthy();
  const members: Array<{ id: string; user_id: string }> = await membersRes.json();
  const fosterMember = members.find((member) => member.user_id === fosterUserId);
  expect(fosterMember).toBeTruthy();

  const detailRes = await page.request.get(
    `${base}/backend/api/organizations/${orgId}/people/member/${fosterMember!.id}`,
    { headers: { Authorization: `Bearer ${adminToken}` } },
  );
  expect(detailRes.ok()).toBeTruthy();
  const detail: {
    foster_onboarding?: { steps?: Array<{ key: string; state: string }> };
  } = await detailRes.json();
  const homeVisitStep = detail.foster_onboarding?.steps?.find(
    (step) => step.key === 'home_visit',
  );
  expect(homeVisitStep?.state).toBe('complete');
}

test.describe('Foster home visit', () => {
  test('admin schedules and validates home visit yes', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL());
    const fosterParentId = await resolveFosterParentId(
      page,
      alice.accessToken,
      org.id,
      eve.userId,
    );

    await loginAs(page, alice, { experience: 'organization' });

    const adminVisit = new FosterHomeVisitAdminPage(page);
    await adminVisit.goto(org.id, fosterParentId);
    await adminVisit.scheduleVisit({ address: '42 Foster Lane, Test Town' });
    await adminVisit.validateYes();

    await expectHomeVisitStepComplete(page, alice.accessToken, org.id, eve.userId);

    await loginAs(page, eve, { experience: 'organization' });
    const candidateStatus = new FosterHomeVisitStatusPage(page);
    await candidateStatus.goto(org.id, fosterParentId);
    await candidateStatus.expectValidatedYes();
  });
});
