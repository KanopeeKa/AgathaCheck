import type { Page } from '@playwright/test';
import { InviteRecipientPage } from './invite-recipient.page';

/** Household member invite landing (`/#/household-invite/:code`). */
export class HouseholdInviteLandingPage extends InviteRecipientPage {
  constructor(page: Page) {
    super(page);
  }

  async goto(code: string): Promise<void> {
    await super.gotoHashRoute(`/household-invite/${code}`);
  }
}
