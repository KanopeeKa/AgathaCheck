/**
 * Public access posture for pre-launch vs open API.
 * Env: PUBLIC_ACCESS_MODE=coming_soon|open (default open).
 */

const MODES = new Set(['coming_soon', 'open']);

let warnedUnknown = false;

/**
 * @returns {'coming_soon'|'open'}
 */
export function getPublicAccessMode() {
  const raw = process.env.PUBLIC_ACCESS_MODE;
  if (raw == null || String(raw).trim() === '') {
    return 'open';
  }
  const normalized = String(raw).trim().toLowerCase();
  if (MODES.has(normalized)) {
    return normalized;
  }
  if (!warnedUnknown) {
    warnedUnknown = true;
    console.warn(
      `PUBLIC_ACCESS_MODE="${raw}" is unknown; treating as open. Expected coming_soon|open.`,
    );
  }
  return 'open';
}

export function isPublicAccessClosed() {
  return getPublicAccessMode() === 'coming_soon';
}

let loggedMode = false;

/** Boot log once (no secrets): public_access_mode=<mode> */
export function logPublicAccessModeOnce() {
  if (loggedMode) return;
  loggedMode = true;
  console.info(`public_access_mode=${getPublicAccessMode()}`);
}
