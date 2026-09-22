import { WEIGHT_ESTABLISHMENT_POLICY_VERSION } from '../../../lib/care/progression/weightEstablishmentPolicy.js';
import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday, upsertPersonalPet } from '../helpers.js';

/** Facts for [evaluateWeightEstablishment] — evidence only (no establishment row). */
export function careItemModelWeightEstablishmentFacts() {
  const offsets = [-28, -21, -14, -7];
  return {
    entry: {
      id: DEMO_IDS.careFixtureWeightEntry,
      pet_id: DEMO_IDS.buddyPet,
      care_family: 'weight_monitoring',
      status: 'active',
      frequency: 'weekly',
      frequency_interval: 1,
    },
    completedEvidence: offsets.map((offset, index) => ({
      occurrence: { id: `occ-${index + 1}` },
      measurement: {
        date: calendarDaysFromToday(offset),
        weight: 27.5 + index * 0.2,
        unit: 'kg',
      },
    })),
    skippedCount: 0,
    legacyCompletedWithoutWeight: 0,
  };
}

export async function seedCareItemModelFixture(client) {
  await upsertPersonalPet(client, {
    id: DEMO_IDS.pebblePet,
    userId: DEMO_IDS.alice,
    name: 'Pebble',
    species: 'Dog',
    breed: 'Mixed',
    dateOfBirth: calendarDaysFromToday(-365 * 2),
    weight: 12.0,
    gender: 'Female',
    bio: 'Near-empty demo pet for care surface empty states',
  });

  const today = calendarDaysFromToday(0);
  const upcoming = calendarDaysFromToday(4);

  await client.query(
    `INSERT INTO health_entries (
       id, pet_id, user_id, type, name, dosage, frequency,
       start_date, next_due_date, status, remind_days_before, notes, care_family, completed_on,
       care_setting, care_planning, care_importance
     )
     VALUES
       ($1, $7, $8, 'other', 'Morning walk check-in', '', 'daily',
        $9, $10, 'active', 3, 'Due today — not done', 'exercise', NULL, 'other', 'planned', 'optional'),
       ($2, $7, $8, 'medication', 'Evening supplement', '1 tablet', 'daily',
        $11, $12, 'active', 3, 'Due today — already done', 'medication', NULL, 'home', 'planned', 'essential'),
       ($3, $7, $8, 'other', 'Grooming appointment', '', 'once',
        $14, $15, 'active', 1, 'One-off due today', NULL, NULL, 'other', 'planned', 'optional'),
       ($4, $7, $8, 'other', 'Mystery care item', '', 'weekly',
        $16, $17, 'active', 7, 'Uncategorised care_family', NULL, NULL, 'other', 'planned', 'optional'),
       ($5, $7, $8, 'preventive', 'Nail trim', '', 'monthly',
        $18, $19, 'active', 7, 'Upcoming later this week', 'grooming', NULL, 'other', 'planned', 'optional'),
       ($6, $7, $8, 'other', 'Weekly weight check', '', 'weekly',
        $20, $21, 'active', 3, 'Established weight monitoring', 'weight_monitoring', NULL, 'home', 'planned', 'recommended')
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       next_due_date = EXCLUDED.next_due_date,
       status = EXCLUDED.status,
       notes = EXCLUDED.notes,
       care_family = EXCLUDED.care_family,
       completed_on = EXCLUDED.completed_on,
       updated_at = NOW()`,
    [
      DEMO_IDS.careFixtureTodayPending,
      DEMO_IDS.careFixtureTodayDone,
      DEMO_IDS.careFixtureOneOffToday,
      DEMO_IDS.careFixtureUncategorised,
      DEMO_IDS.careFixtureUpcomingWeek,
      DEMO_IDS.careFixtureWeightEntry,
      DEMO_IDS.buddyPet,
      DEMO_IDS.alice,
      calendarDaysFromToday(-14),
      today,
      calendarDaysFromToday(-30),
      today,
      calendarDaysFromToday(-7),
      today,
      calendarDaysFromToday(-60),
      upcoming,
      calendarDaysFromToday(-56),
      upcoming,
      calendarDaysFromToday(-35),
      calendarDaysFromToday(7),
    ],
  );

  await client.query(
    `INSERT INTO health_occurrences (
       id, health_entry_id, scheduled_date, status, completed_on, notes
     )
     VALUES ($1, $2, $3, 'completed', $3, 'Evening supplement done today')
     ON CONFLICT (id) DO UPDATE SET
       scheduled_date = EXCLUDED.scheduled_date,
       status = EXCLUDED.status,
       completed_on = EXCLUDED.completed_on`,
    [DEMO_IDS.careFixtureTodayDoneOcc, DEMO_IDS.careFixtureTodayDone, today],
  );

  const weightOffsets = [-28, -21, -14, -7];
  const weightOccIds = [
    DEMO_IDS.careFixtureWeightOcc1,
    DEMO_IDS.careFixtureWeightOcc2,
    DEMO_IDS.careFixtureWeightOcc3,
    DEMO_IDS.careFixtureWeightOcc4,
  ];
  const weightEntryIds = [
    DEMO_IDS.careFixtureWeightWe1,
    DEMO_IDS.careFixtureWeightWe2,
    DEMO_IDS.careFixtureWeightWe3,
    DEMO_IDS.careFixtureWeightWe4,
  ];

  for (let index = 0; index < weightOffsets.length; index += 1) {
    const date = calendarDaysFromToday(weightOffsets[index]);
    const weight = 27.5 + index * 0.2;
    await client.query(
      `INSERT INTO health_occurrences (
         id, health_entry_id, scheduled_date, status, completed_on, notes
       )
       VALUES ($1, $2, $3, 'completed', $3, $4)
       ON CONFLICT (id) DO UPDATE SET
         status = EXCLUDED.status,
         completed_on = EXCLUDED.completed_on`,
      [
        weightOccIds[index],
        DEMO_IDS.careFixtureWeightEntry,
        date,
        `Completed weight occurrence ${index + 1}`,
      ],
    );

    await client.query(
      `INSERT INTO weight_entries (
         id, pet_id, user_id, weight, unit, date, notes, measurement_source, health_occurrence_id
       )
       VALUES ($1, $2, $3, $4, 'kg', $5, $6, 'guardian', $7)
       ON CONFLICT (id) DO UPDATE SET
         weight = EXCLUDED.weight,
         date = EXCLUDED.date,
         health_occurrence_id = EXCLUDED.health_occurrence_id`,
      [
        weightEntryIds[index],
        DEMO_IDS.buddyPet,
        DEMO_IDS.alice,
        weight,
        date,
        `Fixture weigh-in ${index + 1}`,
        weightOccIds[index],
      ],
    );
  }

  await client.query(
    `INSERT INTO health_occurrences (
       id, health_entry_id, scheduled_date, status, notes
     )
     VALUES ($1, $2, $3, 'pending', 'Next weight check')
     ON CONFLICT (id) DO UPDATE SET
       scheduled_date = EXCLUDED.scheduled_date,
       status = EXCLUDED.status`,
    [
      DEMO_IDS.careFixtureWeightOccPending,
      DEMO_IDS.careFixtureWeightEntry,
      calendarDaysFromToday(7),
    ],
  );

  await client.query(
    `INSERT INTO care_establishments (
       id, pet_id, care_family, health_entry_id, established_at, policy_version
     )
     VALUES ($1, $2, 'weight_monitoring', $3, NOW(), $4)
     ON CONFLICT (health_entry_id) DO UPDATE SET
       established_at = EXCLUDED.established_at,
       policy_version = EXCLUDED.policy_version`,
    [
      DEMO_IDS.careFixtureWeightEstablishment,
      DEMO_IDS.buddyPet,
      DEMO_IDS.careFixtureWeightEntry,
      WEIGHT_ESTABLISHMENT_POLICY_VERSION,
    ],
  );

  console.log(
    'seed: care-item-model-fixture ready (Buddy temporal groups + Pebble empty pet)',
  );
}
