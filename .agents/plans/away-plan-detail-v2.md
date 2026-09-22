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

**APPROVED — implementation authorized.** Decisions frozen 2026-09-22 after two chat review rounds with no further blocking findings; user granted approval in chat ("Go ahead... create PR and make sure it merges, then check it passes e2e-preUAT workflow").

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-22T13:12:45Z |
| **approved_until** | 2026-09-24T13:12:45Z |
| **approved_by** | User chat 2026-09-22 — two review rounds, no further blocking findings; proceed through merge and e2e-preUAT verification |
| **autonomy** | `active` |
| **control_issue** | [#1270](https://github.com/KanopeeKa/AgathaCheck/issues/1270) |

**Branch suffix note:** `-d4c1` throughout. No fixed/reserved suffix is documented in this repo (`atomic-pr-policy.md`: "or your agent suffix").

**Execution note:** this session is Claude Code, not Cursor Cloud Agents — `.cursor/agent-kernel/`'s multi-agent `/execute-plan` orchestration (babysit-plus, GitHub Projects automation) is not available here (see `CLAUDE.md` §Notes for Claude Code specifically). Phases are executed directly: background implementation agents per phase, orchestrator (this session) merges to the integration branch as phases complete, verification via the repo's own scripts (`pre-push-changed.sh`, `pre-push.sh`, `check_file_size.js`) rather than a babysit skill. Same phase boundaries, exit criteria, and merge discipline as the plan below.

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

**allowed_paths:** `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_header_section.dart`, `flutter_app/test/features/pet_care/context/**`

*(Revised per review round 1: `away_plan_copy.dart` and `flutter_app/lib/l10n/**` dropped — this phase wraps existing `Text` calls in a conditional, no copy-function or ARB change.)*

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

- [ ] Response exposes a single `planned_care_items[]` array per pet; `routine_items`/`dated_items`/`uncertainties` removed (no compat shim — not in production)
- [ ] Each item has `kind` (`recurring_calendar`/`recurring_chain`/`single_once`/`indeterminate_pending`), derived from `recurrence_anchor` + materialisation state — no separate `anchor_kind` field
- [ ] Grouping key is `health_entry_id` only, across all repeating frequencies; `once` stays ungrouped
- [ ] `times_of_day[]`, `frequency`, `frequency_interval`, `next_due_date` present on the wire
- [ ] `next_due_date` is non-null only for `kind: recurring_calendar` with `times_of_day.length <= 1`
- [ ] One row per `health_entry_id` — a `from_completion` entry with both materialised and pending occurrences in-window yields exactly one `recurring_chain` row, never two
- [ ] Response is server-sorted: `kind` bucket order then `name`; Flutter must not need to re-sort
- [ ] Certainty collapse rule (least-certain-wins) unchanged for grouped rows
- [ ] Explicit test cases pass: twice-daily → 1 row/2 times/`next_due_date: null`; weekly ×2 occurrences → 1 row; 3× `once` entries → 3 rows; `from_completion` mixed materialised/pending → 1 row
- [ ] CSM projection corpus byte-identical
- [ ] `api-reference.md` documents the response shape as a breaking change (old fields removed, not deprecated)

### Phase awd-3 — Unified "Planned care" list (Flutter)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd3-d4c1` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_pet_care_section.dart`, `flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_carers_section.dart`, `flutter_app/lib/features/pet_care/context/presentation/away_plan_schedule_copy.dart`, `flutter_app/lib/features/pet_profile/presentation/widgets/care_family_icon.dart`, `flutter_app/lib/features/pet_care/context/domain/entities/care_period_coverage.dart`, `flutter_app/lib/features/pet_care/context/data/models/**`, `flutter_app/lib/features/pet_care/context/data/datasources/care_context_remote_datasource.dart`, `flutter_app/lib/features/pet_care/context/presentation/controllers/away_plan_handover_controller.dart`, `flutter_app/lib/features/pet_care/context/data/services/away_plan_handover_service.dart`, `flutter_app/lib/l10n/**`, `flutter_app/test/features/pet_care/context/**`

*(Revised per review round 1: `away_plan_copy.dart` dropped — schedule copy lives in `away_plan_schedule_copy.dart`, this phase doesn't touch carer/care coverage summary functions. Added `care_family_icon.dart` for the new `CareFamilyIcon.forWire` constructor.)*

*(AW-11 rebase note, 2026-09-22: `away_plan_handover_controller.dart`/`away_plan_handover_service.dart`/`away_plan_carers_section.dart` were reworked same-day by a parallel session for per-pet handover export — read current content before editing, don't restore the pre-AW-11 shape. Replace only `routineLines`/`datedLines`/`indeterminateLines` construction with unified `plannedCareLines`; leave `petNote`, `petFilter`, and pet-scoped summary calls (`AwayPlanCopy.petCarerCoverageSummary`/`petCareCoverageSummary`) untouched. `_CarerRow` now has 2 IconButtons — avatar tap target covers only avatar+name, not the whole row.)*

**Exit criteria:**

- [ ] Single "Planned care" heading and list per pet, rendered in server-sent order (no client sort/merge)
- [ ] `CareFamilyIcon.forWire(type:, careFamily:)` per row — not `.materialIconFor(...)` directly (must preserve custom-glyph handling `.forEntry` gets elsewhere)
- [ ] Row template matches D-AWD-004 for all four `kind` values (`recurring_calendar`, `recurring_chain`, `single_once`, `indeterminate_pending`)
- [ ] Chain-anchor explainer line renders once per pet section when any item is `recurring_chain`/`indeterminate_pending`, never per row
- [ ] Row tap → `petEventView` route with correct `petId`/`entryId`
- [ ] Pet header photo + tap → `petDetail` route (full row in `away_plan_pet_care_section.dart`; avatar+name only in `away_plan_carers_section.dart`, which has two other tap targets already)
- [ ] PDF handover lines match the same unified data for both full-plan and per-pet export (no drift between screen and PDF) — PDF delta called out explicitly in PR description
- [ ] `petNote` and per-pet coverage summaries (AW-11) render unchanged in both PDF variants
- [ ] Carer-perspective test: a pending `single_once`/`recurring_calendar` item's due date is readable from the row alone, without opening detail
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
- [ ] Delete confirms → cancels → navigates to `/pc/away`, and the hub's absence list provider is invalidated so the cancelled absence no longer shows as active there
- [ ] Carer-edit dialog and dates/pets editing untouched (diff check)

### Phase awd-5 — Docs + journey

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-plan-detail-v2-awd5-d4c1` |

**allowed_paths:** `docs/domains/pet_care/**`, `docs/architecture/api-reference.md`, `flutter_app/test/bdd/**`, `e2e/playwright/**`

**Exit criteria:**

- [ ] `care-context.md` reflects unified event model + edit screen
- [ ] Decisions doc statuses flipped Proposed → Frozen
- [ ] Three separate BDD scenarios (not bundled): attention-only header, unified list + tap-through, edit screen save/delete — each with matching Playwright spec, `@bdd` header, exact title match
- [ ] `node e2e/scripts/check_bdd_coverage.js` run (report-only, no regression)

## Runtime state

```yaml
autonomy: active
current_phase: null
last_completed_phase: awd-5
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/away-plan-detail-v2-integration-d4c1
  plan_path: .agents/plans/away-plan-detail-v2.md
  plan_commit: e0b21a87bcb65e63a2107ba359f7ec91e858ed0a
  snapshot_path: .agents/plans/away-plan-detail-v2.snapshot.json
  snapshot_commit: e0b21a87bcb65e63a2107ba359f7ec91e858ed0a
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
