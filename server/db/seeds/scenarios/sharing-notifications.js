import { DEMO_IDS } from '../demo-constants.js';
import { timestampFromNow } from '../helpers.js';

export async function seedSharingNotifications(client) {
  // Share link for Whiskers (pending)
  await client.query(
    `INSERT INTO pet_share_links (id, pet_id, code, created_by, status)
     VALUES ($1, $2, $3, $4, 'pending')
     ON CONFLICT (id) DO UPDATE SET
       code = EXCLUDED.code,
       status = EXCLUDED.status`,
    [DEMO_IDS.buddyShareLink, DEMO_IDS.whiskersPet, 'DEMO-WHISKERS', DEMO_IDS.alice],
  );

  // Carol has shared access to Buddy
  await client.query(
    `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by)
     VALUES ($1, $2, $3, 'shared', $4)
     ON CONFLICT (pet_id, user_id) DO UPDATE SET
       role = EXCLUDED.role,
       hidden = false,
       updated_at = NOW()`,
    [DEMO_IDS.carolPetAccess, DEMO_IDS.buddyPet, DEMO_IDS.carol, DEMO_IDS.alice],
  );

  await client.query(
    `INSERT INTO shared_pets (id, pet_id, user_id, role, invited_by)
     VALUES ($1, $2, $3, 'shared', $4)
     ON CONFLICT (pet_id, user_id) DO UPDATE SET
       role = EXCLUDED.role,
       updated_at = NOW()`,
    ['a8000001-0001-4001-8001-000000000003', DEMO_IDS.buddyPet, DEMO_IDS.carol, DEMO_IDS.alice],
  );

  // Overdue health notification for Buddy flea treatment
  await client.query(
    `INSERT INTO notifications (
       id, user_id, pet_id, pet_name, health_entry_id, title, type, message,
       is_read, read, kind, priority
     )
     VALUES ($1, $2, $3, $4, $5, $6, 'health_reminder', $7, false, false, 'care', 'urgent')
     ON CONFLICT (id) DO UPDATE SET
       message = EXCLUDED.message,
       is_read = EXCLUDED.is_read,
       read = EXCLUDED.read,
       priority = EXCLUDED.priority`,
    [
      DEMO_IDS.buddyOverdueNotification,
      DEMO_IDS.alice,
      DEMO_IDS.buddyPet,
      'Buddy',
      DEMO_IDS.buddyOverduePreventive,
      'Flea treatment overdue',
      'Buddy flea treatment was due — please administer or update the schedule',
    ],
  );

  // Admin notification for Rescue Hearts
  await client.query(
    `INSERT INTO notifications (
       id, user_id, organization_id, title, type, message,
       is_read, read, kind, priority
     )
     VALUES ($1, $2, $3, $4, 'foster_request', $5, false, false, 'administrative', 'normal')
     ON CONFLICT (id) DO UPDATE SET
       message = EXCLUDED.message,
       is_read = EXCLUDED.is_read`,
    [
      DEMO_IDS.rescueAdminNotification,
      DEMO_IDS.alice,
      DEMO_IDS.rescueHeartsOrg,
      'Foster request response received',
      'Eve Foster responded to the urgent weekend foster request',
    ],
  );

  await client.query(
    `INSERT INTO notification_preferences (id, user_id, preference, value)
     VALUES
       ($1, $2, 'health_reminders', 'in_app'),
       ($3, $2, 'foster_updates', 'in_app')
     ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value`,
    [
      'a8110001-0001-4001-8001-000000000001',
      DEMO_IDS.alice,
      'a8110001-0001-4001-8001-000000000002',
    ],
  );

  console.log('seed: sharing-notifications scenario ready');
}
