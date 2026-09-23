---
title: Away Care Planning — Delivery Plan
owner: Product / Agent
audience: both
status: proposed
last_updated: 2026-09-23
tags: [pet_care, care_context, care_schedule_management, away_planning, delivery]
---

# Away Care Planning — Delivery Plan

**Decisions:** [away-care-planning-decisions.md](./away-care-planning-decisions.md) (D-ACP-001 … D-ACP-010)
**Canonical product behaviour today:** [care-context.md](../features/care-context.md), [care-schedule-management.md](../features/care-schedule-management.md)
**Predecessor plans:** [away-plan-detail-v2-delivery-plan.md](./away-plan-detail-v2-delivery-plan.md) (AWD, shipped), [care-schedule-management-delivery-plan.md](./care-schedule-management-delivery-plan.md) (CSM-1…17, on `main`)

**Status: proposed.** Written for review in Cursor. Nothing here is implemented. Execute-plan files (`.agents/plans/away-care-planning.{md,snapshot.json}`) are created in ACP-DOC-0 once this plan is frozen.

---

## 1. Introduction

### 1.1 Programme goal

> When a pet parent plans an absence, AgathaTrack shows **every care item that will need attention**: with its real date when one exists, an honest estimate when it does not, and a clear status. It then **helps the pet parent arrange care so as little as possible falls on the carer**, always as a suggestion they accept, never an automatic change.

This extends Care Through Change (programme promise: *"quietly help existing care continue through a declared change, while being honest about what it knows and what it cannot yet know"*).

### 1.2 Origin

User report (2026-09-23), using Buddy on the fred prevost profile, with an absence in progress:

- **Annual Rabies booster** shows only "date not known", although its occurrence is due and overdue.
- **Dental check** had a missed occurrence on 11 Sept and also shows "date not known".
- Titles show an unexplained `~` prefix.

The user then asked for three things:

1. A precise display contract for care during an absence.
2. Suggestions to reduce care during the absence.
3. Planning occurrence dates from inside the care item.

### 1.3 Product answers already given (2026-09-23)

| # | Question | Answer |
|---|---|---|
| 1 | Example arithmetic: every 7 days from Mon 1st → 8th / 22nd, not 7th / 21st | Correct: 8th and 22nd |
| 2 | Is the CSM-17 integration gate (D-CSM-008) done? | Yes, on `main`. A separate PR fixes the stale CSM status table |
| 3 | Moving a `from_due_date` occurrence re-anchors the following ones | Yes, wanted (→ D-ACP-007) |
| 4 | Medication is `fixed`; vaccinations are `earlier_only` | Agreed (→ D-ACP-006) |
| 5 | Planner is deterministic, in Care Context, not CIM | Agreed. It must be a clearly bounded component (→ D-ACP-008, §6) |
| 6 | Fixed dates two or more occurrences ahead | Dropped for now (→ D-ACP-010) |
| 7 | "Due before you leave" instead of predicted "overdue at start" | Yes (→ D-ACP-004) |

### 1.4 Principles applied (True North / repo policy)

- **Honest certainty (#2, #9):** every date says what it is: scheduled, planned or estimated. There is no false certainty and no false uncertainty.
- **Parent stays in control (#10):** the planner only proposes; flexibility never blocks a manual change.
- **Single source of truth:** the server computes dates, statuses and suggestions. Flutter renders and never re-derives (same rule as D-AWD-002).
- **One primitive per real-world action:** accepting a suggestion *is* a reschedule, through the existing CSM route.
- **Atomic PRs, ≤500-line files, BDD for journeys:** see phase exit criteria.

---

## 2. Context: the codebase today (verified on `main` @ `6e23f0d`)

| Area | Current state | Consequence |
|---|---|---|
| `projectEntryForPeriod` (`server/lib/care/schedule/projectSchedule.js:124`) | `from_completion` + any pending occurrence → uncertainty and **no items**. `from_due_date` → cursor skips overdue dates. Only in-window occurrences are materialised as items | Rabies and Dental show "date not known". An overdue `from_due_date` item **vanishes** entirely |
| Corpus `server/test/careContext/carePeriodProjectionCorpus.js:495` | `from-completion-overdue-before-window` **expects** 0 items | The bug is locked in as expected behaviour; changing it is a decision (D-ACP-001) |
| `buildPlannedCareItems` (`server/lib/care/awayPlan/presentation.js`) | Row `kind` ∈ `recurring_calendar` / `recurring_chain` / `single_once` / `indeterminate_pending`; `next_due_date` only for calendar rows | No field carries open-occurrence status or date basis |
| `loadScheduleDataForProjection` | Already loads in-window occurrences **plus all pending** occurrences | No extra query needed for the open occurrence |
| `AwayPlanScheduleCopy` (Flutter) | `~ ` prefix when conditional; chain rows show "Repeats every N, from completion" only | Tilde to retire; estimated line to add |
| CSM primitives | `reschedule`, `pause`/`resume`, `adjust-cadence`, `undo`, `explainGap` are implemented and mounted (`server/routes/healthEntries/occurrencesRouter.js`) | Server work for Phase 4 is small |
| Flutter client | `health_occurrence_remote_datasource.dart` calls `complete`, `skip`, `skip-missed`, `undo` only | **No reschedule UI or client exists** |
| Reschedule route validation | Accepts any date (past, same day, beyond the next hop). Does not refresh `health_entries.next_due_date`, and a test asserts this | The event list (reads `entry.nextDueDate`) would show a stale date after a reschedule (D-ACP-009) |
| Flexibility data | Nothing stores "movable". Available signals: `care_family`, `care_source` (`vet_instruction`, `treatment_schedule`, …), `recurrence_anchor`, `frequency` | A deterministic derivation is possible without schema change (D-ACP-006) |
| File sizes | `occurrencesRouter.js` 498 lines, `plannedAbsencesRouter.js` 449 lines | New logic goes into `server/lib/**`; new routes go in new router files |

**Buddy diagnosis.** Both rows render `indeterminate_pending`, which only happens on the `from_completion` path. So Buddy's Rabies entry is almost certainly `from_completion`: the DB column default is `from_completion`, and the D-CSM-001 family default only applies on create when the anchor is omitted. Confirm in the UAT DB during ACP-1. Either way, ACP-1 fixes both anchors.

---

## 3. Glossary

| Term | Definition |
|---|---|
| **Absence window** `[S, E]` | `planned_absences.starts_on` … `ends_on`, inclusive calendar days |
| **Open occurrence** | The earliest `pending` `health_occurrences` row of an entry (CSM keeps at most one open per series slot, D-CSM-004) |
| **Scheduled / Planned / Estimated** | `date_basis` values (D-ACP-002) |
| **Open status** | `overdue` / `due_before_absence` / `in_window` (D-ACP-004) |
| **Flexibility** | `fixed` / `earlier_only` / `carer_task` / `flexible` + `max_shift_days` (D-ACP-006) |
| **Care Planner** | Deterministic component that proposes reschedules to reduce in-window care (D-ACP-008) |
| **Carer task** | An in-window occurrence the planner cannot or should not move; the carer does it |

---

## 4. Requirements

IDs are stable; phases reference them. "MUST" = exit criterion.

### A — What the away plan shows (per pet, per absence)

| ID | Requirement |
|---|---|
| **R-A1** | The plan MUST list every active, non-paused care item that has (a) an overdue open occurrence, (b) an open occurrence due before `S`, or (c) any scheduled, planned or estimated occurrence in `[S, E]`. |
| **R-A2** | Each row MUST show: care-family icon, title (no `~`), recurrence line (existing D-AWD-003 copy), then the date lines of R-A3–R-A5. |
| **R-A3** | If the open occurrence is overdue or due before `S`, the row MUST show its real date (and time when set) with suffix "Overdue" or "Due before you leave" (D-ACP-004). "Overdue" uses the same wording and colour treatment as the event list (`CareEventStatusLine`, `overdueStatusTreatment`). |
| **R-A4** | In-window dates MUST be labelled by basis: scheduled = date only; `from_due_date` future = "Planned: {date}"; `from_completion` future = "Estimated: {date}" (D-ACP-002/003). |
| **R-A5** | When more than one date falls in the window, the row MUST show the first date, the count and the last date (reusing `occurrence_count`, `first_scheduled_date`, `last_scheduled_date`), not one line per occurrence. |
| **R-A6** | When any row in a pet section shows an estimated date, the section MUST show once, at the bottom: "Estimated dates assume each care is done on its due date." (replaces `awayPlanningChainAnchorExplainer` for this case). |
| **R-A7** | "Date not known" (`indeterminate_pending`) MUST only appear when no date can be computed (D-ACP-001 §2). |
| **R-A8** | The PDF handover MUST show the same lines as the screen (shared `AwayPlanScheduleCopy`). |
| **R-A9** | Paused series MUST show "Paused" and no dates (D-CSM-005: no catch-up). |

### B — Flexibility (CSM fact)

| ID | Requirement |
|---|---|
| **R-B1** | `resolveScheduleFlexibility(entry)` MUST return the value and `max_shift_days` per D-ACP-006, for every care family and source, with table-driven unit tests. |
| **R-B2** | Flexibility MUST be exposed read-only on the care-item read (for warnings) and consumed by the planner. It MUST NOT be persisted in v1. |

### C — Rescheduling from the care item

| ID | Requirement |
|---|---|
| **R-C1** | On Care Item Detail, a pending open occurrence MUST offer "Change date" (next to complete/skip in `pet_event_occurrence_actions.dart`). |
| **R-C2** | Before confirming, the sheet MUST show the gap warning when it differs from the usual gap: "This will be {x} days after the last one instead of {y}." The last one is the last closed occurrence (`completed_on` for `from_completion`, `scheduled_date` for `from_due_date`). If there is no history, show only the usual interval. |
| **R-C3** | The sheet MUST preview what follows. `from_due_date`: "Next ones: {d1}, {d2}" computed from the new date (D-ACP-007). `from_completion`: "Next one estimated around {d1} if done on {new date}". |
| **R-C4** | When the item is `fixed` or `earlier_only` and the move breaks that rule, the sheet MUST show a non-blocking caution, e.g. "This care usually follows a vet's schedule. Check with your vet before changing it." The server returns it as `warnings[]` (D-ACP-009). |
| **R-C5** | After confirming, the care item, the event list and any open away plan MUST show the new date without a manual refresh (provider invalidation; `next_due_date` synced server-side). |
| **R-C6** | The server MUST reject past dates, no-op moves, moves beyond the next hop and moves before the last closed occurrence (400, D-ACP-009). |
| **R-C7** | A reschedule MUST be undoable through the existing `undo` route (already supports `rescheduled`); the snackbar offers Undo, as for complete and skip. |
| **R-C8** | From an away-plan row, "Plan this" MUST open the same sheet with the date pre-filled to `S − 1` (or `E + 1` if earlier is not allowed or not possible). |

### D — Care Planner suggestions

| ID | Requirement |
|---|---|
| **R-D1** | For a planned absence, the plan MUST show a "Suggested by Agatha" block listing moves that reduce the number of in-window occurrences, each with from → to date and a one-line reason. |
| **R-D2** | Each suggestion MUST have **Accept** (executes the reschedule with `reason_code: 'away_planner'`) and **Not now** (hides it for the session). No suggestion ever applies itself. |
| **R-D3** | The block MUST also summarise what remains for the carer: "{n} care tasks for your carer during this absence." |
| **R-D4** | Suggestions MUST respect flexibility strictly: never `fixed`/`carer_task`, only earlier for `earlier_only`, within `max_shift_days`, never to a date `< today` or inside `[S, E]`. |
| **R-D5** | Unaccepted suggestions MUST NOT affect Care Status, Actions, readiness or coverage (CIM non-goal, D-ACP-008). |
| **R-D6** | When there is nothing to suggest, the block MUST NOT render. There is no "no suggestions" empty state (attention-only, same spirit as D-AWD-001). |

---

## 5. Implementation sequence

```text
ACP-DOC-0  Freeze decisions + execute-plan files
   ├── ACP-1  Server: surface open occurrences in projection (bug fix)     ─┐
   │     └── ACP-2  Server: wire contract (date_basis, open_status, estimates) ─┐
   │            └── ACP-3  Flutter: away-plan rows + PDF                        │
   ├── ACP-4  Server: flexibility + reschedule hardening (sync, validate, warnings)
   │     └── ACP-5  Flutter: "Change date" in care item (+ "Plan this" from plan, needs ACP-3)
   │            └── (ACP-6 needs ACP-2 + ACP-4)
   └── ACP-6  Server: Care Planner component + read route
         └── ACP-7  Flutter: suggestions block
ACP-8  Docs, api-reference, BDD + Playwright (last)
```

**Shipping gates**

1. ACP-1 ships alone and first: it is a user-visible bug fix and needs no new UI copy beyond what exists.
2. ACP-2 changes the wire contract **additively** (new fields only; `kind` values unchanged). No red window for the Flutter client, unlike AWD-2.
3. ACP-5 must not merge before ACP-4 (it relies on `warnings[]` and `next_due_date` sync).
4. ACP-7 must not merge before ACP-5: accepting a suggestion reuses the reschedule client and its undo.
5. Single-agent PRs to `main` in the order above. If parallelised, use an integration branch per `agent-coordination.mdc`.

---

## 6. Phases: specification and suggested implementation

### ACP-DOC-0 — Freeze

- Review D-ACP-001…010 and set them to **Frozen**. Resolve §9 items.
- Draft EN + FR ARB strings for every `[proposed]` copy item (§7).
- Create `.agents/plans/away-care-planning.{md,snapshot.json}` and a control issue.

### ACP-1 — Surface open occurrences in the projection (R-A1, R-A3 data, R-A7)

**Files:** `server/lib/care/schedule/projectSchedule.js`, `server/test/careContext/carePeriodProjectionCorpus.js`, `server/test/careContext/carePeriodProjection.test.js`.

Suggested implementation:

1. In `projectEntryForPeriod`, after in-window materialisation, compute `open = earliest pending occurrence` (the input already contains all pending rows).
2. If `open` exists and `open.scheduled_date < startsOn` and the entry is not paused or closed, push a **materialised** item for it (`materialisedItem(entry, open)`) with a new marker `window_relation: 'before_window'`. Items already carry `status`; the presentation layer (ACP-2) classifies overdue or before-absence.
3. `from_due_date`: start the forward loop at `open.scheduled_date` (or `next_due_date`). Record the pre-window open occurrence (step 2) instead of silently skipping it. Keep advancing into the window from there.
4. `from_completion`: replace the "any pending → uncertainty, return" early exit. Emit the open occurrence (step 2 or in-window). Emit `from_completion_chain` uncertainty only when further hops fall in the window; ACP-2 turns those into estimates.
5. `projectSchedule` return shape is unchanged. `projection_status` stays `partially_indeterminate` when chain uncertainty exists.

Tests (explicit cases, added to the corpus):

- `from-completion-overdue-before-window` → **1 item** (the open occurrence, `before_window`), status pending. Replaces the old expectation.
- `from-due-date-overdue-before-window` (annual, due 2026-09-01, window 09-20…09-27, today 09-23) → 1 item on 09-01. Previously 0 items and no uncertainty.
- `from-completion-open-in-window` → unchanged behaviour.
- `paused-series-open-before-window` → 0 items.
- `closed-series` → 0 items.
- Run the full corpus. Every other case stays identical, and the PR lists any case that changes, with a reason.

**Exit:** Buddy's two rows no longer render "date not known" on UAT. The rows may still use V2 copy until ACP-3.

### ACP-2 — Row contract: open status, date basis, estimates (R-A3–R-A7 data)

**Files:** new `server/lib/care/schedule/estimateOccurrences.js` (pure, D-ACP-003), `server/lib/care/awayPlan/presentation.js`, `server/lib/care/awayPlan/formatProjectionReadContract.js`, `docs/architecture/api-reference.md`.

`estimateOccurrences({ entry, openOccurrence, lastCompletedOn, startsOn, endsOn, todayIso })` → `{ dates: string[], basis: 'estimated' | 'planned' | null }`. It uses `advanceByFrequency` and `isOccurrenceDateWithinSeries` from CSM, and never duplicates frequency math.

New **additive** fields on each repeating `planned_care_items[]` row:

```jsonc
{
  "open_occurrence": {              // null when none relevant
    "occurrence_id": "…",
    "scheduled_date": "2026-09-11",
    "scheduled_time": null,
    "open_status": "overdue"        // overdue | due_before_absence | in_window
  },
  "in_window": {                    // null when nothing in [S, E]
    "first_date": "2026-09-25",
    "last_date": "2026-09-25",
    "count": 1,
    "date_basis": "estimated"       // scheduled | planned | estimated (least certain wins)
  },
  "is_paused": false
}
```

- `kind` values and sort order are unchanged (D-AWD-002). A row whose only content is an overdue open occurrence gets its anchor's kind (`recurring_calendar` / `recurring_chain`), not `indeterminate_pending`.
- `next_due_date` stays for backwards compatibility. Flutter stops reading it in ACP-3.
- `open_status` is computed with `todayCalendarIso()`, as in the existing routes.

Tests: table tests for `estimateOccurrences`, including:

- the product example: due Mon 1st, 7 days, windows 6–10 → 8th and 20–23 → 22nd;
- the overdue base-today case;
- `repeat_end_date` cut;
- monthly on the 31st;
- `times_of_day` × 2;
- presentation tests for each `open_status` and the `date_basis` precedence.

### ACP-3 — Flutter away-plan rows + PDF (R-A2–R-A9)

**Files:** `flutter_app/lib/features/pet_care/context/domain/entities/care_period_coverage.dart` (+ data model), `…/presentation/away_plan_schedule_copy.dart`, the pet-care section widget, ARB EN/FR, mirrored widget tests.

- Parse `open_occurrence`, `in_window`, `is_paused` (nullable, tolerant of absence).
- Copy layer: `openOccurrenceLine` ("{date} · Overdue" / "{date} · Due before you leave"), `inWindowLine` ("Planned: {date}", "Estimated: {date}", or for count > 1 "{count} times, {first} – {last}", prefixed "Estimated" when the basis is estimated), `pausedLine`.
- Remove the `~` prefix (D-ACP-005). Keep `isConditional` on the entity if other code uses it.
- Overdue suffix uses `overdueStatusTreatment(colorScheme)` so colour and semantics match the event list. Accessibility: the status word is text, not colour only.
- Section footnote per R-A6, rendered once per pet.
- PDF: same functions via `plannedCareHandoverLine`. **Call out the PDF delta in the PR description.**
- Widget tests: one per open status × basis, a paused row, the footnote shown once, no tilde.

### ACP-4 — Flexibility + reschedule hardening (R-B1, R-B2, R-C4 data, R-C6, D-ACP-009)

**Files:** new `server/lib/care/schedule/scheduleFlexibility.js`, new `server/lib/care/schedule/validateReschedule.js`, `rescheduleOccurrence.js`, `server/routes/healthEntries/occurrencesRouter.js` (thin call only; the file is at 498 lines, so move helper code out rather than growing it), tests.

- `resolveScheduleFlexibility(entry, todayIso)` → `{ flexibility, max_shift_days }` per D-ACP-006.
- `validateReschedule({ entry, occurrence, newDate, lastClosedDate, todayIso })` → `{ ok, error? , warnings[] }` implementing D-ACP-009 §2–3.
- `rescheduleOccurrence` calls `syncNextDueDateFromOccurrences` after the update. Update the CSM-10 test expectation (`nextDueDate` → new date; `advanceSeriesCalled` stays `false`).
- Response: existing occurrence map + `warnings[]` + `next_due_date`.
- Expose flexibility on the care-item read: add `schedule_flexibility` to the entry map, computed on read.
- Tests: every 400 branch, each warning, the flexibility table, and route auth (401/404 unchanged).

### ACP-5 — "Change date" in the care item (R-C1–R-C8)

**Files:** `health_occurrence_remote_datasource.dart` (+ repository/provider), new `reschedule_occurrence_sheet.dart` under `health_tracking/presentation/widgets/`, `pet_event_occurrence_actions.dart`, the away-plan row action, ARB, tests.

- Datasource `rescheduleOccurrence(entryId, occurrenceId, date, {reasonCode})` → `POST …/occurrences/:occId/reschedule`.
- Sheet: date picker bounded by the server rules (past disabled; hard limits come from server errors, not duplicated logic). It shows the gap warning (R-C2) and next-date preview (R-C3). These are computed client-side for instant feedback, but the text of any `warnings[]` returned by the server wins on confirm.
- **Accepted duplication:** the preview maths runs on the client for responsiveness. It is display-only; the server decides. If this proves fragile, add a `dry_run=true` flag to the route (follow-up, not v1).
- On success: invalidate `entryOccurrencesProvider`, the entry and the away-plan coverage providers; snackbar with Undo (existing undo route).
- "Plan this" on away-plan rows opens the sheet with the pre-filled date (R-C8).
- Accessibility: the sheet follows `AppForm*` conventions, the warning is announced (live region), and the picker is labelled.

### ACP-6 — Care Planner component (R-D1, R-D3–R-D6 data)

**Boundary (D-ACP-008):**

```text
server/lib/care/planner/
  index.js                 public API: planAbsenceCare, loadAbsenceCarePlan
  planAbsenceCare.js       pure: (input) → plan; no I/O, no Date.now()
  candidateMoves.js        pure: candidate dates per entry within flexibility
  loadAbsenceCarePlan.js   I/O: loads absence, pets, entries, pending occurrences, last closed dates
server/routes/careContext/absenceCarePlanRouter.js
  GET /api/planned-absences/:id/care-plan   (declarer-scoped, same auth as /:id/readiness)
```

Allowed imports: `../schedule/index.js` (projection, `estimateOccurrences`, `resolveScheduleFlexibility`, `advanceByFrequency`) and `../../calendarDate.js`. Forbidden: `../intelligence/**`, any write helper, `pool` inside pure files. Enforce with a Jest import-boundary test, the same pattern as other boundary tests if present; otherwise a simple static `grep` test.

**Input → output**

```jsonc
// planAbsenceCare input
{ "absence": { "id", "starts_on", "ends_on" }, "today": "YYYY-MM-DD",
  "pets": [{ "pet_id", "entries": [{ "entry", "open_occurrence", "last_closed_date" }] }] }

// output (per pet)
{ "pet_id": "…",
  "suggestions": [{
     "health_entry_id", "occurrence_id", "from_date", "to_date",
     "direction": "earlier" | "later",
     "in_window_before": 2, "in_window_after": 0,
     "flexibility": "flexible", "rationale_code": "move_before_departure" }],
  "carer_tasks": { "count": 5, "by_entry": [{ "health_entry_id", "count", "reason": "fixed" | "carer_task" | "no_valid_move" }] } }
```

**Business rules**

| # | Rule |
|---|---|
| BR-1 | Only the **open occurrence** can be moved (D-CSM-004, D-ACP-010). Later hops change only as a consequence. |
| BR-2 | Candidate dates: `open.scheduled_date ± k`, `k ∈ 1…max_shift_days`; `earlier_only` → minus only. Discard if `< today`, inside `[S, E]`, `≤ last_closed_date`, or `≥ advanceByFrequency(open.scheduled_date)`. |
| BR-3 | For each candidate, recompute in-window count with `estimateOccurrences`, taking the candidate as the new open date. Keep a candidate only if it **reduces** the count. |
| BR-4 | Choose one suggestion per entry, ordered by (1) largest reduction, (2) earlier over later (guardian is present before leaving), (3) smallest `|k|`. This order is deterministic, so the same input always gives the same output. |
| BR-5 | Chain-aware: a `from_completion` weekly item due Mon 1st with absence 6–10 can be cleared by moving the open occurrence so the estimated next hop falls outside the window. BR-3 already covers this; no special case. |
| BR-6 | `fixed`, `carer_task`, paused and closed entries never get suggestions. Their in-window occurrences count as carer tasks. |
| BR-7 | Overdue open occurrences: the suggestion is "do it before you leave" (`rationale_code: 'overdue_do_before_departure'`), only when `today < S`. Accepting it is a reschedule to a date in `[today, S−1]`, and only if the item is not `fixed`. For a `fixed` item nothing is suggested; the row already shows Overdue. |
| BR-8 | Stateless: computed on each read, not persisted. "Not now" is client-session only (v1). |
| BR-9 | Acceptance goes through `POST …/occurrences/:occId/reschedule` with `reason_code: 'away_planner'`. The server re-validates (ACP-4). A stale suggestion fails cleanly with 400/404; the client refreshes the plan. |
| BR-10 | Output never feeds Care Status, readiness, coverage or Actions. |

**Tests:** pure-function table tests for BR-1…BR-7 (including the product's weekly example and an `earlier_only` vaccine with a 5-day cap); route tests for auth, a cancelled absence (404) and a non-declarer (404); the boundary test; a determinism test (same input twice → deep-equal output).

### ACP-7 — Suggestions block (R-D1–R-D6)

**Files:** new `away_plan_suggestions_section.dart`, repository and provider for `GET …/care-plan`, ARB, tests.

- Renders under the pet header, above "Planned care", only when there are suggestions or carer tasks.
- Label "Suggested by Agatha" (`careSuggestionTitle`). Each suggestion: icon, title, "Move from {from} to {to}", reason line, **Accept** / **Not now**.
- Accept → the reschedule datasource from ACP-5 (with its Undo), then invalidate the plan and coverage.
- Carer-tasks line (R-D3).
- Widget tests: hidden when empty, accept calls the reschedule client with `reason_code`, Not now hides the suggestion, Undo restores it.

### ACP-8 — Docs, contract, journeys

- `care-context.md`: absence display contract (R-A*) and planner section (R-D*).
- `care-schedule-management.md`: flexibility, reschedule validation and sync.
- `docs/architecture/api-reference.md`: ACP-2 fields, reschedule response `warnings[]`, `GET /care-plan`.
- BDD + Playwright `@bdd` scenarios:
  - Overdue item shown with its date on the away plan
  - Estimated date shown for a completion-based item
  - Change a care date from the care item and see the next dates update
  - Accept a planner suggestion and see the carer-task count drop
- `.agents/memory/MEMORY.md`: one line on D-ACP-001 (the projection now surfaces pre-window open occurrences).

---

## 7. Copy to draft in ACP-DOC-0 (EN, `[proposed]`; FR in the same pass)

| Key | EN |
|---|---|
| `awayPlanningOpenOverdue` | "{date} · Overdue" (reuse `urgencyOverdue`) |
| `awayPlanningOpenDueBeforeLeave` | "{date} · Due before you leave" |
| `awayPlanningPlannedOn` | "Planned: {date}" |
| `awayPlanningEstimatedOn` | "Estimated: {date}" |
| `awayPlanningInWindowRange` | "{count} times, {first} – {last}" |
| `awayPlanningEstimateFootnote` | "Estimated dates assume each care is done on its due date." |
| `awayPlanningPaused` | "Paused" |
| `rescheduleActionLabel` | "Change date" |
| `rescheduleGapWarning` | "This will be {x} days after the last one instead of {y}." |
| `reschedulePreviewCalendar` | "Next ones: {dates}" |
| `reschedulePreviewCompletion` | "Next one estimated around {date} if done on {newDate}." |
| `rescheduleVetScheduleCaution` | "This care usually follows a vet's schedule. Check with your vet before changing it." |
| `awayPlanningPlanThis` | "Plan this" |
| `plannerMoveLine` | "Move from {from} to {to}" |
| `plannerReasonBeforeDeparture` | "Done before you leave, so your carer doesn't need to." |
| `plannerReasonAfterReturn` | "Done after you're back, so your carer doesn't need to." |
| `plannerCarerTasks` | "{count, plural, one{1 care task} other{{count} care tasks}} for your carer during this absence." |
| `plannerAccept` / `plannerNotNow` | "Accept" / "Not now" |

Check every string against `docs/design/copy-tone.md` (plain, operational, no blame).

---

## 8. Where this plan stops

**In scope:** everything in §4 and §6.

**Out of scope, deliberately deferred:**

| Item | Why deferred | Revisit trigger |
|---|---|---|
| Fixed dates two or more occurrences ahead (schedule-intent records) | D-ACP-010; needs new schema against D-CSM-004 | A concrete case that estimates plus one reschedule cannot handle |
| Per-entry flexibility override (column + form field) | Derived defaults first; avoid schema before evidence | Users report wrong defaults |
| Persisted "Not now" / dismissed suggestions | v1 is stateless (BR-8) | Users see the same dismissed suggestion repeatedly |
| Planner suggesting **pause** or **cadence change** | Larger, rule-changing actions; D-CSM-006 separates them from reschedule | After ACP-7 usage review |
| Carer-facing view of estimates (shared users) | Carer access model is D-AWAY-003/004 territory | Carer handover v2 |
| `dry_run` reschedule preview endpoint | Client preview is enough for v1 | Preview and server disagree in QA |
| Time-of-day "missed today" on the away plan | Away plan is calendar-day based | Product asks for it |
| Notifications or reminders about "due before you leave" | Separate surface; notification policy | Separate plan |
| Stale CSM status table in `care-schedule-management.md` | Already covered by the separate docs PR | — |

**Known follow-ups created by this plan:**

- The corpus byte-identical guarantee (CSM delivery plan gate 2) is intentionally broken once, in ACP-1, and recorded in D-ACP-001.
- After ACP-4, `health_entries.next_due_date` is refreshed on reschedule. Any other code that assumed otherwise must be checked (grep `next_due_date` readers in ACP-4).

---

## 9. Review checklist for Cursor (resolve in ACP-DOC-0)

1. **Flexibility numbers** (D-ACP-006):
   - Is 7 days the right `carer_task` threshold?
   - Is `flexible` tolerance of 25% of the interval (cap 14 days) right?
   - Is `earlier_only` at 10% (cap 7 days) right? Any clinical claim needs vet-advisor sign-off before copy ships.
2. **Manual moves of `fixed` / `earlier_only` items:** confirm they are allowed with a caution rather than blocked (D-ACP-006 last bullet, True North #10).
3. **D-ACP-009 route guards:** confirm "no move beyond the next hop" and "no move before the last closed occurrence" are acceptable for all families, including `once` entries (out of scope: `once` has no next hop; the rule applies to repeating entries only).
4. **Buddy's data:** confirm on UAT which anchor his Rabies entry has, to close the diagnosis (§2).
5. **ACP-1 corpus diff:** reviewer approves each changed corpus case explicitly.
6. **Copy table §7:** EN + FR wording; "Due before you leave" vs "Due before you go".
7. **Planner placement in the UI:** above "Planned care" (proposed) or in a separate tab/card.
