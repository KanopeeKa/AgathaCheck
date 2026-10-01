import { WEIGHT_ESTABLISHMENT_POLICY_VERSION } from '../../../lib/care/progression/weightEstablishmentPolicy.js';
import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday, upsertPersonalPet } from '../helpers.js';
import {
  clockAt,
  completeEarliest,
  createSeedCareItem,
  dayFrom,
  seedNow,
} from '../helpers/care-commands.js';

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

  // Weekly weight check with four recorded weigh-ins (Care Progression:
  // Established). Other temporal cases live in care-occurrences.js.
  const now = seedNow();
  const weight = { entryId: DEMO_IDS.careFixtureWeightEntry, userId: DEMO_IDS.alice };
  const weightOffsets = [-28, -21, -14, -7];
  const weightEntryIds = [
    DEMO_IDS.careFixtureWeightWe1,
    DEMO_IDS.careFixtureWeightWe2,
    DEMO_IDS.careFixtureWeightWe3,
    DEMO_IDS.careFixtureWeightWe4,
  ];
  await createSeedCareItem(client, {
    id: weight.entryId,
    petId: DEMO_IDS.buddyPet,
    userId: DEMO_IDS.alice,
    name: 'Weekly weight check',
    careFamily: 'weight_monitoring',
    frequency: 'weekly',
    firstDate: dayFrom(now, weightOffsets[0]),
    remindDaysBefore: 3,
    notes: 'Established weight monitoring',
  }, clockAt(now, weightOffsets[0] - 1, '09:00'));

  for (let index = 0; index < weightOffsets.length; index += 1) {
    const offset = weightOffsets[index];
    const done = await completeEarliest(client, weight, clockAt(now, offset, '10:00'));
    if (!done?.occurrence) continue;
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
        27.5 + index * 0.2,
        dayFrom(now, offset),
        `Fixture weigh-in ${index + 1}`,
        done.occurrence.id,
      ],
    );
  }

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
    'seed: care-item-model-fixture ready (Buddy weight establishment + Pebble empty pet)',
  );
}
