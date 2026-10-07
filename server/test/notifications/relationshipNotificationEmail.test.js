import { emailShareAccessChanged } from '../../lib/notifications/relationshipNotificationEmail.js';
import { sendTransactionalEmail } from '../../services/mailService.js';

jest.mock('../../config/mail.js', () => ({
  isSmtpConfigured: () => true,
}));

jest.mock('../../services/mailService.js', () => ({
  sendTransactionalEmail: jest.fn(async () => {}),
}));

describe('relationshipNotificationEmail', () => {
  it('escapes HTML in compulsory share access email body', async () => {
    await emailShareAccessChanged('user@example.com', {
      actorName: '<b>Evil</b>',
      petName: 'Rex<img>',
      roleLabel: 'carer',
    });
    const call = sendTransactionalEmail.mock.calls[0][0];
    expect(call.html).not.toContain('<b>Evil</b>');
    expect(call.html).toContain('&lt;b&gt;Evil&lt;/b&gt;');
    expect(call.html).toContain('Rex&lt;img&gt;');
  });
});
