---
title: Away Care Planning — Decisions
owner: Product / Agent
audience: both
status: frozen
last_updated: 2026-09-23
tags: [pet_care, care_context, care_schedule_management, away_planning, decisions]
---

# Away Care Planning — Decisions

**Delivery plan:** [away-care-planning-delivery-plan.md](./away-care-planning-delivery-plan.md)
**Builds on:** [away-plan-detail-v2-decisions.md](./away-plan-detail-v2-decisions.md) (D-AWD-*), [away-planning-decisions.md](./away-planning-decisions.md) (D-AWAY-*), [care-schedule-management-decisions.md](./care-schedule-management-decisions.md) (D-CSM-*)

**Status: frozen** (ACP-DOC-0, 2026-09-23). Product answers were given in chat on 2026-09-23 (summarised in the delivery plan §1.3). Cursor review resolutions are recorded in delivery plan §9. Decisions marked *amends* change a frozen decision and must be read together with it.

---

## D-ACP-001 — An open occurrence with a known date is always visible on the away plan (amends D-AWAY-007, corpus case `from-completion-overdue-before-window`)

**Problem:** `projectEntryForPeriod` (`server/lib/care/schedule/projectSchedule.js`) drops overdue pending occurrences:

- `from_completion`: any pending occurrence → `uncertainty: from_completion_pending`, zero items → row `kind: indeterminate_pending` → "date not known" copy, although the occurrence has a real `scheduled_date`.
- `from_due_date`: the cursor advances past an overdue date without recording it → no item and no uncertainty → **the entry vanishes from the plan**.

**Rule:**

1. For every active, non-paused repeating entry with a pending occurrence, the plan shows that **open occurrence** with its real `scheduled_date` (and `scheduled_time` when set) whenever the occurrence is **overdue**, **due before the absence starts**, or **inside the absence window**.
2. `indeterminate_pending` is kept only for real unknowns: no pending occurrence, no `next_due_date`, and no completion history to estimate from.
3. The corpus case `from-completion-overdue-before-window` (expects 0 items) is **replaced**, not deleted. It must expect the open occurrence to be surfaced. A new case covers the vanishing `from_due_date` entry, using a **materialised pending `health_occurrences` row** (the production shape loaded by `loadScheduleDataForProjection`), not only `next_due_date` before the window.

**Coverage side effect (intentional):** surfacing a before-window pending occurrence may change care coverage from `indeterminate` to `has_items_to_review`. That is more honest than falsely reassuring `nothing_scheduled` when a `from_due_date` entry previously vanished entirely.

**Why:** True North #9 (safety without alarmism) requires honesty about what is known. Hiding a known, late date is false uncertainty, which is also dishonest.

---

## D-ACP-002 — Three date bases: scheduled, planned, estimated (amends D-AWD-003 "never a fabricated calendar date")

Every date shown on a planned-care row carries a `date_basis`:

| `date_basis` | Meaning | Source | Row wording (proposed) |
|---|---|---|---|
| `scheduled` | A real occurrence exists | `health_occurrences` row | the date alone, plus a status suffix |
| `planned` | Fixed calendar rhythm, not yet materialised | `from_due_date` projection | "Planned: {date}" |
| `estimated` | Depends on when the previous one is done | `from_completion` estimate (D-ACP-003) | "Estimated: {date}" |

**Amendment to D-AWD-003:** `recurring_chain` rows may now show a calendar date, but **only** with `date_basis: estimated` and the word "Estimated" on the row itself. The footnote explains how estimates work; the row states that the date is uncertain. D-AWD-003's intent (never pass off a guess as a fact) is preserved.

---

## D-ACP-003 — Estimate algorithm for `from_completion` rhythms

Inputs: the entry (frequency, interval, times, `repeat_end_date`), the **earliest pending occurrence** `O` (if any), `today`, and the window `[S, E]`.

```text
base :=
  O.scheduled_date           if O exists and O.scheduled_date >= today   // assume done on time
  today                      if O exists and O.scheduled_date <  today   // overdue: assume done today
  last_completed_on          if no O (defensive; CSM normally keeps one open)
  → indeterminate_pending    if none of the above

d := base
while d < S:               d := advanceByFrequency(d, entry)   // same helper CSM uses
estimates := all d' in [S, E] reachable by repeated advanceByFrequency, within series end
```

- The open occurrence itself is never "estimated". It is `scheduled` (D-ACP-001).
- Estimates are recomputed on every read, so an overdue item's estimates move forward day by day. This is expected and the reason for the footnote.
- Example (confirmed with product): open occurrence due Mon 1st, every 7 days. Absence 6th–10th → estimated **8th**. Absence 20th–23rd → estimated **22nd**.
- **Footnote copy (frozen):** "Estimated dates assume you complete overdue care today, then keep to the usual interval." This matches the algorithm (overdue open occurrence → base = `today`; on-time open → base = `scheduled_date`). The originally drafted "done on its due date" wording was incorrect for overdue rows.

---

## D-ACP-004 — "Due before you leave" replaces predicted "overdue at the start"

Status of the open occurrence on an away-plan row, computed **server-side** against `today` (calendar day, `todayCalendarIso()`):

| Condition | `open_status` | Row suffix (proposed) |
|---|---|---|
| `scheduled_date < today` | `overdue` | "Overdue" (same word and treatment as the event list, `CareEventStatusLine`) |
| `today ≤ scheduled_date < S` | `due_before_absence` | "Due before you leave" |
| `S ≤ scheduled_date ≤ E` | `in_window` | none (date only; "Due today" if it is today) |

We never predict "will be overdue". An absence that starts today makes the middle bucket empty. Time-of-day "missed today" (the Flutter `isOccurrenceMissed` rule) stays a client concern for the event list. The away plan works in calendar days, like the rest of Care Context.

---

## D-ACP-005 — The `~` title prefix is retired

`AwayPlanScheduleCopy.plannedCareRowTitle` prefixes `~ ` when `certainty == conditional_on_future_completion`. Once D-ACP-002 puts "Estimated" on the row, the tilde duplicates that signal without explaining it. Remove it from the screen and from the PDF handover, which share the same copy layer.

---

## D-ACP-006 — Schedule flexibility is a deterministic CSM fact

A new read-only derivation `resolveScheduleFlexibility(entry)` in `server/lib/care/schedule/` returns one of:

| Value | Meaning | Derived when (first match wins) |
|---|---|---|
| `fixed` | Never suggested for moving | `care_source ∈ {vet_instruction, treatment_schedule}` only (not all `medication` — frequent guardian-set meds are handled by `carer_task` when interval < 7 days) |
| `earlier_only` | May be suggested earlier, never later | `care_family ∈ {vaccination, parasite_prevention}` (Care Through Change "movable: ask, earlier only, never later") |
| `carer_task` | Too frequent to move meaningfully | interval < 7 days (daily, every-N-days with N < 7, multiple times/day) |
| `flexible` | May move earlier or later within tolerance | everything else |

Tolerance (`max_shift_days`):

- `flexible`: `min(14, floor(interval_days × 0.25))`.
- `earlier_only`: `min(7, floor(interval_days × 0.1))`.
- `interval_days` for calendar frequencies is the day gap of one `advanceByFrequency` step from `today`.

Numbers are **v1 product defaults** (not clinical claims), confirmed in ACP-DOC-0: `carer_task` threshold 7 days; `flexible` 25% cap 14 days; `earlier_only` 10% cap 7 days.

- **Not stored in v1.** No column and no per-entry override. Derived on read, so it cannot drift from `care_family`/`care_source`.
- **Scope of the rule:** flexibility constrains the **Care Planner** (D-ACP-008) strictly. It does **not** block a guardian's own manual reschedule (True North #10: the pet parent stays in control). Instead it changes the warning shown (D-ACP-009).

---

## D-ACP-007 — Rescheduling a `from_due_date` occurrence re-anchors the series (clarifies D-CSM-006)

Confirmed by product: when a `from_due_date` occurrence is moved, the **following** occurrence is calculated from the moved date. This is current behaviour: `rescheduleOccurrence` overwrites `scheduled_date`, and `resolveNextSeriesDate` uses the closed `scheduled_date` as base. The clinical rationale is that the next booster counts from when it was actually given.

D-CSM-006's "does not change series recurrence rule" remains true: frequency and interval are unchanged, only the phase moves. The reschedule UI must say so in its preview (delivery plan R-C3).

---

## D-ACP-008 — Care Planner is a bounded, deterministic component in Care Context, not CIM

- **Location:** `server/lib/care/planner/` (new). Pure functions plus one loader, with no writes.
- **Reads** (via public exports only): CSM `projectSchedule` / estimate helpers and `resolveScheduleFlexibility`, the planned absence, and pending occurrences.
- **Never:** writes to DB, imports from `server/lib/care/intelligence/**` (CIM), changes Care Status or Actions, or persists suggestions.
- **Acceptance** of a suggestion calls the existing CSM reschedule route with `reason_code: 'away_planner'`. The planner has no write path of its own.
- **Presentation:** reuses CIM's guardian-facing label ("Suggested by Agatha", `careSuggestionTitle`) for consistency. That is the only thing borrowed from CIM.
- **Not subject to CIM scope limits** (species, `CIM_SUGGESTION_CARE_FAMILIES`), because it makes no health inference. It only rearranges dates the guardian already committed to.
- Business rules: delivery plan §6 (ACP-6).

---

## D-ACP-009 — Reschedule keeps `next_due_date` in sync; server validates the new date (amends CSM-10 test expectation)

`rescheduleOccurrence` currently leaves `health_entries.next_due_date` unchanged. The test `does not advance series or change entry cadence` asserts this. But `next_due_date` is the cache the event list reads (`formatCareEventStatusLine` uses `entry.nextDueDate`), so after a reschedule the event list shows the **old** date.

**Rule:**

1. After the occurrence update, call `syncNextDueDateFromOccurrences`. This is a cache refresh (earliest pending), not a cadence change. `advanceSeries` must still **not** be called.
2. The route rejects (400) when:
   - `scheduled_date < today`,
   - it equals the current `scheduled_date`, or
   - it is on or after `advanceByFrequency(current scheduled_date)`. You cannot move an occurrence past where the next one would have been; that is a cadence change (`adjust-cadence`), or
   - it is on or before the entry's last closed occurrence date (completed or skipped). Occurrences never overtake history.
3. The route returns `warnings[]` (non-blocking): `outside_flexibility` (D-ACP-006), `interval_changed` (`{ previous_gap_days, usual_gap_days }`), and `earlier_only_later_move` when an `earlier_only` item is moved later than its current date. The client renders these; the server stays the source of truth. Manual moves of `fixed` / `earlier_only` items are **never blocked** (True North #10); warnings only.
4. Update the test expectation: `nextDueDate` becomes the new date, and `advanceSeriesCalled` stays `false`.

---

## D-ACP-010 — Fixed future dates beyond the open occurrence are deferred

The "planned fixed" chain (fix occurrence #3 while #2 is still open) needs a new schedule-intent record because D-CSM-004 forbids pre-materialising `anchor+1`. **Dropped for now** (product, 2026-09-23). Absence needs are covered by D-ACP-003 estimates, rescheduling the open occurrence, and the Care Planner's chain-aware suggestion (ACP-6 BR-5). Revisit only with a concrete case that needs two or more future fixed dates.
