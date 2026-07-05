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
    externalFosterNotice: {
      subject: '{orgName} added you as a foster contact on Agatha Track',
      preheader: 'Your contact details are stored to help coordinate fostering.',
      title: 'Foster contact information',
      intro: '<strong>{orgName}</strong> has added your contact details to Agatha Track to help coordinate pet fostering.',
      why: 'Agatha Track is used by rescues and charities to manage foster placements, reminders, and care records. Your details are visible only to administrators of that organisation.',
      rights: 'You can learn how your data is used and exercise your privacy rights in our <a href="{url}" style="color:#1565C0;">Privacy Notice</a>. To request access, correction, or deletion, contact the organisation or email contact@agathatrack.com.',
      contact: 'If you believe this was added in error, please contact the organisation directly.',
      cta: 'Privacy Notice',
      textIntro: '{orgName} has added your contact details to Agatha Track to help coordinate pet fostering.',
      textWhy: 'Your details are visible only to administrators of that organisation.',
      textRights: 'Privacy information and your rights: {url}',
      textContact: 'Questions? Contact the organisation or contact@agathatrack.com.',
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
    externalFosterNotice: {
      subject: '{orgName} vous a ajouté comme contact d\'accueil sur Agatha Track',
      preheader: 'Vos coordonnées sont conservées pour faciliter l\'accueil.',
      title: 'Coordonnées d\'accueil',
      intro: '<strong>{orgName}</strong> a ajouté vos coordonnées sur Agatha Track pour faciliter l\'accueil d\'animaux.',
      why: 'Agatha Track est utilisé par des refuges et associations pour gérer les placements en famille d\'accueil. Vos coordonnées ne sont visibles que par les administrateurs de cette organisation.',
      rights: 'Consultez notre <a href="{url}" style="color:#1565C0;">Politique de confidentialité</a> pour connaître vos droits. Pour exercer vos droits, contactez l\'organisation ou contact@agathatrack.com.',
      contact: 'Si vous pensez qu\'il s\'agit d\'une erreur, contactez directement l\'organisation.',
      cta: 'Politique de confidentialité',
      textIntro: '{orgName} a ajouté vos coordonnées sur Agatha Track pour faciliter l\'accueil d\'animaux.',
      textWhy: 'Vos coordonnées ne sont visibles que par les administrateurs de cette organisation.',
      textRights: 'Informations et droits : {url}',
      textContact: 'Questions ? Contactez l\'organisation ou contact@agathatrack.com.',
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
