import type { Page } from '@playwright/test';
import { InviteRecipientPage } from './invite-recipient.page';

/** Away-plan carer invite landing (`/#/absence-invite/:code`). */
export class AbsenceInviteLandingPage extends InviteRecipientPage {
  constructor(page: Page) {
    super(page);
  }

  async goto(code: string): Promise<void> {
    await super.gotoHashRoute(`/absence-invite/${code}`);
  }
}
