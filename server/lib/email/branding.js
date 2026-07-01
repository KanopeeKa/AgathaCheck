/** Shared Agatha Track branding for transactional emails. */

export const APP_NAME = 'Agatha Track';
export const PRIMARY_COLOR = '#6750A4';
export const PRIMARY_COLOR_HOVER = '#58459a';
export const LOGO_CID = 'agatha-logo';

/** Public app URL used in email links and footers (no trailing slash). */
export function getPublicUrl() {
  const raw = process.env.APP_PUBLIC_URL || 'https://uat.agathatrack.com';
  return String(raw).replace(/\/$/, '');
}

/** Hostname portion of {@link getPublicUrl} for compact footer display. */
export function getPublicHost() {
  try {
    return new URL(getPublicUrl()).host;
  } catch {
    return 'agathatrack.com';
  }
}
