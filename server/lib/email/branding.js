/** Shared AgathaTrack branding for transactional emails. */

export const APP_NAME = 'AgathaTrack';
export const PRIMARY_COLOR = '#755B68';
export const PRIMARY_COLOR_HOVER = '#664C59';
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
