import { escapeHtml } from '../email/escapeHtml.js';
import { isSmtpConfigured } from '../../config/mail.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import { maskEmailForNotice } from '../account/maskEmail.js';

async function sendRelationshipCompulsoryEmail(email, { subject, text, html }) {
  if (!email || !isSmtpConfigured()) return { sent: false, reason: 'smtp_unconfigured' };
  try {
    await sendTransactionalEmail({ to: email, subject, text, html });
    return { sent: true };
  } catch (err) {
    console.error('relationship compulsory email failed', err);
    return { sent: false, reason: 'send_failed' };
  }
}

export async function emailShareAccessChanged(email, { actorName, petName, roleLabel }) {
  const subject = 'Your access to a pet was updated';
  const message = `${actorName} changed your access to ${petName} to ${roleLabel}.`;
  const masked = maskEmailForNotice(email);
  const text = `${message}\n\nAccount: ${masked}\n\nOpen AgathaTrack to review your access.`;
  const html = `<p>${escapeHtml(message)}</p><p>Account: ${escapeHtml(masked)}</p>`;
  return sendRelationshipCompulsoryEmail(email, { subject, text, html });
}

export async function emailShareAccessRemoved(email, { actorName, petName }) {
  const subject = 'Pet sharing ended';
  const message = `${actorName} stopped sharing ${petName} with you.`;
  const masked = maskEmailForNotice(email);
  const text = `${message}\n\nAccount: ${masked}`;
  const html = `<p>${escapeHtml(message)}</p><p>Account: ${escapeHtml(masked)}</p>`;
  return sendRelationshipCompulsoryEmail(email, { subject, text, html });
}

export async function emailOwnershipTransferCompleted(email, { petName }) {
  const subject = 'Pet ownership transferred';
  const message = `You are now the owner of ${petName}.`;
  const masked = maskEmailForNotice(email);
  const text = `${message}\n\nAccount: ${masked}`;
  const html = `<p>${escapeHtml(message)}</p><p>Account: ${escapeHtml(masked)}</p>`;
  return sendRelationshipCompulsoryEmail(email, { subject, text, html });
}
