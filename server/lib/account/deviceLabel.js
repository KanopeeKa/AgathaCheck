const UNKNOWN_DEVICE = 'Unknown device';

const MAX_LABEL_LEN = 120;

/**
 * Coarse device label from User-Agent (N13). Never stores raw UA.
 * @param {string} userAgent
 */
export function parseUserAgentLabel(userAgent = '') {
  const ua = String(userAgent || '').trim();
  if (!ua) return UNKNOWN_DEVICE;

  const isAndroid = /Android/i.test(ua);
  const isIos = /iPhone|iPad|iPod/i.test(ua);
  const isAgathaApp = /AgathaTrack|AgathaCheck|Dart\/\d/i.test(ua);

  if (isAgathaApp && isAndroid) return 'Agatha app on Android';
  if (isAgathaApp && isIos) return 'Agatha app on iOS';
  if (isAgathaApp) return 'Agatha app';

  let browser = 'Browser';
  if (/Edg\//i.test(ua)) browser = 'Edge';
  else if (/Chrome\//i.test(ua) && !/Edg\//i.test(ua)) browser = 'Chrome';
  else if (/Firefox\//i.test(ua)) browser = 'Firefox';
  else if (/Safari\//i.test(ua) && !/Chrome\//i.test(ua)) browser = 'Safari';

  let os = 'Unknown OS';
  if (/Windows NT/i.test(ua)) os = 'Windows';
  else if (/Mac OS X/i.test(ua) && !isIos) os = 'macOS';
  else if (isAndroid) os = 'Android';
  else if (isIos) os = 'iOS';
  else if (/Linux/i.test(ua)) os = 'Linux';

  return `${browser} on ${os}`;
}

/**
 * @param {import('express').Request} req
 */
export function deriveDeviceLabelFromRequest(req) {
  const bodyLabel = req.body?.device_label ?? req.body?.deviceLabel;
  if (typeof bodyLabel === 'string' && bodyLabel.trim()) {
    return bodyLabel.trim().slice(0, MAX_LABEL_LEN);
  }
  return parseUserAgentLabel(req.headers?.['user-agent'] || '');
}

export { UNKNOWN_DEVICE, MAX_LABEL_LEN };
