/** Shared Agatha Track branding for transactional emails. */

export const APP_NAME = 'Agatha Track';
export const PRIMARY_COLOR = '#755B68';
export const PRIMARY_COLOR_HOVER = '#664C59';
export const ORGANIZATION_PRIMARY_COLOR = '#218B6C';
export const ORGANIZATION_PRIMARY_COLOR_HOVER = '#1B765C';
export const LOGO_CID = 'agatha-logo';
export const ORGANIZATION_LOGO_CID = 'agatha-logo-org';

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
