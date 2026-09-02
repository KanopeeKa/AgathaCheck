---
title: Health occurrences scheduling plan
plan_id: health-occurrences-ec83
---

# Health occurrences scheduling

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `health-occurrences-ec83` |
| **title** | Health occurrence scheduling (multi-dose + stack UX) |
| **author** | cloud-agent |
| **created** | 2026-09-02 |
| **base_branch** | `cursor/health-occurrences-integration-ec83` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Introduce first-class `health_occurrences` so carers can track multiple doses per day with calm list triage (`CareEventRow` + stack sheet) and a detailed event-view workbench. Backend materialisation, Flutter UI, and E2E coverage ship in five phases on an integration branch, then one PR to `main`.

**Design reference:** `docs/domains/health_tracking/changes/occurrence-scheduling.md` · `/ui-design-deep`

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-02T10:00:00Z |
| **approved_until** | 2026-09-04T10:00:00Z |
| **control_issue** | #811 |
| **content_hash** | from snapshot |
| **autonomy** | `active` |

**Grant keyword:** user chat 2026-09-02 — `/execute-plan` + `/ui-design-deep` standing grant

## Phases

### Phase 1 — Domain spec, DB, backend API

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/health-occurrences-backend-ec83` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
docs/domains/health_tracking/changes/occurrence-scheduling.md
db/migrations/**
server/lib/occurrence*
server/lib/recurrenceHelper.js
server/routes/healthEntries/**
server/test/healthEntries/**
server/test/occurrence*
scripts/migrations/**
```

**forbidden_paths:**

```
flutter_app/**
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `backend-route`

**Scope:**

- Finalise occurrence-scheduling spec (already drafted)
- Migration: `health_occurrences` + `schedule_times` on `health_entries`
- Materialisation service (once / ≤1× day / >1× day rules; anchor = today)
- Occurrence routes: list, complete, skip, skip-missed, undo
- `is_missed` server helper; legacy `mark-taken` delegates to oldest pending
- Jest coverage; dev data cleanup script for stale `next_due_date` rows

**Exit criteria:**

- [ ] Migration applies cleanly
- [ ] Jest green for occurrence CRUD + materialisation
- [ ] Spec matches implemented API

---

### Phase 2 — Flutter data layer + schedule form

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/health-occurrences-data-form-ec83` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/health_tracking/domain/**
flutter_app/lib/features/health_tracking/data/**
flutter_app/lib/features/health_tracking/presentation/providers/**
flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_form/**
flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart
flutter_app/lib/features/health_tracking/presentation/controllers/**
flutter_app/lib/core/utils/calendar_date.dart
flutter_app/lib/l10n/**
flutter_app/test/features/health_tracking/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`, `backend-route`

**Scope:**

- `HealthOccurrence` entity + model + repository
- `occurrenceSummaryProvider`, local `isMissed` helper (device TZ)
- Schedule form: checkbox “Schedule at specific times”, time rows, add/remove
- Wire create/edit to `schedule_times` API
- Unit tests for summary + form

**Exit criteria:**

- [ ] Can create 2× daily entry with times via form
- [ ] Provider returns zone counts and heads
- [ ] flutter analyze + unit tests pass

---

### Phase 3 — List triage: CareEventRow + stack sheet

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/health-occurrences-list-stack-ec83` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/health_tracking/presentation/widgets/care_event_*
flutter_app/lib/features/health_tracking/presentation/widgets/occurrence_*
flutter_app/lib/features/experience/presentation/**
flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/**
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_events_preview_section.dart
flutter_app/test/features/health_tracking/presentation/widgets/**
flutter_app/test/features/experience/**
docs/design/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope (ui-design-deep):**

- Occurrence-aware `CareEventRow` status lines
- `OccurrenceStackSheet` with Missed LIFO / Coming up FIFO zones
- Opt-in checkbox skip earlier missed; Skip all missed; Review → event view route
- Wire dashboard preview, `/g/events`, pet due section
- Remove snooze from list-adjacent flows touched in this phase

**Exit criteria:**

- [ ] Stack sheet shows when `open > 1` OR `missed >= 1`
- [ ] List row shows missed/latest headline per spec
- [ ] Widget tests for stack sheet + row

---

### Phase 4 — Event view workbench

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/health-occurrences-event-view-ec83` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/health_tracking/presentation/widgets/pet_event_*
flutter_app/lib/features/health_tracking/presentation/screens/pet_event_view_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/home_event_actions.dart
flutter_app/test/features/health_tracking/presentation/screens/pet_event_view_screen_test.dart
docs/design/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope (ui-design-deep):**

- Replace single next-occurrence block with zoned open occurrence list
- Per-row Mark done / Skip; footer Skip all missed
- Past occurrences section (LIFO)
- Remove snooze from event view
- Deep link scroll target for stack “Review each dose”

**Exit criteria:**

- [ ] Event view lists open occurrences in correct zones/sorts
- [ ] Per-occurrence actions work end-to-end against API
- [ ] Snooze removed from event view

---

### Phase 5 — BDD, E2E, integration → main

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/health-occurrences-e2e-ec83` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
e2e/playwright/tests/health.tracking.spec.ts
e2e/playwright/pages/**
e2e/playwright/support/api.ts
flutter_app/test/bdd/features/health_tracking.feature
docs/domains/health_tracking/**
.agents/plans/health-occurrences-ec83.*
```

**forbidden_paths:**

```
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `bdd-journey`

**Scope:**

- Gherkin: 2× daily medication + stack skip scenario
- Playwright: create timed entry, mark dose, stack sheet, event view review
- Open integration → `main` PR; babysit-uat

**Exit criteria:**

- [ ] BDD mapped + Playwright green locally
- [ ] Integration branch merged to `main` with pre-UAT gate

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "start phase 2: checkout cursor/health-occurrences-data-form-ec83"
artifact_ref:
  branch: cursor/health-occurrences-backend-ec83
  plan_path: .agents/plans/health-occurrences-ec83.md
  plan_commit: b19a65aa8facd052e877d0ee7d15edf3c4ef519f
  snapshot_path: .agents/plans/health-occurrences-ec83.snapshot.json
  snapshot_commit: b19a65aa8facd052e877d0ee7d15edf3c4ef519f
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check

**Output:** `proceed` — medium feature, clear phases, disjoint paths, no prod data risk.
