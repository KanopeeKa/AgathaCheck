---
title: Away Plan Detail V2 — Delivery Plan
owner: Product / Agent
audience: both
status: proposed
last_updated: 2026-09-22
tags: [pet_care, care_context, away_planning, delivery]
---

# Away Plan Detail V2 — Delivery Plan

**Canonical product behaviour (V1):** [care-context.md](../features/care-context.md) — update in AWD-5.
**Proposed decisions:** [away-plan-detail-v2-decisions.md](./away-plan-detail-v2-decisions.md)
**Execute-plan:** `.agents/plans/away-plan-detail-v2.md` (draft — not yet approved)

**Status: proposed** — decisions not yet reviewed/frozen. Do not run `/execute-plan away-plan-detail-v2` until D-AWD-001–007 are confirmed and a control issue exists (see execute-plan §Before autonomy grant).

## Programme goal

Redesign the Away Plan detail screen shipped in Away Planning V1: replace the Routine/Dated/Indeterminate three-way split with one unified, tappable "Planned care" list; make the carer/care coverage summary attention-only; split the screen into a read-only display view and a new edit screen (notes + delete) that follows the app's standard edit-screen convention; add pet photos with tap-through. Scheduling semantics (Care Schedule Management) are untouched — this is a read-side regrouping plus a UI/UX pass, same boundary V1 held.

---

## Shipping gates

1. **AWD-DOC-0** merges first — decisions must be reviewed/frozen before any implementation phase starts (they change a frozen V1 decision, D-AWAY-006's grouping key, and partially supersede D-AWAY-002).
2. **AWD-2** before **AWD-3** — the unified list needs the new wire contract before the widget can render it.
3. **AWD-1** and **AWD-4** have no dependency on AWD-2/AWD-3 and run in parallel with them.
4. **AWD-5** (docs + BDD/journey) ships last — it documents the shape all other phases produced.
5. Projection corpus (Care Schedule Management) must stay byte-identical through AWD-2 — same guarantee V1's AW-3 made; this plan only regroups read-side output, never re-derives occurrences.

Integration branch (4 phases run in parallel after AWD-DOC-0): `cursor/away-plan-detail-v2-integration-d4c1`.

---

## Phase table

| Phase | Outcome | Depends on |
|---|---|---|
| **AWD-DOC-0** | Decisions reviewed/frozen; this delivery plan; execute-plan files | — |
| **AWD-1** | Plan-page carer/care coverage summary becomes attention-only (D-AWD-001) | AWD-DOC-0 |
| **AWD-2** | Backend: unified care-event grouping by `health_entry_id` across all frequencies; `times_of_day[]`, `frequency`/`frequency_interval`, `next_due_date`, `anchor_kind` on the wire (D-AWD-002, D-AWD-003) | AWD-DOC-0 |
| **AWD-3** | Flutter: single "Planned care" list rendering the new contract; `CareFamilyIcon` per row; tap-through to Care Item Detail; pet photo + tap-through on both per-pet sections; PDF handover lines updated to match (shared copy layer) (D-AWD-004, D-AWD-005, D-AWD-006) | AWD-2 |
| **AWD-4** | Display screen read-only; new edit screen (notes + delete) using `AppFormStickyActionsBar` / `AppFormDestructiveButton`; `cancelPlannedAbsence` repository method wired to existing `POST /:id/cancel` (D-AWD-007) | AWD-DOC-0 |
| **AWD-5** | `care-context.md` updated; BDD scenario(s) for edit/delete + unified list; Playwright spec; api-reference.md updated for the new coverage/projection response fields | AWD-1, AWD-2, AWD-3, AWD-4 |

```text
AWD-DOC-0
   ├── AWD-1 ─────────────────────────┐
   ├── AWD-2 ──> AWD-3 ────────────────┼──> AWD-5
   └── AWD-4 ─────────────────────────┘
```

**File ownership (parallel AWD-1 / AWD-2 / AWD-4):** AWD-1 touches only `away_plan_header_section.dart` + `away_plan_copy.dart`; AWD-2 is backend-only (`server/**`); AWD-4 touches the plan screen + a new edit screen + note-section split, not the pet-care-section files AWD-3 will later touch. AWD-3 starts only after AWD-2 merges to the integration branch, to avoid rebasing a wire-contract change mid-flight.

---

## AWD-DOC-0 — Plan bootstrap

Review and freeze D-AWD-001–007 in [away-plan-detail-v2-decisions.md](./away-plan-detail-v2-decisions.md); this delivery plan; `.agents/plans/away-plan-detail-v2.{md,snapshot.json}`; open control issue; confirm scope boundaries (carer-edit dialog and dates/pets editing explicitly out of scope, D-AWD-007).

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

One outcome: the coverage/projection read path returns one row per care event (grouped by `health_entry_id`, all frequencies) instead of routine/dated/uncertainty buckets keyed inconsistently.

| Item | Action |
|---|---|
| `server/lib/recurrenceHelper.js#splitRoutineAndDatedItems` | Group key becomes `health_entry_id` only (drop `\|timeKey`); extend grouping to every repeating `frequency`, not just `daily`; `frequency === 'once'` stays ungrouped |
| Group row shape | Add `frequency`, `frequency_interval`, `times_of_day: string[]` (distinct, sorted), keep `certainty` (least-certain-wins, D-AWAY-006 unchanged), `occurrence_count`, `status_counts`, `first_scheduled_date`, `last_scheduled_date` |
| `next_due_date` | Earliest pending occurrence date; computed only when `times_of_day.length <= 1`; else `null` |
| `server/lib/care/awayPlan/presentation.js` (or nearest read-model boundary) | Add `anchor_kind: 'calendar' \| 'completion_chain'` per event, derived from existing certainty/reason data — **no new "how do we know" logic**, just labelling what's already computed |
| Uncertainties enrichment | Extend `enrichUncertainties` to carry `frequency`/`frequency_interval` when the underlying entry has a repeating cadence, so D-AWD-003's "every N days from the last occurrence" can render without a second lookup |
| `server/test/careContext/**`, `server/test/careSchedule/**` | New matrix: frequency × single-vs-multiple-times-of-day × calendar-vs-chain-anchor |
| `docs/architecture/api-reference.md` | Document the new/changed response fields on the coverage and projection endpoints |

**Not AWD-2:** any change to `projectSchedule.js` occurrence materialisation, CSM ledger, or write paths. Projection corpus byte-identical (verify with existing corpus test).

---

## AWD-3 — Unified "Planned care" list (Flutter)

One outcome: `AwayPlanPetCareSection` renders one "Planned care" list from the AWD-2 contract; PDF handover lines stay consistent with the same data.

| Item | Action |
|---|---|
| `care_period_coverage.dart` (domain) + data model | Add `frequency`, `frequencyInterval`, `timesOfDay`, `nextDueDate`, `anchorKind` fields matching AWD-2's wire shape |
| `away_plan_schedule_copy.dart` | Replace `routineRowTitle/Subtitle`, `datedRowStatus`, `indeterminateRowSubtitle` with one formatter producing the D-AWD-004 row template (recurring/calendar, recurring/chain, single-care, indeterminate-fallback branches) |
| `away_plan_pet_care_section.dart` | Single list, single "Planned care" heading (`awayPlanningScheduleDatedTitle` repurposed); `CareFamilyIcon.materialIconFor(...)` per row (retire hardcoded `Icons.repeat`/`check_circle_outline`/`help_outline`); one chain-anchor explainer line per pet section when applicable (D-AWD-003); row wrapped in `InkWell`/`ListTile` → `context.goNamed('petEventView', pathParameters: {petId, entryId: item.healthEntryId})` |
| Pet header (both `away_plan_pet_care_section.dart` and `away_plan_carers_section.dart`) | `CareEventRowPetAvatar`-pattern 32px photo + tap → `context.goNamed('petDetail', pathParameters: {petId})` |
| `away_plan_handover_controller.dart` / `away_plan_handover_service.dart` | Update line-building to consume the unified event list (drop separate routine/dated/indeterminate PDF sections; keep per-pet grouping) — same data, same copy layer as the screen, so PDF and screen cannot drift |
| ARB (`app_en.arb`, `app_fr.arb`) | New keys: occurs-every (calendar), occurs-every (chain), single-care, next-due-date, time-of-day, chain-anchor explainer; retire `awayPlanningScheduleRoutineTitle`/`…IndeterminateTitle` as section headings (may keep as internal identifiers if still referenced elsewhere — check before deleting) |
| Widget/golden tests | New row-template matrix (mirrors AWD-2's backend matrix); tap targets ≥48×48; semantic labels on the new tappable rows (accessibility.mdc) |

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
| Widget tests | Display screen has no Save button and no editable note field; edit screen has Save + Delete, discard-guard fires on unsaved note changes, delete confirms then cancels then navigates home |

**Explicitly not AWD-4:** carer-edit dialog (`away_plan_carer_edit_dialog.dart`) stays on the display screen, unchanged; no absence dates/pets editing added (doesn't exist today, wasn't requested).

---

## AWD-5 — Docs + journey

`care-context.md` updated for the unified event model and the new edit screen; `away-plan-detail-v2-decisions.md` statuses flipped from Proposed to Frozen (post-merge); BDD scenario(s) added/updated in `flutter_app/test/bdd/features/` for: unified list rendering, tap-through to Care Item Detail, edit screen save/delete flow; matching Playwright spec(s) with `@bdd` header; `docs/architecture/api-reference.md` finalised for the AWD-2 contract fields (draft written in AWD-2, confirmed here against the shipped shape).
