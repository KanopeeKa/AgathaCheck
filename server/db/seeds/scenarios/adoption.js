import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday, timestampFromNow } from '../helpers.js';

export async function seedAdoption(client) {
  // Adoption journey for Rocky (foster-to-adopt in progress)
  await client.query(
    `INSERT INTO adoption_journeys (
       id, organization_id, fostering_session_id, pet_id, foster_user_id,
       status, adoption_conditions, started_at, created_by, milestone_items
     )
     VALUES ($1, $2, $3, $4, $5, 'pending_conditions', $6, $7, $8, $9::jsonb)
     ON CONFLICT (id) DO UPDATE SET
       status = EXCLUDED.status,
       adoption_conditions = EXCLUDED.adoption_conditions,
       milestone_items = EXCLUDED.milestone_items,
       updated_at = NOW()`,
    [
      DEMO_IDS.rockyAdoptionJourney,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.rockyAdoptionPlacement,
      DEMO_IDS.rockyPet,
      DEMO_IDS.eve,
      'Neutering required before finalisation. Home check within 30 days.',
      timestampFromNow(-14),
      DEMO_IDS.alice,
      JSON.stringify({
        home_check: { completed: true, completed_at: timestampFromNow(-7) },
        adoption_contract: { completed: false },
      }),
    ],
  );

  // Prospect for Luna adoption
  await client.query(
    `INSERT INTO prospects (
       id, organization_id, display_name, email, phone, notes,
       creation_source, user_id, created_by
     )
     VALUES ($1, $2, $3, $4, $5, $6, 'registered_user', $7, $8)
     ON CONFLICT (id) DO UPDATE SET
       display_name = EXCLUDED.display_name,
       email = EXCLUDED.email,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [
      DEMO_IDS.lunaProspect,
      DEMO_IDS.rescueHeartsOrg,
      'Grace Prospect',
      'grace@demo.agathatrack.test',
      '+44 7700 900123',
      'Interested in adopting Luna — first-time cat owner',
      DEMO_IDS.grace,
      DEMO_IDS.alice,
    ],
  );

  // Scheduled adoption visit for Luna
  await client.query(
    `INSERT INTO adoption_visits (
       id, organization_id, prospect_id, pet_id, scheduled_at, status,
       assigned_foster_parent_id, created_by
     )
     VALUES ($1, $2, $3, $4, $5, 'scheduled', $6, $7)
     ON CONFLICT (id) DO UPDATE SET
       scheduled_at = EXCLUDED.scheduled_at,
       status = EXCLUDED.status,
       updated_at = NOW()`,
    [
      DEMO_IDS.lunaAdoptionVisit,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.lunaProspect,
      DEMO_IDS.lunaPet,
      timestampFromNow(3),
      DEMO_IDS.eveOrgFosterParent,
      DEMO_IDS.alice,
    ],
  );

  // Pending custody transfer for Luna (org internal demo)
  await client.query(
    `INSERT INTO custody_transfers (
       id, pet_id, transfer_kind, from_org_id, to_user_id,
       requested_by_user_id, requesting_org_id, status, notes
     )
     VALUES ($1, $2, 'individual_guardianship', $3, $4, $5, $3, 'pending', $6)
     ON CONFLICT (id) DO UPDATE SET
       status = EXCLUDED.status,
       notes = EXCLUDED.notes`,
    [
      DEMO_IDS.lunaCustodyTransfer,
      DEMO_IDS.lunaPet,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.grace,
      DEMO_IDS.alice,
      'Pending adoption transfer to Grace after visit',
    ],
  );

  console.log('seed: adoption scenario ready (journeys, prospects, visits, custody)');
}
