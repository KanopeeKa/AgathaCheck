---
title: Care Schedule Management — Decision log
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-29
tags: [pet_care, care_planning, decisions]
---

# Care Schedule Management — Decision log

Frozen product and engineering decisions for **Care Schedule Management (CSM)**. Canonical behaviour lives in [care-schedule-management.md](../features/care-schedule-management.md). Delivery sequencing: [care-schedule-management-delivery-plan.md](./care-schedule-management-delivery-plan.md).

**Context:** AgathaTrack is **not in production**; no real user data exists. Decisions below assume a clean cutover — no backfill analysis, no GDPR-export preservation for legacy tables.

---

## D-CSM-001 — Recurrence anchor defaults by care family (2026-09-15)

**Status:** Frozen

| Care family | Default `recurrence_anchor` | Rationale |
|-------------|----------------------------|-----------|
| `vaccination` | `from_due_date` | Clinical interval integrity — aligns with Care Through Change “movable: ask, earlier only, never later” for immunisation schedules |
| `parasite_prevention` | `from_due_date` | Same clinical-interval rationale as vaccination |
| All other recurring families | `from_completion` | Guardian-paced rhythms (medication, grooming, weight monitoring, etc.) |

**Implementation:** Server applies default on create when `recurrence_anchor` is omitted; explicit guardian choice always wins. No migration of existing rows required (no production data).

**Supersedes:** Blanket “freeze `from_completion` for all entries” from the initial CSM verification review.

> **Amended 2026-09-29 by [D-CSM-020](#d-csm-020--two-schedule-types-with-category-defaults-2026-09-29).** The defaults are reversed: **medication → Fixed schedule** (`from_due_date`); vaccination, parasite prevention and every other family → **After it's done** (`from_completion`). The “explicit choice wins” rule is unchanged.

---

## D-CSM-002 — `from_completion` semantics for non-clinical families (2026-09-15)

**Status:** Frozen

For entries defaulting to `from_completion`:

> The next occurrence date is **N frequency units after the actual completion date** (current `nextOccurrence()` behaviour). Late completions compound drift; that is intentional for guardian-paced care.

Fixed cadence without drift: use `from_due_date` (explicit at create, or the default for vaccination / parasite prevention per D-CSM-001).

> **Amended 2026-09-29:** the families that default to each type are now set by [D-CSM-020](#d-csm-020--two-schedule-types-with-category-defaults-2026-09-29). The drift rule itself is unchanged and is restated for users as **After it's done** ([D-CSM-022](#d-csm-022--after-its-done-rules-2026-09-29)).

`completion_timing` (`early` \| `on_time` \| `late`) is **informational in v1** — stored at write time, not used to alter `advanceSeries` unless a future decision revisits this.

---

## D-CSM-003 — `health_history` retirement (2026-09-15)

**Status:** Frozen

`health_history` is **dead weight**, not an archive:

- Stop all new writes for complete/skip once unified primitives ship (CSM-7).
- Do **not** backfill into `care_schedule_events`.
- Leave the table in place until a later cleanup migration drops it.
- No GDPR-export preservation reasoning — no real user data exists.

---

## D-CSM-004 — Remove multi-day `anchor + 1` pre-materialization (2026-09-15)

**Status:** Frozen

Remove `materialiseInitialOccurrences`’s extra calendar-day batch for multi-per-day entries (`occurrenceScheduling.js` multi-day branch at create).

**Rationale:** Original intent (PR #821) was UX — surface “coming up” tomorrow doses before T−1 fires; not a timezone safeguard. T−1 materialisation (`isWithinMaterialisationWindow`) is sufficient.

**Outcome:** Eliminates structural multi-open-date state; unified `advanceSeries()` handles rollover for single- and multi-per-day paths (CSM-3/4).

> **Amended 2026-09-29 by [D-CSM-019](#d-csm-019--occurrence-guarantee-2026-09-29) and [D-CSM-023](#d-csm-023--fixed-schedule-rules-2026-09-29).** The T−1 window is removed: occurrences are created in the same transaction as the command that needs them. Fixed-schedule items keep the slots of the **next series date** open (so several open dates are a normal state for them); After-it's-done items keep a single open occurrence unless a person planned more ([D-CSM-021](#d-csm-021--occurrence-origins-and-precedence-2026-09-29)).

---

## D-CSM-005 — Pause resume has no catch-up (2026-09-15)

**Status:** Frozen

`resumeSeries` does **not** backfill occurrences for the paused window. Matches Care Progression rule: pausing does not erase Established status.

> **Amended 2026-09-29 by [D-CSM-028](#d-csm-028--postpone-until-one-mechanism-2026-09-29).** Pause, pause until a date and the absence “move after return” resolution are one command (**Postpone until**). Resume asks for the date, pre-filled with the date the item would have had without the pause. “No catch-up” still holds.

---

## D-CSM-006 — Reschedule vs cadence change (2026-09-15)

**Status:** Frozen

| Operation | Scope |
|-----------|-------|
| `rescheduleOccurrence` | One instance; original `scheduled_date` preserved on `care_schedule_events`; does not change series recurrence rule |
| `adjustCadence` | Series going forward only; never rewrites past occurrences |

Manually moving one occurrence does **not** implicitly change anchor or frequency. “Make this fixed going forward” is an explicit `adjustCadence` action.

---

## D-CSM-007 — Demo seed data refresh (2026-09-15)

**Status:** Frozen

Rewrite UAT/demo seed data to exercise CSM edge cases found in code review (minimum coverage list in delivery plan §CSM-SEED). Runs as **CSM-SEED** — parallel dev/test infrastructure after CSM-0; does not block CSM-1 schema work.

---

## D-CSM-008 — Hard gate before Care Through Change reschedule/pause UI (2026-09-15)

**Status:** Frozen

**Satisfied 2026-09-15.** CSM-17 integration gate merged ([#1192](https://github.com/KanopeeKa/AgathaCheck/pull/1192)) and landed on `main` via programme integration ([#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193)). Unified write primitives, `projectSchedule`, `explainGap`, `advanceSeries`, and `care_schedule_events` ledger are live. Care Through Change reschedule/pause UI (post–CC-4 tranche) may proceed.

---

## D-CSM-018 — Intent-based materialisation of the open occurrence (2026-09-28)

**Status:** Frozen (execute-plan `care-absence-materialisation-7796`)

**Problem:** Lazy T−1 materialisation leaves **projected / estimated** in-window dates without a `health_occurrences` row. Skip, reschedule, and absence **Review date** require a materialised **open head** — UI otherwise dead-ends on “Not set” and null `occurrence_id`.

**Decision:** Add **`ensureOpenOccurrence`** — an explicit CSM write that idempotently creates pending row(s) for the **canonical open calendar day** (earliest pending if any; otherwise the next series date computed like `advanceSeries`, without bypassing series bounds).

| Allowed | Not allowed |
|---------|-------------|
| User intent: Review date, Change date, Skip (after ensure), proactive ensure for **affected** absence context on the **open head** | Pre-generating full in-window chains (daily batch) |
| Materialise **one calendar day** (all slots that day for multi-dose) | Materialising a non-head projected hop while an earlier pending day exists (BR-1) |
| Ledger optional `materialised` event for audit | GET-on-read hidden writes |

**Relationship to D-CSM-004:** D-CSM-004 forbids automatic **`anchor+1` at create**. D-CSM-018 is **on-demand** materialisation when the guardian or absence flow needs to act — not series pre-generation.

**Relationship to D-ACP-010:** Schedule-intent records for “fix hop #3 while hop #2 is open” remain **deferred**. D-CSM-018 does **not** reopen D-ACP-010; non-head estimated dates still require handling the **open head** first.

**HTTP:** `POST /api/health-entries/:id/occurrences/ensure-open` (see [api-reference.md](/docs/architecture/api-reference.md)).

**Implementation plan:** `care-absence-materialisation-7796` phases `ensure-server`, `ensure-flutter`, `absence-ux`.

> **Superseded in part 2026-09-29 by [D-CSM-019](#d-csm-019--occurrence-guarantee-2026-09-29).** Every active planned item now always has a stored open occurrence, so there is nothing to “ensure”. `ensure-open` stays only as a compatibility route that returns the current open occurrences with `created: false`; it is deleted when the new client ships (`care-next-occurrence-c1a7` child F).

---

## Care occurrences programme (2026-09-29)

Decisions D-CSM-019 … D-CSM-033 were agreed with the product owner on 2026-09-29 (roadmap `.agents/plans/care-next-occurrence-c1a7.md`, approved v3.1). The product is pre-launch: existing care data is wiped and reseeded rather than migrated. User-facing wording and the agenda are frozen in [care-item-evolution.md](../features/care-item-evolution.md) (D-CIE-024 … D-CIE-028); absences in [away-care-planning-decisions.md](./away-care-planning-decisions.md) (D-ACP-011).

---

## D-CSM-019 — Occurrence guarantee (2026-09-29)

**Status:** Frozen

Every **active planned** Care Item (`care_planning` ≠ `unplanned`, `status = 'active'`, series not finished) always has **at least one stored open occurrence** (`health_occurrences.status = 'pending'`) that can be acted on at once: Mark as done, Skip, Change date, Postpone.

- Occurrences are created **synchronously, in the same transaction** as the command that needs them (create, complete, skip, undo, change date, postpone, resume, edit). A user sees the next date as soon as the command returns (owner: “no delay, or a few seconds”).
- The **T−1 window is removed** (`isWithinMaterialisationWindow`, the “no insert when the next date is more than a day away” gate). A yearly item has its next open occurrence a year ahead.
- `next_due_date` is a **derived cache** = the earliest open occurrence date (or null). Only the sync step writes it.
- Paused items keep their open occurrence (hidden from lists and reminders) and get no new ones.

**Amends:** D-CSM-004 (T−1 part), D-CSM-018 (ensure-open becomes compatibility only), [occurrence-scheduling.md](../../health_tracking/changes/occurrence-scheduling.md) §Materialisation.

---

## D-CSM-020 — Two schedule types with category defaults (2026-09-29)

**Status:** Frozen

Users choose between two schedule types (Advanced settings → **Schedule type**). Wire values are unchanged.

| User label | `recurrence_anchor` | Meaning |
|------------|---------------------|---------|
| **Fixed schedule** | `from_due_date` | Dates follow the calendar rule, whatever happens to each date. Each date gets its own occurrence; missed ones can still be recorded. |
| **After it's done** | `from_completion` | One open date. The next date counts from the day it is done. |

| Care family (`care_family`) | Default |
|-----------------------------|---------|
| `medication` | **Fixed schedule** |
| `vaccination`, `parasite_prevention`, `wellness_review`, `dental`, `weight_monitoring`, `grooming`, `nail_care`, `other` | **After it's done** |

- The explicit choice always wins; changing category updates the schedule type only while the user has not touched it.
- Items with **several times of day** require Fixed schedule (validation error `times_require_fixed_schedule`; the form does not offer the other type).

**Rationale:** parasite-prevention labels say to give a missed dose and continue monthly from then; the next vaccine booster counts from the date it was given (D-ACP-007); medication needs a record of each dose.

**Amends:** D-CSM-001.

---

## D-CSM-021 — Occurrence origins and precedence (2026-09-29)

**Status:** Frozen

Every occurrence records where its date came from (`health_occurrences.origin`):

| Origin | Created by |
|--------|------------|
| `schedule` | A Fixed-schedule rule (series date × time of day) |
| `computed` | The After-it's-done rule (last done date + interval) |
| `planned` | A person: another date, a moved date, a postponed date, a booster, a booked visit |

Rules:

1. The app **never moves** a `planned` or `schedule` occurrence on its own.
2. At most **one** open `computed` occurrence per item.
3. After an occurrence closes, if any other occurrence is still open, **no** computed occurrence is created. If none is open, the rule creates the next one (`computed` for After it's done, `schedule` for Fixed schedule).
4. Moving a `computed` occurrence (Change date, Postpone) turns it into `planned`.
5. The care tick never creates `computed` occurrences.

---

## D-CSM-022 — After-it's-done rules (2026-09-29)

**Status:** Frozen

| Event | Result |
|-------|--------|
| Done | If another open occurrence waits, it becomes the next date (D-CSM-026 may ask first). Otherwise a `computed` occurrence at `completed_on + interval` (month-end clamp, D-CSM-024) |
| Skipped | Same, counted from `max(scheduled_date, today) + interval` |
| Not done after its day (or time) | **Overdue** until done, skipped or postponed. No stack |
| Estimated next | While overdue, the item shows **“Estimated next: today + interval”**. This is **display only**: never a row, never an action, never a reminder |
| Completing overdue care | D-CIE-009 stays: “When was this done?” first; that date feeds the rule |
| Completing a later open date while an earlier one is open | Ask: **Mark it done** / **Skip it** / **Keep it** for the earlier date |

Example: due 5 Jun (monthly). On 7 Jun, still not done → “Overdue · 5 Jun”, “Estimated next: 7 Jul”. Recorded on 7 Jun as done on 6 Jun → next 6 Jul.

---

## D-CSM-023 — Fixed-schedule rules (2026-09-29)

**Status:** Frozen

| Rule | Detail |
|------|--------|
| Stored slots | Every slot (date × time of day) from **today − 3 days** through **today** not yet closed, plus every slot of the **next series date after today** (unless paused or past the end date), plus any `planned` extras. These are real rows created by commands and the care tick |
| Dates | `schedule_anchor_date + n × interval`, clamped (D-CSM-024), never chained from the previous date |
| Overdue | From the slot's time (or the end of its day when untimed) until the **next slot of the series** is due |
| Not recorded | Once the next slot is due, a still-open slot shows **Not recorded** and joins the **stack** |
| Stack window | Slots with `scheduled_date < today − 3` are closed by the care tick as `skipped` with `close_reason = 'not_recorded'` |
| Record later | From History, a Not recorded slot can be **recorded as given** (becomes `completed`); it is never reopened, so the tick never closes it again |
| Review the stack | “Record earlier doses”: **Given** → `completed` (date = slot date unless changed); **Not given** → `skipped` with `close_reason = 'user'` (a statement, not unknown) |
| Counting | The stack counts **slots**: “3 doses not recorded” (medication) or “3 not recorded” (other care) |
| Done or skipped | Never moves another date |

No leeway period: a slot is Overdue as soon as its time passes. Users change the following date if they need to.

---

## D-CSM-024 — Month-end clamp (2026-09-29)

**Status:** Frozen

When the anchor's day does not exist in the target month, use the month's last day: 31 Jan → 28/29 Feb → **31 Mar** (always from the anchor, never from the clamped date); 29 Feb yearly → 28 Feb in non-leap years. After-it's-done dates use the same clamp from the done date. Replaces the JavaScript/Dart month overflow (31 Jan + 1 month = 3 Mar).

---

## D-CSM-025 — Plan another date (2026-09-29)

**Status:** Frozen

- Any item can get extra **planned** occurrences: **Plan another date** on the Care Item view; **+ Add a booster date** in the form for vaccination.
- **Change date** moves an occurrence; **Plan another date** adds one.
- A date within half an interval of another open occurrence warns first (“Another date is already planned for 5 Jun. Add this one too?”).
- Vaccines: first dose 1 Jun, booster 1 Jul, then yearly After it's done. First dose done → the booster is next (no computed date). Booster done → computed = booster date + 1 year.
- Deleting the only planned date: the rule creates the next one and the user confirms the date.
- Fixed schedule: a planned date is a one-off extra, independent of the series.

---

## D-CSM-026 — Done after the due date, with a waiting date (2026-09-29)

**Status:** Frozen

**Trigger:** an occurrence is done after its due day or time, another open `planned` or `schedule` occurrence waits, and the gap to it has shrunk by **more than half** of the originally planned gap (`waiting.scheduled − closed.scheduled`; minutes for timed slots, days otherwise).

**Choice:** **Keep [date]** (pre-selected, and the result of dismissing) · **Skip [date]** · **Move this and following by [N]** (Fixed schedule: new anchor; After it's done: shifts the waiting planned dates) · ☐ **Remember my choice for this care item** → `health_entries.late_completion_choice` (`keep` | `skip_next` | `shift_following`; `null` = ask). Shown and resettable in Advanced settings as **“If done after the due date”**.

**Ask before saving:** one command, one commit.

1. `POST …/occurrences/:occId/complete { completed_on, next_choice?, remember_choice? }`.
2. When the trigger fires, no `next_choice` is sent and none is remembered, the server **saves nothing** and answers **409 `next_choice_required`** with `{ waiting_occurrence, shift, options }`.
3. The app asks, then re-sends the same request with `next_choice` (and `remember_choice: true` when ticked).
4. Completion, choice and remembered preference commit in **one transaction**. Undo reverses all of it.

A retry after a lost response gets **409 `occurrence_not_open`**; the app reloads the item. No medical advice in the copy (D-CIE-004).

---

## D-CSM-027 — Changing a date (2026-09-29)

**Status:** Frozen

| Schedule type | Change date |
|---------------|-------------|
| Fixed schedule | Ask **This date only** (default: the slot becomes `planned`, the series is untouched; it cannot move past the next series date) or **This and following** (new `schedule_anchor_date`; open future `schedule` slots are rebuilt; `planned` ones stay) |
| After it's done | The occurrence moves and becomes `planned` |

**Amends:** D-ACP-007 and D-ACP-009 (re-anchoring by moving one date).

---

## D-CSM-028 — Postpone until: one mechanism (2026-09-29)

**Status:** Frozen

One command, **Postpone until [date]**; without a date it is **Pause**. Pause, pause until, absence **move after return** and moves beyond one step all use it. Ledger event `postponed { from, until, reason: pause | absence | manual, absence_id? }`.

| Schedule type | Postpone until a date | Pause (no date) | Resume |
|---------------|-----------------------|-----------------|--------|
| After it's done | The open occurrence moves to the date (`planned`) | `status = 'paused'`; the open occurrence stays, hidden from lists and reminders | Ask the date; default = step from the open date by the interval until on or after today |
| Fixed schedule | `status = 'paused'`, `paused_until = date`; open future slots before it close as `paused`; the tick resumes on the date | Same with `paused_until = null` | Ask the date; default = first series slot on or after now |

- Past dates are rejected (400).
- Pausing only hides the item. The care tick keeps applying the 3-day window to a paused Fixed-schedule item; the Care Item view shows “Paused since …” and any “N doses not recorded · Review”; History keeps “Record as given”.
- D-CSM-005 (no catch-up) holds.

**Amends:** D-CSM-005, D-CIE-018 (lifecycle), absence `move_after` (D-ACP-011).

---

## D-CSM-029 — Undo reverses the whole command (2026-09-29)

**Status:** Frozen

Undo reverses the **last command** as a whole: reopen the closed occurrence; delete the `computed` occurrence the command created **only if it is still `computed`**; never delete `planned` or `schedule` occurrences; reverse a next-date choice applied in the same command. Deleting the weight entry of a weigh-in is the undo of that completion. Postpone, pause and resume restore the previous state from the ledger.

---

## D-CSM-030 — Early completion (2026-09-29)

**Status:** Frozen

Any open occurrence can be marked done early, from any surface. The app confirms when it is **more than half an interval early** (“Planned for 12 Mar. Mark it as done today?”). After it's done: the next date counts from the completion date. Fixed schedule: other dates are unchanged. Stored with `completion_timing = 'early'`.

---

## D-CSM-031 — Care tick (2026-09-29)

**Status:** Frozen

A job runs **every 15 minutes** (`server/scripts/care/care_tick.js`, host cron, `pg_try_advisory_lock`, idempotent):

- Fixed-schedule items get the slots that became due plus the next series date.
- Stack slots older than three days close as `not_recorded`.
- Items whose `paused_until` has arrived resume.
- All in the pet's home timezone.

**Every command runs the same catch-up for its item first**, so data is correct even when the tick is late or not running. The tick handles **one item per transaction** (`SELECT … FOR UPDATE SKIP LOCKED`), never holds two item locks and never waits on a user command. It never creates `computed` occurrences.

---

## D-CSM-032 — Edits go through commands (2026-09-29)

**Status:** Frozen

`PUT /api/health-entries/:id` no longer writes `next_due_date`. Schedule fields are applied by commands:

| Field | Applied as |
|-------|-----------|
| First / next date | Change date on the open occurrence |
| Frequency, interval | Cadence change “this and following” from today (D-CSM-006) |
| Schedule type | Confirmed switch. Fixed → After it's done: every open `schedule` slot closes as `not_recorded`, `planned` dates stay, and if nothing is open the rule creates the next date from the last completion. After it's done → Fixed: planned dates stay, the anchor is the open date, slots are generated without duplicates |
| Times of day | Rebuild today's and the next date's open slots |
| End date | Close occurrences after it |
| Start date | Locked once anything is closed (`start_date_locked`) |

`next_due_date` stays on the wire as a read-only cache (D-CSM-019).

---

## D-CSM-033 — One lock and one transaction per command (2026-09-29)

**Status:** Frozen

- Every command runs inside `withCareItemLock` (transaction + `SELECT … FOR UPDATE` on the item). Audit, activity and notifications run **after commit**.
- Closing an occurrence that is no longer open → **409 `occurrence_not_open`**. Two carers completing the same slot: one 200, one 409; different slots: both 200.
- A future command touching several items must lock them in ascending `health_entry_id` order.
- **Write-path guard:** no `INSERT` / `UPDATE` / `DELETE` on `health_occurrences` outside `server/lib/care/occurrence/**` (migrations excluded; seeds call commands). Enforced by `scripts/check_occurrence_writes.js` in `./scripts/pre-push.sh`.
- Compatibility routes (`mark-taken`, `ensure-open`, the `pause` wrapper, `skip-missed`, legacy `undo-complete`) exist only until the new client ships and are then deleted — there are no installed clients to protect.
