import { createNotification } from '../../notificationHelper.js';
import { NOTIFICATION_TYPE_HOUSEHOLD_ORGANISER_PROMOTED } from '../../notificationKind.js';
import { emitHouseholdPetRemovedNotices } from '../../notifications/relationshipEmitters.js';

/**
 * After-commit notices for account erasure household release (H2, H6).
 *
 * @param {import('pg').Pool} pool
 * @param {{ petNotices: import('../departure/notices.js').HouseholdPetRemovedNotice[], promotions: Array<{ householdId: string, householdName: string, promotedUserId: string }>, householdMeta: Map<string, { householdName: string, recipientUserIds: string[] }> }} params
 */
export async function emitErasureHouseholdNotices(pool, {
  petNotices,
  promotions,
  householdMeta,
}) {
  for (const promo of promotions || []) {
    await createNotification(pool, {
      userId: promo.promotedUserId,
      title: 'Household update',
      message: `You are now the organiser of the ${promo.householdName} household.`,
      type: NOTIFICATION_TYPE_HOUSEHOLD_ORGANISER_PROMOTED,
    });
  }

  const noticesByHousehold = new Map();
  for (const notice of petNotices || []) {
    if (!noticesByHousehold.has(notice.householdId)) {
      noticesByHousehold.set(notice.householdId, []);
    }
    noticesByHousehold.get(notice.householdId).push(notice);
  }

  for (const [householdId, notices] of noticesByHousehold) {
    const meta = householdMeta.get(householdId);
    const householdName = meta?.householdName
      ?? promotions?.find((p) => p.householdId === householdId)?.householdName
      ?? 'Household';
    const recipientUserIds = meta?.recipientUserIds ?? [];
    await emitHouseholdPetRemovedNotices(pool, {
      householdName,
      notices,
      recipientUserIds,
      actorUserId: null,
    });
  }
}
