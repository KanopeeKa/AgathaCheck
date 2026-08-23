const MESSAGES = {
  en: {
    passwordReset: {
      subject: 'Your AgathaTrack password reset code',
      preheader: 'Your reset code expires in 15 minutes.',
      title: 'Reset your password',
      intro: 'Use the code below to reset your AgathaTrack password.',
      codeLabel: 'Your reset code',
      expiry: 'This code expires in 15 minutes.',
      security: "If you didn't request a password reset, you can safely ignore this email.",
      cta: 'Open AgathaTrack',
      textIntro: 'Your AgathaTrack password reset code is {code}.',
      textExpiry: 'It expires in 15 minutes.',
      textSecurity: "If you didn't request this, you can ignore this email.",
      textCta: 'Reset your password: {url}',
    },
    externalFosterNotice: {
      subject: '{orgName} added you as a foster contact on AgathaTrack',
      preheader: 'Your contact details are stored to help coordinate fostering.',
      title: 'Foster contact information',
      intro: '<strong>{orgName}</strong> has added your contact details to AgathaTrack to help coordinate pet fostering.',
      why: 'AgathaTrack is used by rescues and charities to manage foster placements, reminders, and care records. Your details are visible only to administrators of that organisation. You may ask the organisation to stop outreach at any time.',
      rights: 'You can learn how your data is used, how long it is kept, and exercise your privacy rights in our <a href="{url}" style="color:#1565C0;">Privacy Notice</a>. To request access, correction, deletion, or to opt out of further outreach, contact the organisation or email contact@agathatrack.com.',
      contact: 'If you believe this was added in error, please contact the organisation directly.',
      cta: 'Privacy Notice',
      textIntro: '{orgName} has added your contact details to AgathaTrack to help coordinate pet fostering.',
      textWhy: 'Your details are visible only to administrators of that organisation. You may ask the organisation to stop outreach at any time.',
      textRights: 'Privacy information, retention, and your rights (including opt-out): {url}',
      textContact: 'Questions? Contact the organisation or contact@agathatrack.com.',
    },
    externalProspectNotice: {
      subject: '{orgName} added you as an adoption prospect on AgathaTrack',
      preheader: 'Your contact details are stored to help coordinate adoption visits.',
      title: 'Adoption prospect information',
      intro: '<strong>{orgName}</strong> has added your contact details to AgathaTrack to help coordinate adoption visits and screening.',
      why: 'AgathaTrack is used by rescues and charities to manage adoption visits and adopter screening. Your details are visible only to administrators of that organisation. You may ask the organisation to stop outreach at any time.',
      rights: 'You can learn how your data is used, how long it is kept, and exercise your privacy rights in our <a href="{url}" style="color:#1565C0;">Privacy Notice</a>. To request access, correction, deletion, or to opt out of further outreach, contact the organisation or email contact@agathatrack.com.',
      contact: 'If you believe this was added in error, please contact the organisation directly.',
      cta: 'Privacy Notice',
      textIntro: '{orgName} has added your contact details to AgathaTrack to help coordinate adoption visits and screening.',
      textWhy: 'Your details are visible only to administrators of that organisation. You may ask the organisation to stop outreach at any time.',
      textRights: 'Privacy information, retention, and your rights (including opt-out): {url}',
      textContact: 'Questions? Contact the organisation or contact@agathatrack.com.',
    },
  },
  fr: {
    passwordReset: {
      subject: 'Votre code de réinitialisation AgathaTrack',
      preheader: 'Votre code expire dans 15 minutes.',
      title: 'Réinitialisez votre mot de passe',
      intro: 'Utilisez le code ci-dessous pour réinitialiser votre mot de passe AgathaTrack.',
      codeLabel: 'Votre code de réinitialisation',
      expiry: 'Ce code expire dans 15 minutes.',
      security:
        "Si vous n'avez pas demandé de réinitialisation, vous pouvez ignorer cet e-mail en toute sécurité.",
      cta: 'Ouvrir AgathaTrack',
      textIntro: 'Votre code de réinitialisation AgathaTrack est {code}.',
      textExpiry: 'Il expire dans 15 minutes.',
      textSecurity: "Si vous n'avez pas demandé ceci, vous pouvez ignorer cet e-mail.",
      textCta: 'Réinitialiser votre mot de passe : {url}',
    },
    externalFosterNotice: {
      subject: '{orgName} vous a ajouté comme contact d\'accueil sur AgathaTrack',
      preheader: 'Vos coordonnées sont conservées pour faciliter l\'accueil.',
      title: 'Coordonnées d\'accueil',
      intro: '<strong>{orgName}</strong> a ajouté vos coordonnées sur AgathaTrack pour faciliter l\'accueil d\'animaux.',
      why: 'AgathaTrack est utilisé par des refuges et associations pour gérer les placements en famille d\'accueil. Vos coordonnées ne sont visibles que par les administrateurs de cette organisation. Vous pouvez demander à l\'organisation de cesser tout contact.',
      rights: 'Consultez notre <a href="{url}" style="color:#1565C0;">Politique de confidentialité</a> pour connaître la durée de conservation et vos droits. Pour exercer vos droits ou refuser tout contact ultérieur, contactez l\'organisation ou contact@agathatrack.com.',
      contact: 'Si vous pensez qu\'il s\'agit d\'une erreur, contactez directement l\'organisation.',
      cta: 'Politique de confidentialité',
      textIntro: '{orgName} a ajouté vos coordonnées sur AgathaTrack pour faciliter l\'accueil d\'animaux.',
      textWhy: 'Vos coordonnées ne sont visibles que par les administrateurs de cette organisation. Vous pouvez demander à l\'organisation de cesser tout contact.',
      textRights: 'Informations, conservation et droits (y compris opposition) : {url}',
      textContact: 'Questions ? Contactez l\'organisation ou contact@agathatrack.com.',
    },
    externalProspectNotice: {
      subject: '{orgName} vous a ajouté comme prospect d\'adoption sur AgathaTrack',
      preheader: 'Vos coordonnées sont conservées pour faciliter les visites d\'adoption.',
      title: 'Coordonnées prospect d\'adoption',
      intro: '<strong>{orgName}</strong> a ajouté vos coordonnées sur AgathaTrack pour faciliter les visites d\'adoption et le screening.',
      why: 'AgathaTrack est utilisé par des refuges et associations pour gérer les visites d\'adoption. Vos coordonnées ne sont visibles que par les administrateurs de cette organisation. Vous pouvez demander à l\'organisation de cesser tout contact.',
      rights: 'Consultez notre <a href="{url}" style="color:#1565C0;">Politique de confidentialité</a> pour connaître la durée de conservation et vos droits. Pour exercer vos droits ou refuser tout contact ultérieur, contactez l\'organisation ou contact@agathatrack.com.',
      contact: 'Si vous pensez qu\'il s\'agit d\'une erreur, contactez directement l\'organisation.',
      cta: 'Politique de confidentialité',
      textIntro: '{orgName} a ajouté vos coordonnées sur AgathaTrack pour faciliter les visites d\'adoption et le screening.',
      textWhy: 'Vos coordonnées ne sont visibles que par les administrateurs de cette organisation. Vous pouvez demander à l\'organisation de cesser tout contact.',
      textRights: 'Informations, conservation et droits (y compris opposition) : {url}',
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
