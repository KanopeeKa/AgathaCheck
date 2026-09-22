---
title: Away Plan Detail V2
plan_id: away-plan-detail-v2
---

# Away Plan Detail V2

| Field | Value |
|-------|-------|
| **plan_id** | `away-plan-detail-v2` |
| **title** | Away Plan Detail V2 (AWD-DOC-0 through AWD-5) |
| **base_branch** | `cursor/away-plan-detail-v2-integration-d4c1` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Redesign the Away Plan detail screen from Away Planning V1: one unified, tappable "Planned care" list (replaces Routine/Dated/Indeterminate); attention-only carer/care coverage summary; read-only display screen + new edit screen (notes, delete) on the app's standard edit-screen pattern; pet photo + tap-through. Scheduling stays with CSM — read-side only.

**Canonical docs:** `docs/domains/pet_care/changes/away-plan-detail-v2-delivery-plan.md`
**Proposed decisions:** `docs/domains/pet_care/changes/away-plan-detail-v2-decisions.md` (**not yet reviewed — status: proposed**)

## Autonomy

**DRAFT — not yet approved.** Do not run `/execute-plan away-plan-detail-v2`. Fields below are placeholders per execute-plan §Before autonomy grant steps 1–3; steps 4–6 (open control issue, human review, `approve-autonomous away-plan-detail-v2`) have not happened.

| Field | Value |
|-------|-------|
| **approved_at** | TBD |
| **approved_until** | TBD (`approved_at + 48h` once granted) |
| **approved_by** | TBD |
| **autonomy** | `draft` |
| **control_issue** | TBD — open before requesting approval |

**Blocking on approval:** D-AWD-001–007 in the decisions doc must move from Proposed to Frozen first — AWD-DOC-0's own exit criteria is that review.

## Phases

**AWD-1, AWD-2, AWD-4 parallel after AWD-DOC-0. AWD-3 waits on AWD-2 (needs the new wire contract). AWD-5 last.**

### Phase awd-doc-0 — Plan bootstrap

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-doc0-d4c1` |
| **spawn_allowed** | `false` |

**allowed_paths:** `docs/domains/pet_care/**`, `.agents/plans/away-plan-detail-v2.*`

**Exit criteria:**

- [ ] D-AWD-001–007 reviewed and Frozen (or revised and re-reviewed)
- [ ] Scope boundaries confirmed: carer-edit dialog and absence dates/pets editing stay out of scope
- [ ] Control issue opened with labels `execute-plan`, `plan:away-plan-detail-v2`
- [ ] `node scripts/validate_execute_plan_snapshot.js .agents/plans/away-plan-detail-v2.snapshot.json` passes with real `approved_at`/`approved_until`/`control_issue` filled in

### Phase awd-1 — Attention-only coverage summary

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd1-d4c1` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_header_section.dart`, `flutter_app/lib/features/pet_care/context/presentation/away_plan_copy.dart`, `flutter_app/lib/l10n/**`, `flutter_app/test/features/pet_care/context/**`

**Exit criteria:**

- [ ] Carer-coverage line hidden when `all_have_carers`
- [ ] Care-coverage line hidden for `nothing_scheduled` / `all_completed` / `no_unresolved_items`
- [ ] Both lines still render for the remaining states, unchanged copy
- [ ] Matrix widget tests (3 carer states × 5 coverage states)
- [ ] Dashboard tile and PDF untouched (diff check)

### Phase awd-2 — Unified care-event contract (backend)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd2-d4c1` |

**allowed_paths:** `server/lib/recurrenceHelper.js`, `server/lib/care/awayPlan/**`, `server/routes/careContext/carePeriodCoverageRouter.js`, `server/routes/careContext/carePeriodProjectionRouter.js`, `server/test/careContext/**`, `server/test/careSchedule/**`, `docs/architecture/api-reference.md`

**Exit criteria:**

- [ ] Grouping key is `health_entry_id` only, across all repeating frequencies; `once` stays ungrouped
- [ ] `times_of_day[]`, `frequency`, `frequency_interval`, `next_due_date`, `anchor_kind` present on the wire
- [ ] `next_due_date` is `null` whenever `times_of_day.length > 1`
- [ ] Certainty collapse rule (least-certain-wins) unchanged for grouped rows
- [ ] CSM projection corpus byte-identical
- [ ] `api-reference.md` documents new/changed fields

### Phase awd-3 — Unified "Planned care" list (Flutter)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd3-d4c1` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_pet_care_section.dart`, `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_carers_section.dart`, `flutter_app/lib/features/pet_care/context/presentation/away_plan_schedule_copy.dart`, `flutter_app/lib/features/pet_care/context/presentation/away_plan_copy.dart`, `flutter_app/lib/features/pet_care/context/domain/entities/care_period_coverage.dart`, `flutter_app/lib/features/pet_care/context/data/models/**`, `flutter_app/lib/features/pet_care/context/data/datasources/care_context_remote_datasource.dart`, `flutter_app/lib/features/pet_care/context/presentation/controllers/away_plan_handover_controller.dart`, `flutter_app/lib/features/pet_care/context/data/services/away_plan_handover_service.dart`, `flutter_app/lib/l10n/**`, `flutter_app/test/features/pet_care/context/**`

**Exit criteria:**

- [ ] Single "Planned care" heading and list per pet; `CareFamilyIcon` per row
- [ ] Row template matches D-AWD-004 for all four branches (calendar-recurring, chain-recurring, single-care, indeterminate-fallback)
- [ ] Row tap → `petEventView` route with correct `petId`/`entryId`
- [ ] Pet header photo + tap → `petDetail` route, both per-pet sections
- [ ] PDF handover lines match the same unified data (no drift between screen and PDF)
- [ ] Touch targets ≥48×48; semantic labels on new tappable rows
- [ ] `flutter analyze` clean; widget/golden test matrix green

### Phase awd-4 — Display/edit screen split

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd4-d4c1` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_plan_screen.dart`, `flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_edit_screen.dart`, `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_handover_note_section.dart`, `flutter_app/lib/features/pet_care/context/domain/repositories/care_context_repository.dart`, `flutter_app/lib/features/pet_care/context/data/repositories/care_context_repository_impl.dart`, `flutter_app/lib/features/pet_care/context/data/datasources/care_context_remote_datasource.dart`, `flutter_app/lib/core/router/away_routes.dart`, `flutter_app/lib/core/router/app_router.dart`, `flutter_app/lib/l10n/**`, `flutter_app/test/features/pet_care/context/**`

**allowed_exceptions:** `file-split` (splitting the note section into display/edit variants)

**Exit criteria:**

- [ ] Display screen: no Save button, no editable note field, note shown read-only when present, Edit icon in app bar (disabled when cancelled)
- [ ] Edit screen at `/pc/away/:id/edit`: `AppFormStickyActionsBar` (phone) / inline actions (tablet), `AppFormDestructiveButton` + confirm dialog for delete, `PopScope` discard guard
- [ ] `cancelPlannedAbsence` wired to existing `POST /:id/cancel`, no new backend endpoint
- [ ] Delete confirms → cancels → navigates to `/pc/away`
- [ ] Carer-edit dialog and dates/pets editing untouched (diff check)

### Phase awd-5 — Docs + journey

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd5-d4c1` |

**allowed_paths:** `docs/domains/pet_care/**`, `docs/architecture/api-reference.md`, `flutter_app/test/bdd/**`, `e2e/playwright/**`

**Exit criteria:**

- [ ] `care-context.md` reflects unified event model + edit screen
- [ ] Decisions doc statuses flipped Proposed → Frozen
- [ ] BDD scenario(s) + matching Playwright spec(s) with `@bdd` header, exact title match
- [ ] `node e2e/scripts/check_bdd_coverage.js` run (report-only, no regression)

## Runtime state

```yaml
autonomy: draft
current_phase: null
last_completed_phase: null
halt_reason: null
next_action: "awaiting decision review (AWD-DOC-0) before approval"
artifact_ref:
  branch: null
  plan_path: .agents/plans/away-plan-detail-v2.md
  plan_commit: null
  snapshot_path: .agents/plans/away-plan-detail-v2.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
