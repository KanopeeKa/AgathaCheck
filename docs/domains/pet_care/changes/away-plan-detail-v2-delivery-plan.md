---
title: Away Plan Detail V2 — Delivery Plan
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-22
tags: [pet_care, care_context, away_planning, delivery]
---

# Away Plan Detail V2 — Delivery Plan

**Canonical product behaviour (V1):** [care-context.md](../features/care-context.md) — update in AWD-5.
**Frozen decisions:** [away-plan-detail-v2-decisions.md](./away-plan-detail-v2-decisions.md)
**Execute-plan:** `.agents/plans/away-plan-detail-v2.md`

**Status: active** — decisions frozen 2026-09-22 after two chat review rounds; implementation authorized.

**Reviewed 2026-09-22 (round 1):** contract-edge gaps in the unified list (wire shape, sort/dedupe, `anchor_kind`), draft copy, an icon-helper fix, an allowed-path overlap, and snapshot placeholder hygiene were resolved in the decisions doc and reflected below and in the execute-plan files.

**Reviewed 2026-09-22 (round 2):** no further blocking findings. Added below: an integration-branch shipping gate for the AWD-2→AWD-3 window.

## Programme goal

Redesign the Away Plan detail screen shipped in Away Planning V1: replace the Routine/Dated/Indeterminate three-way split with one unified, tappable "Planned care" list; make the carer/care coverage summary attention-only; split the screen into a read-only display view and a new edit screen (notes + delete) that follows the app's standard edit-screen convention; add pet photos with tap-through. Scheduling semantics (Care Schedule Management) are untouched — this is a read-side regrouping plus a UI/UX pass, same boundary V1 held.

---

## Shipping gates

1. **AWD-DOC-0** merges first — decisions must be reviewed/frozen before any implementation phase starts (they change a frozen V1 decision, D-AWAY-006's grouping key, and partially supersede D-AWAY-002).
2. **AWD-2** before **AWD-3** — the unified list needs the new wire contract before the widget can render it.
3. **AWD-1** and **AWD-4** have no dependency on AWD-2/AWD-3 and run in parallel with them.
4. **AWD-5** (docs + BDD/journey) ships last — it documents the shape all other phases produced.
5. Projection corpus (Care Schedule Management) must stay byte-identical through AWD-2 — same guarantee V1's AW-3 made; this plan only regroups read-side output, never re-derives occurrences.
6. **(added per review round 2) Integration-branch red window:** after AWD-2 merges to the integration branch and before AWD-3 merges, the Flutter client on that branch expects the old `routine_items`/`dated_items`/`uncertainties` fields AWD-2 just removed — it will fail to parse or render the pet-care section. Expected for a stacked-phase branch, not a regression to chase. Do not open the integration→`main` PR until AWD-3 (and AWD-1, AWD-4, AWD-5) are merged; this window is internal to the integration branch and never reaches `main`.

Integration branch (4 phases run in parallel after AWD-DOC-0): `cursor/away-plan-detail-v2-integration-d4c1`.

---

## Phase table

| Phase | Outcome | Depends on |
|---|---|---|
| **AWD-DOC-0** | Decisions reviewed/frozen; this delivery plan; execute-plan files | — |
| **AWD-1** | Plan-page carer/care coverage summary becomes attention-only (D-AWD-001) | AWD-DOC-0 |
| **AWD-2** | Backend: single `planned_care_items[]` array (replaces `routine_items`/`dated_items`/`uncertainties`) grouped by `health_entry_id` across all frequencies; `kind` discriminant, `times_of_day[]`, `frequency`/`frequency_interval`, `next_due_date` on the wire, server-side sorted (D-AWD-002, D-AWD-003) | AWD-DOC-0 |
| **AWD-3** | Flutter: single "Planned care" list rendering the new contract; `CareFamilyIcon` per row; tap-through to Care Item Detail; pet photo + tap-through on both per-pet sections; PDF handover lines updated to match (shared copy layer) (D-AWD-004, D-AWD-005, D-AWD-006) | AWD-2 |
| **AWD-4** | Display screen read-only; new edit screen (notes + delete) using `AppFormStickyActionsBar` / `AppFormDestructiveButton`; `cancelPlannedAbsence` repository method wired to existing `POST /:id/cancel` (D-AWD-007) | AWD-DOC-0 |
| **AWD-5** | `care-context.md` updated; BDD scenario(s) for edit/delete + unified list; Playwright spec; api-reference.md updated for the new coverage/projection response fields | AWD-1, AWD-2, AWD-3, AWD-4 |

```text
AWD-DOC-0
   ├── AWD-1 ─────────────────────────┐
   ├── AWD-2 ──> AWD-3 ────────────────┼──> AWD-5
   └── AWD-4 ─────────────────────────┘
```

**File ownership (parallel AWD-1 / AWD-2 / AWD-4):** AWD-1 touches only `away_plan_header_section.dart` — it wraps existing `Text` calls in a conditional on already-existing `readiness` fields, no copy-function change, so `away_plan_copy.dart` isn't in its path; AWD-2 is backend-only (`server/**`); AWD-4 touches the plan screen + a new edit screen + note-section split, not the pet-care-section files AWD-3 will later touch. AWD-3 starts only after AWD-2 merges to the integration branch, to avoid rebasing a wire-contract change mid-flight. **(revised per review round 1):** `away_plan_copy.dart` was originally listed in both AWD-1's and AWD-3's `allowed_paths` — neither phase actually edits it (AWD-3's copy lives in `away_plan_schedule_copy.dart`), so it's removed from both rather than resolved as an overlap.

---

## AWD-DOC-0 — Plan bootstrap

Review and freeze D-AWD-001–007 in [away-plan-detail-v2-decisions.md](./away-plan-detail-v2-decisions.md); this delivery plan; `.agents/plans/away-plan-detail-v2.{md,snapshot.json}`; open control issue; confirm scope boundaries (carer-edit dialog and dates/pets editing explicitly out of scope, D-AWD-007). Specific items this phase confirms (all drafted already, not blank):

- `planned_care_items[]` wire shape, `kind` discriminant, sort/dedupe rules (D-AWD-002)
- `[proposed]` ARB copy table in D-AWD-003 (wording confirmed by user 2026-09-22: "Repeats" over "Occurs") and its FR strings
- The two V1 amendment blocks in [away-planning-decisions.md](./away-planning-decisions.md) (D-AWAY-002, D-AWAY-006, D-AWAY-007) read correctly once D-AWD-001–003 are frozen

---

## AWD-1 — Attention-only coverage summary

One outcome: `AwayPlanHeaderSection` shows the carer-coverage line only when not every pet has a carer, and the care-coverage line only when there's something to review or timing is indeterminate.

| Item | Action |
|---|---|
| `AwayPlanHeaderSection` | Wrap each `Text` block (title + summary) in a conditional on `readiness.carerCoverage.state` / `readiness.careCoverage.coverageState` per D-AWD-001 |
| Widget tests | Cover all 3 carer states × 5 coverage states → assert line presence/absence (same matrix shape V1's D-AWAY-002 tests used) |
| Dashboard tile, PDF | **No change** — explicitly out of scope for this phase |

**Not AWD-1:** any icon/severity/colour treatment on the remaining lines — copy-only change.

---

## AWD-2 — Unified care-event contract (backend)

One outcome: the coverage/projection read path returns **one array**, `planned_care_items[]` per pet, one row per care event, server-sorted — replacing `routine_items`/`dated_items`/`uncertainties` outright (no compat shim; not in production, see decisions doc §Context).

| Item | Action |
|---|---|
| `server/lib/recurrenceHelper.js#splitRoutineAndDatedItems` | Rework into a single-array builder. Group key becomes `health_entry_id` only (drop `\|timeKey`); extend grouping to every repeating `frequency`, not just `daily`; `frequency === 'once'` stays ungrouped |
| `kind` discriminant | `recurring_calendar` / `recurring_chain` / `single_once` / `indeterminate_pending`, derived from `recurrence_anchor` (`RECURRENCE_ANCHOR_FROM_DUE_DATE` / `RECURRENCE_ANCHOR_FROM_COMPLETION`, `recurrenceAnchorDefaults.js`) + whether the entry has a materialised occurrence in the window. One field — do not also add a separate `anchor_kind` |
| Group row shape (`recurring_calendar`/`recurring_chain`) | `health_entry_id`, `name`, `type`, `care_family`, `frequency`, `frequency_interval`, `times_of_day: string[]` (distinct, sorted), `certainty` (least-certain-wins, D-AWAY-006 unchanged), `occurrence_count`, `status_counts`, `first_scheduled_date`, `last_scheduled_date` |
| `next_due_date` | Earliest pending occurrence date; computed only when `kind === 'recurring_calendar'` and `times_of_day.length <= 1`; else `null` |
| Dedupe | One row per `health_entry_id`. A `from_completion` entry with both materialised and pending occurrences in-window → one `recurring_chain` row, never split |
| Sort | Server-side: `kind` bucket order (`recurring_calendar` → `recurring_chain` → `single_once` → `indeterminate_pending`), then `name.localeCompare()` within bucket — screen and PDF both consume this order, neither re-sorts |
| `server/lib/care/awayPlan/presentation.js` (or nearest read-model boundary) | Merge former `routine_items`/`dated_items`/`uncertainties` builders into the single `planned_care_items[]` builder; enrichment (`name`/`type`/`care_family`, plus `frequency`/`frequency_interval` for `recurring_chain` rows) happens here, feeding D-AWD-003's "repeats every N, from completion" copy without a second lookup |
| `server/test/careContext/**`, `server/test/careSchedule/**` | Explicit cases, not just a fuzz matrix: (1) twice-daily med → one row, `times_of_day: ['08:00','20:00']`, `next_due_date: null`; (2) weekly entry spanning 2 occurrences in-window → one `recurring_calendar` row, not two; (3) `frequency: 'once'` × 3 distinct entries → 3 rows, never grouped; (4) `from_completion` entry with 1 materialised + 1 pending occurrence in-window → exactly one `recurring_chain` row; (5) sort order asserted across a mixed-kind fixture |
| `docs/architecture/api-reference.md` | Document `planned_care_items[]` replacing the three old fields — this is a breaking response shape change, called out explicitly, not folded into a changelog line |

**Not AWD-2:** any change to `projectSchedule.js` occurrence materialisation, CSM ledger, or write paths. Projection corpus byte-identical (verify with existing corpus test).

---

## AWD-3 — Unified "Planned care" list (Flutter)

One outcome: `AwayPlanPetCareSection` renders one "Planned care" list from the AWD-2 contract; PDF handover lines stay consistent with the same data.

| Item | Action |
|---|---|
| `care_period_coverage.dart` (domain) + data model | Replace the routine/dated/uncertainty entity split with one `PlannedCareItem` type carrying `kind`, `healthEntryId`, `name`, `type`, `careFamily`, `frequency`, `frequencyInterval`, `timesOfDay`, `nextDueDate`, plus the existing date/status/reason fields per `kind` — matches AWD-2's single-array wire shape |
| `away_plan_schedule_copy.dart` | Replace `routineRowTitle/Subtitle`, `datedRowStatus`, `indeterminateRowSubtitle` with one formatter switching on `item.kind`, producing the D-AWD-004 row template using the ARB keys drafted in D-AWD-003 |
| `away_plan_pet_care_section.dart` | Single list, single "Planned care" heading (`awayPlanningScheduleDatedTitle` repurposed); render `planned_care_items[]` in the order the server sent it (**no client-side sort or merge**); `CareFamilyIcon.forWire(type: item.type, careFamily: item.careFamily)` per row (new named constructor, see below — retires hardcoded `Icons.repeat`/`check_circle_outline`/`help_outline`); one `awayPlanningChainAnchorExplainer` line per pet section when any item is `recurring_chain`/`indeterminate_pending` (D-AWD-003); row wrapped in `InkWell`/`ListTile` → `context.goNamed('petEventView', pathParameters: {petId, entryId: item.healthEntryId})` |
| `care_family_icon.dart` | Add `CareFamilyIcon.forWire({required String? type, required String? careFamily, double size, bool showChip})` — mirrors `.forEntry`'s inference/custom-glyph logic from wire strings instead of a `HealthEntry`. **Do not** use `.materialIconFor(...)` directly on this screen — it skips custom glyphs `.forEntry` gets elsewhere (dental/wellness) |
| Pet header (`away_plan_pet_care_section.dart`) | `CareEventRowPetAvatar`-pattern 32px photo + tap → `context.goNamed('petDetail', pathParameters: {petId})`, whole header row (no other tap targets there) |
| Pet row (`away_plan_carers_section.dart`) | Same avatar, but **AW-11 (merged same day) added a second `IconButton` to `_CarerRow`** (edit carer + download per-pet PDF) — wrap only the avatar+name in the tap target, not the whole row |
| `away_plan_handover_controller.dart` / `away_plan_handover_service.dart` | **Rebase note:** AW-11 already reworked these for per-pet export (`AwayPlanHandoverPetSection.petNote`, `_buildDocument(petFilter:)`, pet-scoped `carerCoverageSummary`/`careCoverageSummary` via `AwayPlanCopy.petCarerCoverageSummary`/`petCareCoverageSummary`) — read current content first. In `_buildDocument`, replace only the `routineLines`/`datedLines`/`indeterminateLines` construction (still built from `coverage.routineItems`/`datedItems`/`uncertainties`, i.e. the fields AWD-2 removes) with one `plannedCareLines` built from `coverage.plannedCareItems` via the same `item.kind` formatter AWD-3 adds to `away_plan_schedule_copy.dart`. Leave `petNote`, `petFilter`, and the pet-scoped summary calls untouched — same data, same copy layer as the screen, so PDF and screen cannot drift. **Call the PDF delta out explicitly in the AWD-3 PR description** — it's a PDF content change riding inside a "Flutter UI" phase and reviewers should not assume UI-only |
| ARB (`app_en.arb`, `app_fr.arb`) | Add the 6 keys drafted in D-AWD-003 (EN + FR); retire `awayPlanningScheduleRoutineTitle`/`…IndeterminateTitle` as section headings (check for other call sites before deleting) |
| Widget/golden tests | Row-template matrix for all 4 `kind` values (mirrors AWD-2's backend matrix); **carer-perspective test:** a pending `single_once`/`recurring_calendar` item's due date is readable from the row alone, without tapping through (D-AWD-004, strengthened per review); tap targets ≥48×48; semantic labels on the new tappable rows (accessibility.mdc) |

**Not AWD-3:** removing per-occurrence completion visibility entirely — it moves one tap away (Care Item Detail), not gone; flag in PR description as the accepted trade-off from the review.

---

## AWD-4 — Display/edit screen split

One outcome: `PlannedAbsencePlanScreen` is read-only; a new edit screen owns the note and delete.

| Item | Action |
|---|---|
| `planned_absence_plan_screen.dart` | Add "Edit" `IconButton` in app bar (disabled when cancelled, same guard as the PDF button); remove reliance on inline note editing |
| `away_plan_handover_note_section.dart` | Split into a read-only display variant (shows note text or nothing, no `TextField`) and reuse the existing editable variant inside the new edit screen |
| New `planned_absence_edit_screen.dart` at route `petCarePlannedAbsenceEdit` → `/pc/away/:id/edit` | `AppFormStickyActionsBar` (Save) on phone / inline row on tablet; note field; `AppFormDestructiveButton` → confirm dialog → `cancelPlannedAbsence` → navigate to `/pc/away`; `PopScope` + `confirmDiscardFormChanges` for unsaved note edits |
| `care_context_repository.dart` / `_impl.dart` / `care_context_remote_datasource.dart` | Add `cancelPlannedAbsence(absenceId)` calling existing `POST /api/careContext/plannedAbsences/:id/cancel` — **no backend change** |
| `away_routes.dart` / `app_router.dart` | Register the new edit route, mirroring the existing `/pc/away/new`, `/pc/away/:id` pattern |
| Widget tests | Display screen has no Save button and no editable note field; edit screen has Save + Delete, discard-guard fires on unsaved note changes, delete confirms then cancels then navigates home; **after a successful delete, the hub's absence list (`plannedAbsencesListProvider` or equivalent) is invalidated and the absence no longer shows as active there** — made an explicit exit criterion per review round 1, not just "verify at implementation" |

**Explicitly not AWD-4:** carer-edit dialog (`away_plan_carer_edit_dialog.dart`) stays on the display screen, unchanged; no absence dates/pets editing added (doesn't exist today, wasn't requested).

---

## AWD-5 — Docs + journey

`care-context.md` updated for the unified event model and the new edit screen; `away-plan-detail-v2-decisions.md` statuses flipped from Proposed to Frozen (post-merge); `docs/architecture/api-reference.md` finalised for the AWD-2 contract fields (draft written in AWD-2, confirmed here against the shipped shape).

**BDD: three separate scenarios, not one bundled one** (per review round 1 — atomic BDD, mirrors atomic-pr.mdc's "one outcome" principle applied to test scenarios):

1. Attention-only coverage header (AWD-1 behaviour) — carer/care lines present/absent per state.
2. Unified Planned care list + tap-through to Care Item Detail (AWD-2/AWD-3 behaviour).
3. Edit screen save/delete flow (AWD-4 behaviour).

Each gets its own Gherkin scenario in `flutter_app/test/bdd/features/` and matching Playwright spec with `@bdd` header, exact title match to the Gherkin `Scenario:` line, per `bdd-journey` exit checklist.
