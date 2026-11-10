/**
 * @bdd invite_recipient_return.feature
 * Scenario: Share link recipient signs in and returns to the same share code
 * Scenario: Email share invite recipient signs in and returns to the same invite code
 * Scenario: Away-plan carer invite recipient signs in and returns to the same invite code
 * Scenario: Household invite recipient signs in and returns to the same invite code
 */
import { test } from '../fixtures/auth.fixture';
import { LandingPage } from '../pages/landing.page';
import { InviteRecipientPage } from '../pages/invite-recipient.page';
import { SharedPetPage } from '../pages/shared-pet.page';
import { InviteLandingPage } from '../pages/invite-landing.page';
import { AbsenceInviteLandingPage } from '../pages/absence-invite-landing.page';
import { HouseholdInviteLandingPage } from '../pages/household-invite-landing.page';
import {
  seedAbsenceCarerInvite,
  seedEmailShareInvite,
  seedHouseholdInvite,
  seedShareLink,
} from '../pages/invite-recipient.helpers';
import { clearBrowserSessionState } from '../support/session';
import {
  completeExperienceChooserIfPresent,
  completeGuardianOnboarding,
  dismissConsentBannerIfPresent,
  flutterRoutePath,
  refreshFlutterAccessibility,
  waitForFlutterRoutePattern,
} from '../support/flutter';
import { clearLiveApiAccess, prepareLiveApiAccess } from '../support/waf';

const baseURL = () => process.env.E2E_BASE_URL ?? 'http://localhost:3000';

async function signInAndReturnToInvite(
  page: import('@playwright/test').Page,
  email: string,
  password: string,
  routePattern: RegExp,
): Promise<void> {
  const landing = new LandingPage(page);
  await landing.openSignInTab();
  await landing.login(email, password);
  await dismissConsentBannerIfPresent(page);
  await refreshFlutterAccessibility(page);
  await waitForFlutterRoutePattern(
    page,
    /\/(app\/resolve|pc\/onboarding|shared|invite|absence-invite|household-invite)/,
    90_000,
  );
  const path = flutterRoutePath(page.url());
  if (path === '/pc/onboarding') {
    await completeExperienceChooserIfPresent(page, 'guardian');
    await completeGuardianOnboarding(page, 'E2EPet');
  } else if (path === '/app/resolve') {
    await waitForFlutterRoutePattern(page, routePattern, 90_000);
  }
  const recipient = new InviteRecipientPage(page);
  await recipient.expectReturnedToInvite(routePattern);
}

test.describe.configure({ mode: 'serial' });

test.describe('Invite recipient return-to-invite @sharing @people @petCare', () => {
  test('@P1 share link: signed-out preview, auth, return, explicit accept', async ({ page }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    await prepareLiveApiAccess(page, root);
    try {
      const { shareCode, owner } = await seedShareLink(root);
      const recipientEmail = `share-return-${Date.now()}@example.com`;
      const recipientPassword = 'E2eTestPass1';
      const { signupUser, createPet } = await import('../support/api');
      const recipient = await signupUser(root, {
        email: recipientEmail,
        password: recipientPassword,
        firstName: 'Bob',
        lastName: 'Viewer',
      });
      await createPet(root, recipient.accessToken, 'Rex', 'Dog');

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, root);

      const shared = new SharedPetPage(page);
      await shared.goto(shareCode);
      const recipientPage = new InviteRecipientPage(page);
      await recipientPage.expectSignedOutRecipientPreview({ inviterName: owner.firstName });
      await recipientPage.continueToLandingWithReturnTo();
      await signInAndReturnToInvite(
        page,
        recipientEmail,
        recipientPassword,
        new RegExp(`/shared/${shareCode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`),
      );
      await recipientPage.expectExplicitAcceptVisible();
    } finally {
      clearLiveApiAccess();
    }
  });

  test('@P1 email share invite: signed-out preview, auth, return, accept and decline', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    await prepareLiveApiAccess(page, root);
    try {
      const { inviteCode, recipient, owner } = await seedEmailShareInvite(root);

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, root);

      const inviteLanding = new InviteLandingPage(page);
      await inviteLanding.goto(inviteCode);
      const recipientUi = new InviteRecipientPage(page);
      await recipientUi.expectSignedOutRecipientPreview({ inviterName: owner.firstName });
      await recipientUi.continueToLandingWithReturnTo();
      await signInAndReturnToInvite(
        page,
        recipient.email,
        recipient.password,
        new RegExp(`/invite/${inviteCode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`),
      );
      await recipientUi.expectExplicitAcceptVisible();
      await recipientUi.expectDeclineVisible();
    } finally {
      clearLiveApiAccess();
    }
  });

  test('@P1 away-plan carer invite: signed-out preview, auth, return, explicit accept', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    await prepareLiveApiAccess(page, root);
    try {
      const { inviteCode, recipient, owner } = await seedAbsenceCarerInvite(root);

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, root);

      const absenceInvite = new AbsenceInviteLandingPage(page);
      await absenceInvite.goto(inviteCode);
      const recipientUi = new InviteRecipientPage(page);
      await recipientUi.expectSignedOutRecipientPreview({ inviterName: owner.firstName });
      await recipientUi.continueToLandingWithReturnTo();
      await signInAndReturnToInvite(
        page,
        recipient.email,
        recipient.password,
        new RegExp(
          `/absence-invite/${inviteCode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`,
        ),
      );
      await recipientUi.expectExplicitAcceptVisible();
    } finally {
      clearLiveApiAccess();
    }
  });

  test('@P1 household invite: signed-out preview, auth, return, accept and decline', async ({
    page,
  }) => {
    test.setTimeout(120_000);
    const root = baseURL();
    await prepareLiveApiAccess(page, root);
    try {
      const { inviteCode, recipient, owner } = await seedHouseholdInvite(root);

      await clearBrowserSessionState(page);
      await prepareLiveApiAccess(page, root);

      const householdInvite = new HouseholdInviteLandingPage(page);
      await householdInvite.goto(inviteCode);
      const recipientUi = new InviteRecipientPage(page);
      await recipientUi.expectSignedOutRecipientPreview({ inviterName: owner.firstName });
      await recipientUi.continueToLandingWithReturnTo();
      await signInAndReturnToInvite(
        page,
        recipient.email,
        recipient.password,
        new RegExp(
          `/household-invite/${inviteCode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`,
        ),
      );
      await recipientUi.expectExplicitAcceptVisible();
      await recipientUi.expectDeclineVisible();
    } finally {
      clearLiveApiAccess();
    }
  });
});
