import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday, timestampFromNow } from '../helpers.js';

export async function seedFostering(client) {
  await client.query(
    `INSERT INTO foster_profiles (
       id, user_id, display_name, email, foster_address, species_capacities
     )
     VALUES ($1, $2, $3, $4, $5, $6::jsonb)
     ON CONFLICT (id) DO UPDATE SET
       display_name = EXCLUDED.display_name,
       email = EXCLUDED.email,
       foster_address = EXCLUDED.foster_address,
       species_capacities = EXCLUDED.species_capacities,
       updated_at = NOW()`,
    [
      DEMO_IDS.eveFosterProfile,
      DEMO_IDS.eve,
      'Eve Foster',
      'eve@demo.agathatrack.test',
      '15 Foster Lane, Manchester',
      JSON.stringify([{ species: 'dog', capacity: 2 }, { species: 'cat', capacity: 1 }]),
    ],
  );

  await client.query(
    `INSERT INTO org_foster_parents (
       id, organization_id, user_id, foster_profile_id, display_name, email,
       foster_address, approval_state, creation_source
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, 'approved', 'member')
     ON CONFLICT (id) DO UPDATE SET
       display_name = EXCLUDED.display_name,
       email = EXCLUDED.email,
       foster_address = EXCLUDED.foster_address,
       approval_state = EXCLUDED.approval_state,
       updated_at = NOW()`,
    [
      DEMO_IDS.eveOrgFosterParent,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.eve,
      DEMO_IDS.eveFosterProfile,
      'Eve Foster',
      'eve@demo.agathatrack.test',
      '15 Foster Lane, Manchester',
    ],
  );

  // Active foster placement — Max with Eve
  await client.query(
    `INSERT INTO foster_placements (
       id, organization_id, pet_id, foster_user_id, org_foster_parent_id,
       status, start_date, session_type, foster_start_confirmed_at,
       shelter_start_confirmed_at, created_by
     )
     VALUES ($1, $2, $3, $4, $5, 'active', $6, 'standard_foster', $7, $7, $8)
     ON CONFLICT (id) DO UPDATE SET
       status = EXCLUDED.status,
       start_date = EXCLUDED.start_date,
       foster_start_confirmed_at = EXCLUDED.foster_start_confirmed_at,
       updated_at = NOW()`,
    [
      DEMO_IDS.maxActivePlacement,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.maxPet,
      DEMO_IDS.eve,
      DEMO_IDS.eveOrgFosterParent,
      calendarDaysFromToday(-21),
      timestampFromNow(-21),
      DEMO_IDS.alice,
    ],
  );

  // Foster-to-adopt placement — Rocky with Eve
  await client.query(
    `INSERT INTO foster_placements (
       id, organization_id, pet_id, foster_user_id, org_foster_parent_id,
       status, start_date, session_type, adoption_conditions,
       foster_start_confirmed_at, shelter_start_confirmed_at, created_by
     )
     VALUES ($1, $2, $3, $4, $5, 'adoption_in_progress', $6, 'foster_in_view_to_adopt', $7, $8, $8, $9)
     ON CONFLICT (id) DO UPDATE SET
       status = EXCLUDED.status,
       adoption_conditions = EXCLUDED.adoption_conditions,
       updated_at = NOW()`,
    [
      DEMO_IDS.rockyAdoptionPlacement,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.rockyPet,
      DEMO_IDS.eve,
      DEMO_IDS.eveOrgFosterParent,
      calendarDaysFromToday(-45),
      'Neutering required before finalisation. Home check within 30 days.',
      timestampFromNow(-45),
      DEMO_IDS.alice,
    ],
  );

  // Completed placement — Mittens
  await client.query(
    `INSERT INTO foster_placements (
       id, organization_id, pet_id, foster_user_id, org_foster_parent_id,
       status, start_date, end_date, session_type,
       foster_start_confirmed_at, shelter_start_confirmed_at, created_by
     )
     VALUES ($1, $2, $3, $4, $5, 'returned_to_shelter', $6, $7, 'standard_foster', $8, $8, $9)
     ON CONFLICT (id) DO UPDATE SET
       status = EXCLUDED.status,
       end_date = EXCLUDED.end_date,
       updated_at = NOW()`,
    [
      DEMO_IDS.mittensCompletedPlacement,
      DEMO_IDS.rescueHeartsOrg,
      DEMO_IDS.mittensPet,
      DEMO_IDS.eve,
      DEMO_IDS.eveOrgFosterParent,
      calendarDaysFromToday(-120),
      calendarDaysFromToday(-30),
      timestampFromNow(-120),
      DEMO_IDS.alice,
    ],
  );

  // Foster request with response
  await client.query(
    `INSERT INTO foster_requests (id, organization_id, message, status, created_by, sent_at)
     VALUES ($1, $2, $3, 'sent', $4, $5)
     ON CONFLICT (id) DO UPDATE SET
       message = EXCLUDED.message,
       status = EXCLUDED.status,
       sent_at = EXCLUDED.sent_at,
       updated_at = NOW()`,
    [
      DEMO_IDS.rescueFosterRequest,
      DEMO_IDS.rescueHeartsOrg,
      'Urgent: need foster for two medium dogs this weekend',
      DEMO_IDS.alice,
      timestampFromNow(-5),
    ],
  );

  await client.query(
    `INSERT INTO foster_request_targets (id, foster_request_id, org_foster_parent_id)
     VALUES ($1, $2, $3)
     ON CONFLICT (id) DO NOTHING`,
    [
      DEMO_IDS.rescueFosterRequestTarget,
      DEMO_IDS.rescueFosterRequest,
      DEMO_IDS.eveOrgFosterParent,
    ],
  );

  await client.query(
    `INSERT INTO foster_request_responses (
       id, foster_request_id, org_foster_parent_id, response, message,
       earliest_availability, responded_at
     )
     VALUES ($1, $2, $3, 'can_help', $4, $5, $6)
     ON CONFLICT (id) DO UPDATE SET
       response = EXCLUDED.response,
       message = EXCLUDED.message,
       responded_at = EXCLUDED.responded_at,
       updated_at = NOW()`,
    [
      DEMO_IDS.rescueFosterRequestResponse,
      DEMO_IDS.rescueFosterRequest,
      DEMO_IDS.eveOrgFosterParent,
      'I can take one dog from Saturday',
      calendarDaysFromToday(2),
      timestampFromNow(-4),
    ],
  );

  console.log('seed: fostering scenario ready (placements, profiles, requests)');
}
