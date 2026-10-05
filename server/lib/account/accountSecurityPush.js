import { logger } from '../logger.js';

/**
 * Push A1 to other session families (FR-ACC / arch).
 * Deferred: no push token registry on server yet — see deferred.md.
 * @param {{ userId: string, title: string, body: string, excludeSessionFamilyId?: string | null }} params
 */
export async function sendAccountSecurityPushToOtherDevices(params) {
  logger.info(
    {
      userId: params.userId,
      excludeSessionFamilyId: params.excludeSessionFamilyId ?? null,
      title: params.title,
    },
    'account security push (other devices) — no token registry yet',
  );
}
