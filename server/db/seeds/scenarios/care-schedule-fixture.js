import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday } from '../helpers.js';

/**
 * Rich scheduling fixtures for Care Schedule Management verification.
 * Covers multi-per-day non-daily frequencies, per-family anchors, weight paths,
 * and from_completion projection uncertainty.
 */
export async function seedCareScheduleFixture(client) {
  const today = calendarDaysFromToday(0);
  const tomorrow = calendarDaysFromToday(1);
  const inFourteen = calendarDaysFromToday(14);
  const inSixty = calendarDaysFromToday(60);
  const lastWeek = calendarDaysFromToday(-7);
  const twoWeeksAgo = calendarDaysFromToday(-14);

  await client.query(
    `INSERT INTO health_entries (
       id, pet_id, user_id, type, name, dosage, frequency, frequency_interval,
       start_date, next_due_date, status, remind_days_before, notes,
       care_family, care_source, recurrence_anchor, schedule_times,
       care_setting, care_planning, care_importance
     )
     VALUES
       ($1, $20, $21, 'medication', 'Weekly antibiotic course', '1 capsule', 'weekly', 1,
        $2, $2, 'active', 3,
        'Twice-daily slots on a weekly cadence — exercises multi-per-day rollover',
        'medication', 'vet_instruction', 'from_completion', $3::jsonb, 'home', 'planned', 'essential'),
       ($4, $20, $21, 'preventive', 'Rabies booster', '', 'yearly', 1,
        $5, $6, 'active', 14,
        'Clinical interval — from_due_date anchor (vaccination family default)',
        'vaccination', 'vet_instruction', 'from_due_date', NULL, 'vet', 'planned', 'essential'),
       ($7, $20, $21, 'preventive', 'Flea & tick prevention', '', 'monthly', 1,
        $8, $9, 'active', 7,
        'Parasite prevention — from_due_date anchor',
        'parasite_prevention', 'guardian_defined', 'from_due_date', NULL, 'home', 'planned', 'essential'),
       ($10, $20, $21, 'medication', 'Evening allergy tablet', '1 tablet', 'daily', 1,
        $11, $11, 'active', 3,
        'Guardian-paced daily rhythm — from_completion anchor',
        'medication', 'guardian_defined', 'from_completion', NULL, 'home', 'planned', 'essential'),
       ($12, $20, $21, 'other', 'Weekly weight check', '', 'weekly', 1,
        $13, $14, 'active', 3,
        'Weight monitoring with occurrence-linked observations',
        'weight_monitoring', 'guardian_defined', 'from_completion', NULL, 'home', 'planned', 'recommended'),
       ($15, $20, $21, 'other', 'Future weigh-in series', '', 'weekly', 1,
        $16, $16, 'active', 3,
        'Far-future next_due — no materialised occurrences (legacy mark-taken blind spot)',
        'weight_monitoring', 'guardian_defined', 'from_completion', NULL, 'home', 'planned', 'recommended'),
       ($17, $20, $21, 'medication', 'Morning joint supplement', '1 tablet', 'daily', 1,
        $18, $18, 'active', 3,
        'from_completion with pending occurrence for projection uncertainty',
        'medication', 'guardian_defined', 'from_completion', NULL, 'home', 'planned', 'essential')
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       frequency = EXCLUDED.frequency,
       frequency_interval = EXCLUDED.frequency_interval,
       next_due_date = EXCLUDED.next_due_date,
       recurrence_anchor = EXCLUDED.recurrence_anchor,
       schedule_times = EXCLUDED.schedule_times,
       care_family = EXCLUDED.care_family,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [
      DEMO_IDS.csmWeeklyCourse,
      today,
      JSON.stringify(['08:00', '20:00']),
      DEMO_IDS.csmVaccinationDueDate,
      calendarDaysFromToday(-365),
      inFourteen,
      DEMO_IDS.csmParasiteDueDate,
      calendarDaysFromToday(-30),
      calendarDaysFromToday(-3),
      DEMO_IDS.csmMedFromCompletion,
      today,
      DEMO_IDS.csmWeightLinked,
      twoWeeksAgo,
      today,
      DEMO_IDS.csmWeightFarFuture,
      inSixty,
      DEMO_IDS.csmFromCompletionDaily,
      today,
      DEMO_IDS.buddyPet,
      DEMO_IDS.alice,
    ],
  );

  await client.query(
    `INSERT INTO health_occurrences (
       id, health_entry_id, scheduled_date, scheduled_time, status,
       completed_on, notes
     )
     VALUES
       ($1, $2, $3, '08:00'::time, 'pending', NULL, 'Morning dose pending'),
       ($4, $2, $3, '20:00'::time, 'completed', $3, 'Evening dose done — partial day'),
       ($5, $2, $6, '08:00'::time, 'pending', NULL, 'Pre-materialised tomorrow morning'),
       ($7, $8, $9, NULL, 'completed', $9, 'Weight check two weeks ago'),
       ($10, $8, $11, NULL, 'completed', $11, 'Weight check last week'),
       ($12, $8, $3, NULL, 'pending', NULL, 'Weight check due today'),
       ($13, $14, $3, NULL, 'pending', NULL, 'from_completion hop unresolved')
     ON CONFLICT (id) DO UPDATE SET
       status = EXCLUDED.status,
       scheduled_date = EXCLUDED.scheduled_date,
       scheduled_time = EXCLUDED.scheduled_time,
       completed_on = EXCLUDED.completed_on,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [
      DEMO_IDS.csmWeeklyOccMorning,
      DEMO_IDS.csmWeeklyCourse,
      today,
      DEMO_IDS.csmWeeklyOccEvening,
      DEMO_IDS.csmWeeklyOccTomorrowMorning,
      tomorrow,
      DEMO_IDS.csmWeightOccCompleted1,
      DEMO_IDS.csmWeightLinked,
      twoWeeksAgo,
      DEMO_IDS.csmWeightOccCompleted2,
      lastWeek,
      DEMO_IDS.csmWeightOccPending,
      DEMO_IDS.csmFromCompletionOccPending,
      DEMO_IDS.csmFromCompletionDaily,
    ],
  );

  await client.query(
    `INSERT INTO weight_entries (
       id, pet_id, user_id, weight, unit, date, notes, health_occurrence_id
     )
     VALUES
       ($1, $6, $7, 28.1, 'kg', $2, 'Linked to completed weight occurrence', $3),
       ($4, $6, $7, 28.4, 'kg', $5, 'Linked to completed weight occurrence', $8)
     ON CONFLICT (id) DO UPDATE SET
       weight = EXCLUDED.weight,
       date = EXCLUDED.date,
       health_occurrence_id = EXCLUDED.health_occurrence_id,
       notes = EXCLUDED.notes`,
    [
      DEMO_IDS.csmWeightLinkedWe1,
      twoWeeksAgo,
      DEMO_IDS.csmWeightOccCompleted1,
      DEMO_IDS.csmWeightLinkedWe2,
      lastWeek,
      DEMO_IDS.buddyPet,
      DEMO_IDS.alice,
      DEMO_IDS.csmWeightOccCompleted2,
    ],
  );

  console.log('seed: care-schedule-fixture ready (CSM edge-case rhythms + occurrences)');
}
