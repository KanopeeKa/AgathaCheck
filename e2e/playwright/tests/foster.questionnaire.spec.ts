/**
 * @bdd foster_onboarding.feature
 * Scenario: Candidate submits foster questionnaire with AUTO_GO path
 */
import { test, expect, loginAs } from '../fixtures/auth.fixture';
import { FosterQuestionnairePage } from '../pages/foster-questionnaire.page';
import { seedRescueHearts } from '../support/api';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function expectOnboardingFormStepComplete(
  page: import('@playwright/test').Page,
  aliceToken: string,
  orgId: string,
  eveUserId: string,
): Promise<void> {
  const base = baseURL().replace(/\/$/, '');
  const membersRes = await page.request.get(
    `${base}/backend/api/organizations/${orgId}/members`,
    { headers: { Authorization: `Bearer ${aliceToken}` } },
  );
  expect(membersRes.ok()).toBeTruthy();
  const members: Array<{ id: string; user_id: string }> = await membersRes.json();
  const eveMember = members.find((member) => member.user_id === eveUserId);
  expect(eveMember).toBeTruthy();

  const detailRes = await page.request.get(
    `${base}/backend/api/organizations/${orgId}/people/member/${eveMember!.id}`,
    { headers: { Authorization: `Bearer ${aliceToken}` } },
  );
  expect(detailRes.ok()).toBeTruthy();
  const detail: {
    foster_onboarding?: { steps?: Array<{ key: string; state: string }> };
  } = await detailRes.json();
  const onboardingForm = detail.foster_onboarding?.steps?.find(
    (step) => step.key === 'onboarding_form',
  );
  expect(onboardingForm?.state).toBe('complete');
}

test.describe('Foster candidate questionnaire', () => {
  test('candidate submits foster questionnaire with AUTO_GO path', async ({ page }) => {
    const { alice, eve, org } = await seedRescueHearts(baseURL());

    const submitResponse = page.waitForResponse(
      (response) =>
        response.request().method() === 'POST'
        && response.url().includes(`/organizations/${org.id}/foster-questionnaire/submit`)
        && response.status() === 201,
    );

    await loginAs(page, eve, { experience: 'organization' });

    const questionnaire = new FosterQuestionnairePage(page);
    await questionnaire.goto(org.id);
    await questionnaire.completeMatchingProfile();
    await questionnaire.answerAllScreeningWithGo();
    await questionnaire.acknowledgeAndSubmit();

    const response = await submitResponse;
    const body = await response.json();
    expect(body.submission?.result).toBe('AUTO_GO');

    await questionnaire.expectAutoGoConfirmation();
    await expectOnboardingFormStepComplete(page, alice.accessToken, org.id, eve.userId);
  });
});
