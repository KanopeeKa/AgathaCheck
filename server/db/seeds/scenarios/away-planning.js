import {
  COVERAGE_STATE_ALL_COMPLETED,
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_INDETERMINATE,
  COVERAGE_STATE_NOTHING_SCHEDULED,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
} from '../../../lib/care/carePeriodCoverage.js';
import {
  CARER_COVERAGE_ALL_HAVE_CARERS,
  CARER_COVERAGE_NONE_HAVE_CARERS,
  CARER_COVERAGE_SOME_HAVE_CARERS,
} from '../../../lib/care/awayPlan/readiness.js';
import {
  CARER_KIND_NOTE_ONLY,
  CARER_KIND_SHARED_USER,
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
} from '../../../lib/care/plannedAbsence.js';
import { DEMO_IDS } from '../demo-constants.js';
import { calendarDaysFromToday, timestampFromNow } from '../helpers.js';

export const AWAY_PLANNING_ABSENCE_IDS = [
  DEMO_IDS.awPastAllCompletedAbsence,
  DEMO_IDS.awUpcomingCarerMixAbsence,
  DEMO_IDS.awActiveMultiTimeAbsence,
  DEMO_IDS.awCancelledAbsence,
  DEMO_IDS.awFutureNothingScheduledAbsence,
  DEMO_IDS.awIndeterminateAbsence,
  DEMO_IDS.awNoUnresolvedAbsence,
  DEMO_IDS.awDownloadedEditedAbsence,
];

export function awayPlanningSeedFacts() {
  return {
    absences: {
      pastAllCompleted: {
        id: DEMO_IDS.awPastAllCompletedAbsence,
        lifecycle: 'past',
        carer_mix: CARER_COVERAGE_ALL_HAVE_CARERS,
        coverage_state: COVERAGE_STATE_ALL_COMPLETED,
      },
      upcomingCarerMix: {
        id: DEMO_IDS.awUpcomingCarerMixAbsence,
        lifecycle: 'upcoming',
        carer_mix: CARER_COVERAGE_SOME_HAVE_CARERS,
        coverage_state: COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
      },
      activeMultiTime: {
        id: DEMO_IDS.awActiveMultiTimeAbsence,
        lifecycle: 'upcoming',
        multi_time_entry_id: DEMO_IDS.csmWeeklyCourse,
        coverage_state: COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
      },
      cancelled: {
        id: DEMO_IDS.awCancelledAbsence,
        lifecycle: 'cancelled',
        status: PLANNED_ABSENCE_STATUS_CANCELLED,
      },
      futureNothingScheduled: {
        id: DEMO_IDS.awFutureNothingScheduledAbsence,
        lifecycle: 'upcoming',
        carer_mix: CARER_COVERAGE_NONE_HAVE_CARERS,
        coverage_state: COVERAGE_STATE_NOTHING_SCHEDULED,
      },
      indeterminate: {
        id: DEMO_IDS.awIndeterminateAbsence,
        lifecycle: 'upcoming',
        coverage_state: COVERAGE_STATE_INDETERMINATE,
        from_completion_entry_id: DEMO_IDS.csmFromCompletionDaily,
      },
      noUnresolved: {
        id: DEMO_IDS.awNoUnresolvedAbsence,
        lifecycle: 'past',
        coverage_state: COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
      },
      downloadedEdited: {
        id: DEMO_IDS.awDownloadedEditedAbsence,
        lifecycle: 'upcoming',
        handover_downloaded_then_edited: true,
      },
    },
    coverage_states: [
      COVERAGE_STATE_ALL_COMPLETED,
      COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
      COVERAGE_STATE_NOTHING_SCHEDULED,
      COVERAGE_STATE_INDETERMINATE,
      COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
    ],
    carer_mix_states: [
      CARER_COVERAGE_ALL_HAVE_CARERS,
      CARER_COVERAGE_SOME_HAVE_CARERS,
      CARER_COVERAGE_NONE_HAVE_CARERS,
    ],
  };
}

async function columnExists(client, table, column) {
  const result = await client.query(
    `SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = $1 AND column_name = $2`,
    [table, column],
  );
  return result.rows.length > 0;
}

async function upsertAbsence(client, row) {
  await client.query(
    `INSERT INTO planned_absences (id, user_id, starts_on, ends_on, status, cancelled_at)
     VALUES ($1, $2, $3::date, $4::date, $5, $6)
     ON CONFLICT (id) DO UPDATE SET
       starts_on = EXCLUDED.starts_on,
       ends_on = EXCLUDED.ends_on,
       status = EXCLUDED.status,
       cancelled_at = EXCLUDED.cancelled_at,
       updated_at = NOW()`,
    [
      row.id,
      row.userId,
      row.startsOn,
      row.endsOn,
      row.status || PLANNED_ABSENCE_STATUS_ACTIVE,
      row.cancelledAt || null,
    ],
  );
}

async function upsertAbsencePet(client, absenceId, petId, carer = null) {
  await client.query(
    `INSERT INTO planned_absence_pets (
       planned_absence_id, pet_id, carer_kind, carer_user_id, carer_name, carer_note
     )
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (planned_absence_id, pet_id) DO UPDATE SET
       carer_kind = EXCLUDED.carer_kind,
       carer_user_id = EXCLUDED.carer_user_id,
       carer_name = EXCLUDED.carer_name,
       carer_note = EXCLUDED.carer_note`,
    [
      absenceId,
      petId,
      carer?.kind ?? null,
      carer?.userId ?? null,
      carer?.name ?? null,
      carer?.note ?? null,
    ],
  );
}

async function setHandoverDownloadedAt(client, absenceId, downloadedAt) {
  if (!(await columnExists(client, 'planned_absences', 'last_handover_downloaded_at'))) {
    return false;
  }
  await client.query(
    `UPDATE planned_absences
     SET last_handover_downloaded_at = $2::timestamptz, updated_at = NOW()
     WHERE id = $1`,
    [absenceId, downloadedAt],
  );
  return true;
}

export async function countAwayPlanningSeedRows(client) {
  const absences = await client.query(
    `SELECT COUNT(*)::int AS count FROM planned_absences WHERE id = ANY($1::uuid[])`,
    [AWAY_PLANNING_ABSENCE_IDS],
  );
  const pets = await client.query(
    `SELECT COUNT(*)::int AS count FROM planned_absence_pets WHERE planned_absence_id = ANY($1::uuid[])`,
    [AWAY_PLANNING_ABSENCE_IDS],
  );
  return { absences: absences.rows[0].count, pet_rows: pets.rows[0].count };
}

async function seedNoUnresolvedFixture(client, startsOn, endsOn) {
  await client.query(
    `INSERT INTO health_entries (
       id, pet_id, user_id, type, name, dosage, frequency,
       start_date, next_due_date, status, remind_days_before, notes, care_family,
       care_setting, care_planning, care_importance
     )
     VALUES ($1, $2, $3, 'other', 'Away-planning skipped/completed demo', '', 'once',
             $4, $4, 'active', 0, 'AW-SEED no_unresolved_items window', NULL,
             'other', 'planned', 'optional')
     ON CONFLICT (id) DO UPDATE SET
       start_date = EXCLUDED.start_date,
       next_due_date = EXCLUDED.next_due_date,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [DEMO_IDS.awNoUnresolvedEntry, DEMO_IDS.buddyPet, DEMO_IDS.alice, startsOn],
  );

  await client.query(
    `INSERT INTO health_occurrences (
       id, health_entry_id, scheduled_date, status, completed_on, notes
     )
     VALUES
       ($1, $4, $2::date, 'completed', $2::date, 'Completed before away window'),
       ($3, $4, $5::date, 'skipped', NULL, 'Skipped dose')
     ON CONFLICT (id) DO UPDATE SET
       scheduled_date = EXCLUDED.scheduled_date,
       status = EXCLUDED.status,
       completed_on = EXCLUDED.completed_on,
       notes = EXCLUDED.notes,
       updated_at = NOW()`,
    [
      DEMO_IDS.awNoUnresolvedOccCompleted,
      startsOn,
      DEMO_IDS.awNoUnresolvedOccSkipped,
      DEMO_IDS.awNoUnresolvedEntry,
      endsOn,
    ],
  );
}

export async function seedAwayPlanning(client) {
  const today = calendarDaysFromToday(0);
  await seedNoUnresolvedFixture(client, calendarDaysFromToday(-3), calendarDaysFromToday(-1));

  await upsertAbsence(client, {
    id: DEMO_IDS.awPastAllCompletedAbsence,
    userId: DEMO_IDS.alice,
    startsOn: calendarDaysFromToday(-14),
    endsOn: calendarDaysFromToday(-7),
  });
  await upsertAbsencePet(client, DEMO_IDS.awPastAllCompletedAbsence, DEMO_IDS.buddyPet, {
    kind: CARER_KIND_NOTE_ONLY,
    name: 'Pat Neighbour',
    note: 'Has spare key',
  });
  await upsertAbsencePet(client, DEMO_IDS.awPastAllCompletedAbsence, DEMO_IDS.whiskersPet, {
    kind: CARER_KIND_NOTE_ONLY,
    name: 'Tom Sitter',
    note: 'Indoor cat only',
  });

  await upsertAbsence(client, {
    id: DEMO_IDS.awUpcomingCarerMixAbsence,
    userId: DEMO_IDS.alice,
    startsOn: calendarDaysFromToday(7),
    endsOn: calendarDaysFromToday(14),
  });
  await upsertAbsencePet(client, DEMO_IDS.awUpcomingCarerMixAbsence, DEMO_IDS.buddyPet, {
    kind: CARER_KIND_SHARED_USER,
    userId: DEMO_IDS.carol,
  });
  await upsertAbsencePet(client, DEMO_IDS.awUpcomingCarerMixAbsence, DEMO_IDS.whiskersPet);

  await upsertAbsence(client, {
    id: DEMO_IDS.awActiveMultiTimeAbsence,
    userId: DEMO_IDS.alice,
    startsOn: today,
    endsOn: calendarDaysFromToday(6),
  });
  await upsertAbsencePet(client, DEMO_IDS.awActiveMultiTimeAbsence, DEMO_IDS.buddyPet, {
    kind: CARER_KIND_SHARED_USER,
    userId: DEMO_IDS.carol,
  });

  await upsertAbsence(client, {
    id: DEMO_IDS.awCancelledAbsence,
    userId: DEMO_IDS.alice,
    startsOn: calendarDaysFromToday(21),
    endsOn: calendarDaysFromToday(28),
    status: PLANNED_ABSENCE_STATUS_CANCELLED,
    cancelledAt: timestampFromNow(-2),
  });
  await upsertAbsencePet(client, DEMO_IDS.awCancelledAbsence, DEMO_IDS.buddyPet);

  await upsertAbsence(client, {
    id: DEMO_IDS.awFutureNothingScheduledAbsence,
    userId: DEMO_IDS.alice,
    startsOn: calendarDaysFromToday(90),
    endsOn: calendarDaysFromToday(97),
  });
  await upsertAbsencePet(client, DEMO_IDS.awFutureNothingScheduledAbsence, DEMO_IDS.whiskersPet);

  await upsertAbsence(client, {
    id: DEMO_IDS.awIndeterminateAbsence,
    userId: DEMO_IDS.alice,
    startsOn: today,
    endsOn: calendarDaysFromToday(2),
  });
  await upsertAbsencePet(client, DEMO_IDS.awIndeterminateAbsence, DEMO_IDS.buddyPet, {
    kind: CARER_KIND_NOTE_ONLY,
    name: 'Weekend cover',
  });

  await upsertAbsence(client, {
    id: DEMO_IDS.awNoUnresolvedAbsence,
    userId: DEMO_IDS.alice,
    startsOn: calendarDaysFromToday(-3),
    endsOn: calendarDaysFromToday(-1),
  });
  await upsertAbsencePet(client, DEMO_IDS.awNoUnresolvedAbsence, DEMO_IDS.buddyPet, {
    kind: CARER_KIND_SHARED_USER,
    userId: DEMO_IDS.carol,
  });

  await upsertAbsence(client, {
    id: DEMO_IDS.awDownloadedEditedAbsence,
    userId: DEMO_IDS.alice,
    startsOn: calendarDaysFromToday(14),
    endsOn: calendarDaysFromToday(21),
  });
  await upsertAbsencePet(client, DEMO_IDS.awDownloadedEditedAbsence, DEMO_IDS.buddyPet, {
    kind: CARER_KIND_NOTE_ONLY,
    name: 'Downloaded handover carer',
    note: 'Initial note before edit',
  });

  if (await setHandoverDownloadedAt(client, DEMO_IDS.awDownloadedEditedAbsence, timestampFromNow(-3))) {
    await client.query(
      `UPDATE planned_absence_pets
       SET carer_note = $3, carer_name = $4
       WHERE planned_absence_id = $1 AND pet_id = $2`,
      [
        DEMO_IDS.awDownloadedEditedAbsence,
        DEMO_IDS.buddyPet,
        'Edited after handover download',
        'Downloaded handover carer (edited)',
      ],
    );
    await client.query(
      `UPDATE planned_absences SET updated_at = NOW() WHERE id = $1`,
      [DEMO_IDS.awDownloadedEditedAbsence],
    );
  }

  console.log('seed: away-planning ready (carer mix, coverage states, multi-time, lifecycle)');
}
