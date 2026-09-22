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

**Hard gate (added post-review):** `approve-autonomous away-plan-detail-v2` must not be granted while `approved_by` still reads "TBD" or `control_issue` in the snapshot is still its placeholder value (`999999999` — see snapshot; deliberately out of range so it can't be mistaken for a real GitHub issue). AWD-DOC-0's own exit criteria already requires the validator to pass with real values, so this is a restatement, not a new mechanism — called out explicitly per review round 1 so a fast-moving agent doesn't treat the placeholder-passing validator run as a green light.

**Branch suffix note:** `-d4c1` throughout is this draft's placeholder suffix. No fixed/reserved suffix is documented in this repo (`atomic-pr-policy.md`: "or your agent suffix") — the agent that actually executes this plan uses its own, same as every other plan in `.agents/plans/`. Re-point branch names at execution time if a different agent picks this up; the phase structure and file ownership don't depend on the exact suffix.

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

**Exit criteria:**

- [ ] Single "Planned care" heading and list per pet, rendered in server-sent order (no client sort/merge)
- [ ] `CareFamilyIcon.forWire(type:, careFamily:)` per row — not `.materialIconFor(...)` directly (must preserve custom-glyph handling `.forEntry` gets elsewhere)
- [ ] Row template matches D-AWD-004 for all four `kind` values (`recurring_calendar`, `recurring_chain`, `single_once`, `indeterminate_pending`)
- [ ] Chain-anchor explainer line renders once per pet section when any item is `recurring_chain`/`indeterminate_pending`, never per row
- [ ] Row tap → `petEventView` route with correct `petId`/`entryId`
- [ ] Pet header photo + tap → `petDetail` route, both per-pet sections
- [ ] PDF handover lines match the same unified data (no drift between screen and PDF) — PDF delta called out explicitly in PR description
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
