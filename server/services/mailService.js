import { mailFrom, mailTransporter } from '../config/mail.js';

export async function sendPasswordResetEmail(to, code) {
  await mailTransporter.sendMail({
    from: mailFrom,
    to,
    subject: 'Your Agatha Track password reset code',
    text: `Your password reset code is ${code}. It expires in 15 minutes.`,
  });
}
