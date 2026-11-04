# Care status model (six vertical slices)

## Goal

Deliver the agreed care date outcome and care item Closed model from
`docs/domains/pet_care/changes/care-status-model-spec.md` (R-001 … R-028) in six
vertical slices on integration branch `cursor/care-status-model-integration-*`, then one
release PR to `main` and UAT. Flutter web ships with the server (no compatibility layer).

**Production data migrations (owner phase-merge approval, in addition to `approve-autonomous`):**
- **Slice 1 — migration 084:** in-place care date outcome backfill + drop `close_reason`.
- **Slice 4 — migration 085:** health entry status `completed` → `closed` for finished /
  archived / recorded care (audit-only item backfill per spec).

Record explicit owner consent on control issue **#2067** before each of those phase PRs merges.

## Phases

### Phase 1 — Truthful History
```json
{
  "allowed_paths": [
    "server/scripts/migrations/084_*",
    "server/lib/care/occurrence/**",
    "server/lib/care/item/scheduling.js",
    "server/lib/care/schedule/validateReschedule.js",
    "server/lib/care/schedule/scheduleEventLedger.js",
    "server/lib/care/repair/tzShiftRepair.js",
    "server/lib/care/progression/weightEstablishmentService.js",
    "server/lib/health/**",
    "server/routes/healthEntries/**",
    "server/test/db/**",
    "server/test/healthEntries/**",
    "server/test/careSchedule/**",
    "flutter_app/lib/features/care_item/**",
    "flutter_app/lib/features/experience/presentation/care_item/**",
    "flutter_app/lib/features/health_tracking/**",
    "flutter_app/lib/features/pet_care/**",
    "flutter_app/test/features/care_item/**",
    "flutter_app/test/bdd/features/care_date_screen.feature",
    "e2e/playwright/tests/care.date.spec.ts"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": ["docs/architecture/openapi/**"],
  "exit_checklist": [
    "Migration 084 backfill idempotent",
    "History wire shows outcome not_recorded",
    "CSV says Not recorded for system rows",
    "Record Not recorded as Done from History",
    "pre-push-changed green"
  ]
}
```
Scope: In-place occurrence outcome migration; history and CSV truthful; Not recorded → Done from History.

**Slice 1 interim (until slice 3 pause delete rule):** dropping `close_reason` means every writer
that used `close_reason` (`not_recorded`, `system`, `paused`, `user`) must set stored
`status` instead on the same paths touched in this slice — system/pause closes become
`not_recorded` (not user `skipped`); user skip stays `skipped`. No dual-write.

Out of scope: Stack removal, item Closed status, Close care button.

### Phase 2 — Not recorded at next dose
```json
{
  "allowed_paths": [
    "server/lib/care/occurrence/syncOpenOccurrences.js",
    "server/lib/care/occurrence/readSync.js",
    "server/lib/care/schedule/occurrenceStatus.js",
    "server/lib/care/occurrence/commands/stack.js",
    "server/routes/healthEntries/occurrenceCommandRouter.js",
    "server/test/db/careOccurrences.*",
    "flutter_app/lib/features/care_item/application/care_completion_service.dart",
    "flutter_app/lib/features/care_item/application/care_stack_feedback.dart",
    "flutter_app/lib/features/care_item/domain/stack_rule.dart",
    "flutter_app/lib/features/care_item/domain/care_agenda.dart",
    "flutter_app/lib/features/care_item/domain/done_decision.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_needs_attention_section.dart",
    "flutter_app/lib/features/pet_care/presentation/widgets/care_agenda/**",
    "flutter_app/lib/features/health_tracking/domain/entities/health_entry.dart",
    "flutter_app/lib/l10n/**",
    "flutter_app/test/features/care_item/**",
    "flutter_app/test/bdd/features/care_agenda.feature",
    "flutter_app/test/bdd/features/care_schedules.feature",
    "flutter_app/test/bdd/features/health_tracking.feature",
    "e2e/playwright/tests/care.agenda.spec.ts",
    "e2e/playwright/tests/care.schedules.spec.ts",
    "e2e/playwright/tests/health.tracking.spec.ts"
  ],
  "forbidden_paths": ["server/scripts/migrations/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [],
  "exit_checklist": [
    "Fixed next dose stores not_recorded",
    "resolve-stack route removed",
    "Stack Review UI removed",
    "pre-push-changed green"
  ]
}
```
Scope: R-005 mechanism; remove stack, Review, Record earlier doses.
Out of scope: Pause delete rule, Close care.

### Phase 3 — Pause and schedule rule
```json
{
  "allowed_paths": [
    "server/lib/care/occurrence/commands/postpone.js",
    "server/lib/care/occurrence/commands/lifecycle.js",
    "server/lib/care/occurrence/occurrenceRepository.js",
    "server/test/db/**",
    "server/test/careSchedule/**",
    "flutter_app/test/bdd/features/care_pause_resume.feature",
    "flutter_app/test/bdd/features/care_schedules.feature",
    "e2e/playwright/tests/care.item.pause_resume.spec.ts",
    "e2e/playwright/tests/care.schedules.spec.ts"
  ],
  "forbidden_paths": ["server/scripts/migrations/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": ["flutter_app/lib/features/care_item/**"],
  "exit_checklist": [
    "R-008 started to not_recorded not-started deleted",
    "No ledger for deleted dates",
    "pre-push-changed green"
  ]
}
```
Scope: R-008 pause and schedule reconciliation.
Out of scope: Item closed migration, Close care UI.

### Phase 4 — Care item Closed status
```json
{
  "allowed_paths": [
    "server/scripts/migrations/085_*",
    "server/lib/care/occurrence/syncOpenOccurrences.js",
    "server/lib/care/item/**",
    "server/lib/care/occurrence/commands/**",
    "server/lib/care/carePeriodCoverage.js",
    "server/lib/care/schedule/nextComputed.js",
    "server/lib/health/healthEntryWriteService.js",
    "server/lib/care/observations/weightObservationRepository.js",
    "server/lib/pets/vetVisits.js",
    "server/routes/careIntelligence/**",
    "server/routes/pets/familyEventsRouter.js",
    "server/lib/account/accountErasureService.js",
    "server/test/db/**",
    "flutter_app/lib/features/experience/presentation/care_item/detail/**",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/all_care/**",
    "flutter_app/lib/features/health_tracking/domain/health_entry_series_closed.dart",
    "flutter_app/lib/features/health_tracking/domain/entities/health_entry.dart",
    "flutter_app/lib/features/health_tracking/domain/services/care_temporal_grouping_service.dart",
    "flutter_app/lib/features/care_item/domain/**",
    "flutter_app/lib/features/experience/presentation/care_item/occurrence/**",
    "flutter_app/test/features/care_item/presentation/detail/**",
    "e2e/playwright/tests/care.item.booster.spec.ts"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests"],
  "companions": ["server/routes/healthEntries/**"],
  "exit_checklist": [
    "Owner approved migration 085 merge on control issue",
    "Item status closed with care_closed_reason",
    "Audit-only stopped_by_user backfill",
    "Read-only detail hides pencil menu Edit schedule Needs attention",
    "Other care no finished archived recorded",
    "pre-push-changed green"
  ]
}
```
Scope: R-009–R-011, R-013 items, R-020, R-023, R-024.
Out of scope: Close care button, Closed care list footer.

### Phase 5 — Close care
```json
{
  "allowed_paths": [
    "server/lib/care/occurrence/commands/lifecycle.js",
    "server/routes/healthEntries/completionRouter.js",
    "server/lib/petAccess.js",
    "server/lib/care/planner/**",
    "server/lib/suggestions/**",
    "server/test/**",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_detail_screen.dart",
    "flutter_app/lib/features/health_tracking/presentation/widgets/pet_event_close_confirm_dialog.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_menu.dart",
    "flutter_app/lib/l10n/**",
    "flutter_app/test/features/care_item/**",
    "flutter_app/test/bdd/features/care_close.feature",
    "e2e/playwright/tests/care.close.spec.ts",
    "e2e/playwright/tests/care.a11y.spec.ts",
    "e2e/playwright/tests/away.*.spec.ts"
  ],
  "forbidden_paths": ["server/scripts/migrations/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [],
  "exit_checklist": [
    "Owner-only close R-015",
    "Dialog Record them first R-016",
    "R-018 close date matrix",
    "CIM verify R-025",
    "reopen removed",
    "pre-push-changed green"
  ]
}
```
Scope: Close care UX and server command; away and CIM; owner-only.
Out of scope: Closed care list screen, canonical fold.

### Phase 6 — Closed care list and canonical docs
```json
{
  "allowed_paths": [
    "flutter_app/lib/core/router/**",
    "flutter_app/lib/l10n/**",
    "flutter_app/lib/features/experience/presentation/pet_profile/widgets/all_care/**",
    "flutter_app/lib/features/experience/presentation/**/closed*",
    "docs/domains/pet_care/**",
    "flutter_app/test/bdd/features/care_close.feature",
    "e2e/playwright/tests/care.close.spec.ts",
    "e2e/playwright/tests/care.agenda.spec.ts"
  ],
  "forbidden_paths": [".github/workflows/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": ["server/routes/healthEntries/**"],
  "exit_checklist": [
    "Closed care link and list no dates R-021",
    "Canonical docs fold care-item-evolution and CSM",
    "Delete care-status-model-spec and delivery plan change docs",
    "check_docs_canonical green",
    "pre-push-changed green"
  ]
}
```
Scope: R-021 list UX; fold canonical docs.
Out of scope: New scheduling behaviour.

## Proof on UAT

On UAT: create or use seeded Fixed-schedule care with a missed dose; confirm History shows
**Not recorded** (not Skipped). After slice 5: owner closes care with overdue dates; confirm
**Closed care** list entry without dates and read-only details. Carer account must not see Close care.
