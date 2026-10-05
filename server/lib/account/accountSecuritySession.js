import { deriveDeviceLabelFromRequest } from './deviceLabel.js';
import { recordAccountDeviceSignIn } from './accountDeviceLabels.js';

/**
 * @param {import('pg').Pool} pool
 * @param {import('express').Request} req
 * @param {{
 *   userId: string,
 *   email: string,
 *   sessionFamilyId?: string | null,
 *   isSignupSession?: boolean,
 * }} params
 */
export async function captureDeviceLabelAfterAuth(pool, req, params) {
  const label = deriveDeviceLabelFromRequest(req);
  return recordAccountDeviceSignIn(pool, {
    userId: params.userId,
    email: params.email,
    label,
    sessionFamilyId: params.sessionFamilyId ?? null,
    isSignupSession: params.isSignupSession ?? false,
    excludeSessionFamilyIdForPush: params.sessionFamilyId ?? null,
  });
}
