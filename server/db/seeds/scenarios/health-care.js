import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday, timestampFromNow } from '../helpers.js';

export async function seedHealthCare(client) {
  await client.query(
    `INSERT INTO vets (id, user_id, name, clinic, phone, email, address, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       clinic = EXCLUDED.clinic,
       phone = EXCLUDED.phone,
       email = EXCLUDED.email,
       address = EXCLUDED.address,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [
      DEMO_IDS.aliceVet,
      DEMO_IDS.alice,
      'Dr. Sarah Mitchell',
      'Happy Paws Veterinary Surgery',
      '+44 20 7946 0123',
      'reception@happypaws.demo',
      '42 Demo Street, London',
      'Primary vet for Alice guardian pets',
    ],
  );

  await client.query(
    `UPDATE pets SET vet_id = $1, updated_at = NOW() WHERE id = $2`,
    [DEMO_IDS.aliceVet, DEMO_IDS.buddyPet],
  );

  await client.query(
    `INSERT INTO health_entries (
       id, pet_id, user_id, type, name, dosage, frequency,
       start_date, next_due_date, status, remind_days_before, notes
     )
     VALUES
       ($1, $6, $7, 'preventive', 'Annual rabies booster', '', 'yearly',
        $8, $9, 'active', 14, 'Due soon — demo upcoming notification'),
       ($2, $6, $7, 'medication', 'Joint supplement', '1 tablet', 'daily',
        $10, $11, 'active', 3, 'Daily medication for arthritis support'),
       ($3, $6, $7, 'preventive', 'Flea treatment', '', 'monthly',
        $12, $13, 'active', 7, 'Overdue — demo overdue notification'),
       ($4, $14, $7, 'vet_visit', 'Annual wellness check', '', 'once',
        $15, NULL, 'active', 0, 'Recent vet visit for Whiskers'),
       ($5, $16, $7, 'preventive', 'Flea & tick prevention', '', 'monthly',
        $17, $18, 'active', 7, 'Foster pet health tracking')
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       next_due_date = EXCLUDED.next_due_date,
       status = EXCLUDED.status,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [
      DEMO_IDS.buddyVaccine,
      DEMO_IDS.buddyMedication,
      DEMO_IDS.buddyOverduePreventive,
      DEMO_IDS.whiskersVetVisit,
      DEMO_IDS.maxFleaTreatment,
      DEMO_IDS.buddyPet,
      DEMO_IDS.alice,
      calendarDaysFromToday(-30),
      calendarDaysFromToday(14),
      calendarDaysFromToday(-60),
      calendarDaysFromToday(7),
      calendarDaysFromToday(-90),
      calendarDaysFromToday(-14),
      DEMO_IDS.whiskersPet,
      calendarDaysFromToday(-14),
      DEMO_IDS.maxPet,
      calendarDaysFromToday(-7),
      calendarDaysFromToday(21),
    ],
  );

  await client.query(
    `INSERT INTO health_issues (
       id, pet_id, user_id, issue_type, name, notes, start_date, status
     )
     VALUES ($1, $2, $3, 'skin', 'Seasonal dermatitis', 'Mild itching in spring — under observation', $4, 'active')
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       notes = EXCLUDED.notes,
       status = EXCLUDED.status,
       updated_at = NOW()`,
    [
      DEMO_IDS.buddySkinIssue,
      DEMO_IDS.buddyPet,
      DEMO_IDS.alice,
      calendarDaysFromToday(-21),
    ],
  );

  await client.query(
    `INSERT INTO weight_entries (id, pet_id, user_id, weight, date, notes)
     VALUES
       ($1, $6, $7, 27.8, $2, 'Baseline weight'),
       ($3, $6, $7, 28.5, $4, 'Recent weigh-in'),
       ($5, $8, $7, 4.2, $9, 'Stable weight')
     ON CONFLICT (id) DO UPDATE SET
       weight = EXCLUDED.weight,
       date = EXCLUDED.date,
       notes = EXCLUDED.notes`,
    [
      DEMO_IDS.buddyWeight1,
      calendarDaysFromToday(-60),
      DEMO_IDS.buddyWeight2,
      calendarDaysFromToday(-7),
      DEMO_IDS.whiskersWeight,
      DEMO_IDS.buddyPet,
      DEMO_IDS.alice,
      DEMO_IDS.whiskersPet,
      calendarDaysFromToday(-14),
    ],
  );

  await client.query(
    `INSERT INTO pet_timeline_entries (
       id, pet_id, entry_type, title, description, start_date, created_by
     )
     VALUES ($1, $2, 'manual', 'Adopted from rescue', 'Buddy joined the family', $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       title = EXCLUDED.title,
       description = EXCLUDED.description,
       start_date = EXCLUDED.start_date`,
    [
      DEMO_IDS.buddyTimelineEntry,
      DEMO_IDS.buddyPet,
      calendarDaysFromToday(-365 * 4),
      DEMO_IDS.alice,
    ],
  );

  await client.query(
    `INSERT INTO family_events (
       id, user_id, pet_id, event_type, notes, from_date, to_date, created_by
     )
     VALUES ($1, $2, $3, 'holiday', 'Family holiday — pet sitter arranged', $4, $5, $2)
     ON CONFLICT (id) DO UPDATE SET
       notes = EXCLUDED.notes,
       from_date = EXCLUDED.from_date,
       to_date = EXCLUDED.to_date,
       updated_at = NOW()`,
    [
      DEMO_IDS.aliceHolidayEvent,
      DEMO_IDS.alice,
      DEMO_IDS.buddyPet,
      calendarDaysFromToday(30),
      calendarDaysFromToday(37),
    ],
  );

  await client.query(
    `INSERT INTO pet_activity_events (
       id, pet_id, org_id, event_type, actor_user_id, occurred_at, metadata
     )
     VALUES ($1, $2, $3, 'health_log', $4, $5, $6::jsonb)
     ON CONFLICT (id) DO UPDATE SET
       metadata = EXCLUDED.metadata,
       occurred_at = EXCLUDED.occurred_at`,
    [
      DEMO_IDS.clinicPetActivityEvent,
      DEMO_IDS.clinicPet,
      DEMO_IDS.happyPawsOrg,
      DEMO_IDS.bob,
      timestampFromNow(-3),
      JSON.stringify({ action: 'create', entry_type: 'vet_visit' }),
    ],
  );

  console.log('seed: health-care scenario ready (vets, health, weight, timeline)');
}
