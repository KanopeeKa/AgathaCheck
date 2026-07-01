const SUPPORTED = new Set(['en', 'fr']);

/** Normalize a locale string to a supported email language (`en` or `fr`). */
export function normalizeLocale(locale) {
  const code = String(locale || 'en')
    .trim()
    .toLowerCase()
    .split(/[-_]/)[0];
  return SUPPORTED.has(code) ? code : 'en';
}

/** Pick the best supported locale from an HTTP Accept-Language header. */
export function parseAcceptLanguage(header) {
  if (!header) return 'en';

  for (const part of String(header).split(',')) {
    const lang = part.trim().split(';')[0].toLowerCase();
    const code = lang.split(/[-_]/)[0];
    if (SUPPORTED.has(code)) return code;
  }

  return 'en';
}

/**
 * Resolve the email locale: user profile preference first, then
 * Accept-Language, then English.
 */
export function resolveEmailLocale(userLocale, acceptLanguage) {
  if (userLocale) return normalizeLocale(userLocale);
  return parseAcceptLanguage(acceptLanguage);
}
