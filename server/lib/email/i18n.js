const MESSAGES = {
  en: {
    passwordReset: {
      subject: 'Your Agatha Track password reset code',
      preheader: 'Your reset code expires in 15 minutes.',
      title: 'Reset your password',
      intro: 'Use the code below to reset your Agatha Track password.',
      codeLabel: 'Your reset code',
      expiry: 'This code expires in 15 minutes.',
      security: "If you didn't request a password reset, you can safely ignore this email.",
      cta: 'Open Agatha Track',
      textIntro: 'Your Agatha Track password reset code is {code}.',
      textExpiry: 'It expires in 15 minutes.',
      textSecurity: "If you didn't request this, you can ignore this email.",
      textCta: 'Reset your password: {url}',
    },
  },
  fr: {
    passwordReset: {
      subject: 'Votre code de réinitialisation Agatha Track',
      preheader: 'Votre code expire dans 15 minutes.',
      title: 'Réinitialisez votre mot de passe',
      intro: 'Utilisez le code ci-dessous pour réinitialiser votre mot de passe Agatha Track.',
      codeLabel: 'Votre code de réinitialisation',
      expiry: 'Ce code expire dans 15 minutes.',
      security:
        "Si vous n'avez pas demandé de réinitialisation, vous pouvez ignorer cet e-mail en toute sécurité.",
      cta: 'Ouvrir Agatha Track',
      textIntro: 'Votre code de réinitialisation Agatha Track est {code}.',
      textExpiry: 'Il expire dans 15 minutes.',
      textSecurity: "Si vous n'avez pas demandé ceci, vous pouvez ignorer cet e-mail.",
      textCta: 'Réinitialiser votre mot de passe : {url}',
    },
  },
};

/** Return localized strings for a template namespace. */
export function getEmailStrings(locale, namespace) {
  const lang = MESSAGES[locale] ? locale : 'en';
  return MESSAGES[lang][namespace];
}

/** Replace `{key}` placeholders in a template string. */
export function formatEmailString(template, values = {}) {
  return template.replace(/\{(\w+)\}/g, (_, key) => values[key] ?? '');
}
