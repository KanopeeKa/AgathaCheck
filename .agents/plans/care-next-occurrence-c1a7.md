# Care Item occurrences: always-real next dates, two schedule types, one agenda — roadmap plan (v2)

> **Status: DRAFT FOR REVIEW (v2, 2026-09-29).** Not approved for `/execute-plan`. Written for Cursor to review, together with the product owner. v2 replaces v1 after three rounds of product decisions (§3). Review checklist: §15.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-next-occurrence-c1a7` |
| **plan_kind** | `roadmap` (parent orchestrator; six child plans, §10) |
| **title** | Every active Care Item always has real, actionable occurrences; two plain schedule types; one Today / Due soon / Upcoming agenda; Absences use the same primitives |
| **author** | Claude Code session, with the product owner (2026-09-29) |
| **created / revised** | 2026-09-29 (v1) · 2026-09-29 (v2) |
| **base_branch** | `main` (each child uses its own integration branch, §10) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **programme_ref** | `docs/domains/pet_care/features/care-item-evolution.md` (canonical Care Item spec) |
| **reviewed commit** | `f6b6285` (`main`, 2026-09-29) — all file:line references are against this commit |
| **supersedes** | PR [KanopeeKa/AgathaCheck#1439](https://github.com/KanopeeKa/AgathaCheck/pull/1439) — **closed** 2026-09-29 with a pointer to this plan |
| **amends (child A)** | D-CSM-001, D-CSM-004, D-CSM-005, D-CSM-018, D-ACP-003, D-ACP-007, D-ACP-009, D-ACP-010, D-CIE-002, D-CIE-006, D-CIE-018; `occurrence-scheduling.md`; `care-schedule-management.md`; `care-item-evolution.md`; `terminology.md` |

### Changes since v1

| Area | v1 | v2 (agreed) |
|------|----|-------------|
| Open occurrences | Exactly one open day per item ("one open day" rule) | At least one open occurrence always; **several allowed** (planned dates, fixed-date stacks); at most one **computed** date |
| Schedule types | Fixed vs after completion, with a tolerance rule for lateness | **Fixed dates** (stack if missed) vs **Counts from when it's done** (late until done); **defaults by category**; user can change |
| Late | Tolerance bands; optional leeway | **Late is late** (no leeway). Fixed: Late until the next dose, then **Not recorded** (stack, 3 days) |
| Pause | Resume moves head | **One "Postpone until" primitive** for pause, pause-until, absence "move after" and long moves; resume asks the date with a default |
| Irregular care | Not covered | **Plan another date** (boosters, booked visits) — planned dates take precedence over computed ones |
| Late completion | Not covered | Prompt when a waiting date gets too close: **Keep / Skip next / Move this and following**, with **Remember my choice** per item |
| Moving a fixed date | Always re-anchors (D-ACP-007) | Ask **This date only** (default) / **This and following** |
| Lists | Overdue / Today / This week / Later | **Today** (late first, then grouped by time only when useful) / **Due soon** (7 days) / **Upcoming** (collapsed) |
| Background job | None | **Care tick** every 15 min (fixed-date items + 3-day stack window), plus per-command catch-up |
| Form | Not covered | **Advanced settings** (collapsed, one-line summary); **Plan shows Due date only, Record shows Completed on only** (bug fix) |
| DB guard | Optional `btree_gist` constraint | Dropped (rule no longer "one open day") |

---

## 1. Goal

1. **Every active planned Care Item always has at least one real, stored open occurrence** that can be acted on immediately (Mark as done, Skip, Change date, Postpone), created in the same transaction as the action that needs it — no placeholders, no "ensure first".
2. **Two schedule types users understand**, with safe defaults per category:
   - **Fixed dates** — every scheduled date gets its own occurrence; missed ones stack so each can be recorded or skipped.
   - **Counts from when it's done** — one open occurrence; if late it stays late until done; the next date counts from when it was done.
3. **Irregular care is simple**: add another planned date (booster, booked visit); planned dates take precedence; the schedule rule resumes when nothing planned remains.
4. **One agenda everywhere** (dashboard = pet profile): **Today** (late first), **Due soon**, **Upcoming**.
5. **One postpone mechanism** used by pause, pause-until and Absences.
6. **One Care Item component** in server and Flutter with a public API (child F).
7. **Canonical documentation updated first** (child A), so every later PR implements a frozen spec.

### 1.1 Product owner requirements (verbatim, 2026-09-29)

| # | Requirement |
|---|-------------|
| R1 | "I want to immediately see the next date even if it is far in the future." |
| R2 | "The occurrence needs to be materialised then and … I want to be able to manipulate that next occurrence immediately." |
| R3 | "That should also help making the 'absence' management easier." |
| R4 | "I must see the next occurrence of every care item I have for my pet, from the moment I close one occurrence … There is no delay (or a few seconds acceptable)." |
| R5 | "Organised cleanly under the Care Item Component domain with clean interactions that we can make evolve." |
| R6 | Late behaviour "updatable by the user (but provide a safe, clean default based on categories)." |
| R7 | "Pausing 'until' should be … the unique implementation of what happens when there's an absence and the user postpones a specific item … Avoid multiple implementation." |
| R8 | Irregular occurrences: "on Vaccine make it clear a user can simply create another fixed occurrence, THEN start yearly recurrence." |
| R9 | "If we tick 'plan something' → show due date — if we tick 'record something' → show 'completed on' — do not show both." (fix inside the domain amendment, not a separate PR) |

---

## 2. Vocabulary (used throughout; copy in §5.4)

| Term | Meaning | Storage |
|------|---------|---------|
| Care item | The lasting definition of care for one pet | `health_entries` |
| Occurrence | One scheduled or performed instance | `health_occurrences` |
| Open occurrence | Not yet done or skipped | `status = 'pending'` |
| Schedule type **Fixed dates** | Dates follow the calendar rule regardless of completion | `recurrence_anchor = 'from_due_date'` (wire value unchanged) |
| Schedule type **Counts from when it's done** | Next date = completion date + interval | `recurrence_anchor = 'from_completion'` (wire value unchanged) |
| Origin `schedule` | Date generated by a Fixed dates rule | `health_occurrences.origin` (new) |
| Origin `computed` | Next date computed for a Counts-from-done item | `origin` |
| Origin `planned` | Date set by a person: another date, a moved date, a postponed date, a booster, a booked visit | `origin` |
| Stack | Open past occurrences of a Fixed dates item waiting to be recorded | derived |
| Care tick | The 15-minute job (§6.6) | `server/scripts/care/care_tick.js` (new) |

---

## 3. Decision record (product owner answers, 2026-09-29)

| Topic | Decision |
|-------|----------|
| Late behaviour | Configurable per item with category defaults; two schedule types (§5.1) |
| Category defaults | Medication → Fixed dates. Vaccination, parasite prevention, wellness review and all other categories → Counts from when it's done |
| Fixed dates, late | Late until the next dose is due; then **Not recorded** and stacked so it can be recorded later (forgot to log ≠ forgot to give) |
| Counts from done, late | Late until done / skipped / postponed; the following date moves with today while late; when done, next = done date + interval |
| Stack window | Keep the **last 3 days** open; older ones close as Not recorded, can be recorded from History |
| Leeway | **None.** "Late is late." Users can change the following date instead |
| Two words | Yes — **Late** and **Not recorded** (amends D-CIE-002) |
| Month-end | Clamp to the last day of the month |
| Early completion | Allowed everywhere; confirm when more than half an interval early |
| Resume after pause | Ask the date; default = what it would have been without the pause. "Pause until" optional (default no end date) |
| Pause until | Is the single postpone implementation, shared with Absences |
| Lists | **Today** (Late first, then due today grouped Morning/Afternoon/Evening/Anytime only when ≥ 2 groups; otherwise "Today's list") / **Due soon** (this week) / **Upcoming** (collapsed). Dashboard and pet profile identical. "Mark as done" button, not a tick |
| Doses closing | Yes, but re-openable to record (fixed dates only) |
| Server "today" | Yes (pet home timezone) |
| Cron | Yes |
| Several open occurrences | Yes. Planned/fixed dates take precedence; if nothing further exists, the Counts-from-done logic resumes |
| Irregular care / boosters | Allowed everywhere as "Plan another date"; made obvious on vaccines (booster, then yearly) |
| Late completion with a waiting date | Offer **Keep** / **Skip next** / **Move this and following**, plus **Remember my choice** for that care item |
| Moving a fixed date | Ask **This date only** (default) / **This and following** |
| New Care Item window | Collapsed **Advanced settings** with one-line summary: Where, Priority, Schedule type, When done late, Provider (outside Notes), Documents. **Main section keeps**: first due date, dosage (medication), notes |
| Plan/Record date bug | Fix inside the form rework (child D), not a separate PR |
| Canonical docs | Update decisions and canonical documentation first (child A) |

---

## 4. Current state (verified facts at `f6b6285`)

F1 was reproduced with the server's own `advanceSeries` test harness (monthly item completed on its due date → no next occurrence, `next_due_date = null`).

### 4.1 Server — write paths

| id | Fact | Evidence | Consequence |
|----|------|----------|-------------|
| F1 | After a close, the next occurrence is inserted only if due by tomorrow (T−1) or already past | `server/lib/care/schedule/advanceSeries.js:90-96`; `server/lib/occurrenceScheduling.js:100-103` | Weekly/monthly/yearly items done on time get no next occurrence |
| F2 | `next_due_date` is recomputed from pending rows only; none → `NULL` | `server/lib/occurrenceScheduling.js:156-173` | The next date disappears everywhere |
| F3 | No T−1 job exists anywhere in `server/` | `grep -rn "setInterval\|node-cron\|cron.schedule" server/lib server/routes` → none | `occurrence-scheduling.md:83` and D-CSM-004 (`care-schedule-management-decisions.md:67`) describe behaviour that never runs |
| F4 | Create defers the first occurrence when the due date is beyond T−1 | `server/lib/occurrenceScheduling.js:65-76, 212-228`; `server/routes/healthEntries/crudRouter.js:216-221` | New future items cannot be completed (falls back to `mark-taken` → 400) |
| F5 | `PUT /api/health-entries/:id` writes `next_due_date`, `start_date`, `frequency`, `recurrence_anchor`, `repeat_end_date` directly | `server/routes/healthEntries/crudRouter.js:237-401` (UPDATE at `:352`) | Item and occurrences diverge after an edit |
| F6 | Resume only flips status | `server/lib/care/schedule/pauseResumeSeries.js:81-110` | Resumed item may have no occurrence |
| F7 | Reopen sets `next_due_date = NULL`, creates nothing | `server/routes/healthEntries/completionRouter.js:218-254` | Reopened item has no occurrence |
| F8 | Undo complete/skip reopens the closed row only; weight-entry delete does the same | `server/lib/care/schedule/undoLastAction.js:139-163`; `server/routes/weightEntries.js:207-229` | Needs origin-aware undo (§5.9) |
| F9 | Care commands are many separate `pool.query` calls; only weight completion/deletion use a transaction; `server/lib/db/withTransaction.js` exists but no care command uses it | `completeWeightRouter.js:135-173`; `weightEntries.js:207-229` | Partial writes; concurrent Done can double-advance |
| F10 | Only DB guard: unique pending slot per (entry, date, time) | `db/migrations/047_health_occurrences.sql:30-36` | Fine for v2 (several open dates are now allowed) |
| F11 | `POST /:id/mark-taken` returns 400 without a pending row; `completeOldestPendingOccurrence` lives in a route file | `completionRouter.js:18-73`; `occurrencesRouter.js:425` | List "Done" fails on items without a stored occurrence |
| F12 | Month arithmetic overflows (31 Jan + 1 month = 3 Mar; 29 Feb + 1 year = 1 Mar); fixed schedules chain from the previous date | `server/lib/recurrenceHelper.js:43-73` (`setMonth` `:56-58`); Dart copy `flutter_app/lib/features/health_tracking/domain/services/recurrence_advance.dart:16-45` | Permanent drift |
| F13 | Two next-date functions | `recurrenceHelper.js:82-93` (`nextOccurrence`); `advanceSeries.js:32-39` (`resolveNextSeriesDate`) | Two sources of truth |
| F14 | Recommendations create path calls `materialiseInitialOccurrences` directly | `server/routes/careIntelligence/recommendationsRouter.js:109` | Extra create path |
| F15 | Category defaults: vaccination and parasite prevention → fixed; everything else (incl. medication) → after completion | `server/lib/care/schedule/recurrenceAnchorDefaults.js:12-31`; families in `server/lib/care/enums.js:3-12` | v2 flips these (D-CSM-020) |
| F16 | Absence resolution decisions include `move_before`/`move_after`, written after reschedules | `server/lib/care/absence/constants.js:1-10` | "Move after" will reuse Postpone (§5.8) |

### 4.2 Server — read paths

| id | Fact | Evidence | Consequence |
|----|------|----------|-------------|
| F17 | Reminders need non-null `next_due_date`; "today" = server clock | `server/lib/checkDueNotifications.js:84-96` | Reminders stop after on-time completions |
| F18 | Away-plan projection: after-completion item with no pending row and null next date → no row, no uncertainty | `server/lib/care/schedule/projectSchedule.js:294-351` | Item vanishes from away plans |
| F19 | Fixed projection without a pending row chains from `start_date`, ignoring re-anchoring | `projectSchedule.js:220-222` | Wrong planned dates |
| F20 | Absence design assumes an open head exists ("CSM normally keeps one open") | `away-care-planning-decisions.md:60`; `estimateOccurrences.js:33-46` | "Defensive" branch is the common case |
| F21 | "Today": pet home TZ (occurrence routes), server clock (reminders, absence planner), device clock (Flutter) | `occurrencesRouter.js:55`; `loadAbsenceCarePlan.js:46`; `checkDueNotifications.js:96`; `health_entry.dart:171-199` | Inconsistent statuses around midnight / across zones |
| F22 | List responses carry no occurrence data | `crudRouter.js:32-62` → `healthEntryToMap` (`server/routes/healthEntries/shared.js`) | Per-row fetches in Flutter |
| F23 | Seed `health-care.js` inserts entries without occurrences | `server/db/seeds/scenarios/health-care.js:~56` | Seeds violate the target invariants |

### 4.3 Flutter

| id | Fact | Evidence | Consequence |
|----|------|----------|-------------|
| F24 | Grouping hides future items beyond `remindDaysBefore` | `flutter_app/lib/features/pet_care/domain/services/care_temporal_grouping_service.dart:20-33` | Far-future items missing |
| F25 | Six different "due" rules across surfaces | `health_providers.dart:226-260`; `pet_profile/presentation/widgets/pet_list/due_events_section.dart:33-40`; `pet_profile/presentation/screens/widgets/manage_events_filters.dart:216`; `experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart:44-80`; `health_entry.dart:163-199`; `health_entry_status.dart:68-86`; `care_event_status_line.dart:38-49` | Same item visible on one screen, missing on another |
| F26 | Each list row fetches its own open occurrences | `health_tracking/presentation/widgets/care_event_row_host.dart:38-39` | N requests per list |
| F27 | Row "Done" falls back to legacy `mark-taken` | `pet_profile/presentation/widgets/pet_list/home_event_actions.dart:40-49`; `health_tracking/presentation/widgets/occurrence_care_actions.dart:73-76, 98-100`; `health_tracking/presentation/widgets/health_dashboard/health_dashboard_entry_list.dart:333-342` | 400s |
| F28 | Placeholder occurrences with empty id + "ensure first" | `health_tracking/presentation/widgets/occurrence_review_flow.dart:24-56` | Removed by D-CSM-019 |
| F29 | Global All care filters still read retired `health_history` | `experience/presentation/screens/pet_care/pet_care_due_events_screen.dart:215-233` | Depends on a retired table |
| F30 | Unreachable screens/widgets: `PetEventViewScreen`, `HealthDashboardScreen`, `PetEventsPreviewSection` | not referenced by router or other `lib/` code | Dead code |
| F31 | Client re-implements server rules (recurrence math; series-closed rule in a UI file) | `recurrence_advance.dart`; `health_tracking/presentation/widgets/pet_event_lifecycle.dart:10-24` | Against "backend authoritative" |
| F32 | Feature cycle: 44 files in `health_tracking` import `pet_care`/`pet_profile`/`experience`; 8 files in `pet_care` import `health_tracking` | grep over `flutter_app/lib/features/*` | Matches A04/A05 in `docs/architecture/reviews/active-codebase-review.md` |
| F33 | No timezone package; `Pet.homeTimezone` unused for status | `flutter_app/pubspec.yaml`; `pet_care/presentation/providers/care_temporal_grouping_providers.dart:15` | Server must supply "today" |
| F34 | **Bug:** in Plan mode the form shows both "Due date" and "Completed on"; the row only hides Due date in Record mode | `health_tracking/presentation/widgets/entry_due_completed_row.dart:55-73`; `health_tracking/presentation/widgets/health_entry_form/health_entry_form_content.dart:163-170` | Planned items can be saved as already completed |
| F35 | Schedule type toggle sits in the frequency section of the form | `health_entry_form/health_entry_frequency_section.dart:121` (`RecurrenceAnchorToggle`) | Moves to Advanced settings |
| F36 | UI word "Overdue" throughout (EN/FR) | `flutter_app/lib/l10n/app_en.arb:222, 233, 2290, 2311, 2323-2329` (+ `app_fr.arb`) | Copy migration to "Late" / "Not recorded" |

### 4.4 Every server call site that creates, removes or re-dates open occurrences

`materialiseInitialOccurrences` (`crudRouter.js:220`, `recommendationsRouter.js:109`); `advanceSeries` (`completeOccurrence.js:87`, `skipOccurrence.js:64`, `adjustCadence.js:114`, `undoLastAction.js:235`); `ensureOpenOccurrence` (`ensureOpenOccurrenceRouter.js:29`); `insertOccurrencesForDay` (`adjustCadence.js:~111`); `skipMissedOccurrences` (`occurrencesRouter.js:130, 239`); `closeHealthEntrySeries` / `skipAllPendingOccurrences` (`occurrenceLifecycle.js`); `reopenOccurrence` (`undoLastAction.js:~92`); weight delete reopen (`weightEntries.js:212-221`); `rescheduleOccurrence.js`; `pauseResumeSeries.js`; PUT edit (`crudRouter.js:237`); reopen route (`completionRouter.js:218`); migration backfill 047 (`server/scripts/migrations/047_health_occurrences_backfill.js`).

---

## 5. Target behaviour (decisions to freeze in child A)

Decision IDs continue the existing logs. Each decision states what it amends.

### 5.1 Schedule types and category defaults — D-CSM-019, D-CSM-020

**D-CSM-019 — Occurrence guarantee.** Every active planned Care Item always has **at least one** open occurrence (INV-1, §6.1). Occurrences are created synchronously inside the command that needs them. The T−1 materialisation window is removed. *Amends D-CSM-004 (T−1 part), D-CSM-018 (ensure-open becomes compatibility only), `occurrence-scheduling.md` §Materialisation.*

**D-CSM-020 — Two schedule types with category defaults.**

| Category (`care_family`) | Default schedule type |
|--------------------------|-----------------------|
| `medication` | **Fixed dates** |
| `vaccination`, `parasite_prevention`, `wellness_review`, `dental`, `weight_monitoring`, `grooming`, `nail_care`, `other` | **Counts from when it's done** |

The user can change the type per item (Advanced settings, §5.10). Items repeating several times a day require Fixed dates (validation `times_require_fixed_dates`). *Amends D-CSM-001 (vaccination and parasite prevention were fixed; medication was after completion). Rationale: parasite treatment labels say to give a missed dose and resume monthly from then; the next vaccine booster counts from the date given (already stated in D-ACP-007); medication needs a per-dose record.*

### 5.2 Occurrence origins and precedence — D-CSM-021

Every open occurrence has an **origin**: `schedule`, `computed` or `planned` (§2).

1. The app **never moves** `planned` or `schedule` occurrences on its own.
2. An item has **at most one** open `computed` occurrence.
3. After a close, if any other open occurrence exists, **no** computed occurrence is created. If none exists, the item's rule creates the next one (`computed` for Counts from done; `schedule` for Fixed dates).
4. Moving a `computed` occurrence (Change date, Postpone) turns it into `planned`.

### 5.3 Rules per schedule type — D-CSM-022, D-CSM-023, D-CSM-024

**D-CSM-022 — Counts from when it's done.**

| Event | Result |
|-------|--------|
| Done | If another open occurrence waits → it is next (late-completion check, §5.6). Else create `computed` = `completed_on + interval` (clamped) |
| Skipped | Same, computed from `max(scheduled_date, today) + interval` |
| Late (not done after its day/time) | Stays **Late** until done, skipped or postponed. No stack. The following date is shown as **Estimated: today + interval** and moves forward each day |
| Example | Due 5 Jun → next would be 5 Jul. On 7 Jun still not done: "Late · 5 Jun", "Estimated next: 7 Jul". Done on 6 Jun (recorded 7 Jun) → next 6 Jul |

**D-CSM-023 — Fixed dates.**

| Rule | Detail |
|------|--------|
| Which occurrences exist | Every slot of every series date from **today − 3 days** through **today** that is not yet closed, plus every slot of the **next series date after today** (unless paused or past the end date). Plus any `planned` extras |
| Late | A slot is **Late** from its time (or the end of its day when untimed) until the **next slot of the series** is due |
| Not recorded | After the next slot is due, a still-open slot shows **Not recorded** and belongs to the stack |
| Stack window | Slots older than **3 days** (`scheduled_date < today − 3`) are closed by the care tick as `skipped` with `close_reason = 'not_recorded'` |
| Record later | From History, a Not recorded slot can be **recorded as given** (becomes `completed` with its `completed_on`). No reopening to pending, so the care tick never re-closes it |
| Done / skipped | Never moves any other date |
| Dates | `schedule_anchor_date + n × interval`, clamped (D-CSM-024), never chained from the previous date |

**D-CSM-024 — Month-end clamp.** When the anchor's day does not exist in the target month, use the month's last day (31 Jan → 28/29 Feb → 31 Mar; 29 Feb yearly → 28 Feb in non-leap years). Counts-from-done additions use the same clamp.

### 5.4 Status words — D-CIE-024 (amends D-CIE-002, D-CIE-006)

| Word | When |
|------|------|
| **Coming up** | Before its day (or before its time on the day, for timed care) |
| **Due** | On its day / at its time |
| **Late** | After its time (timed) or its day (untimed). No leeway. Counts from done: until done/skipped/postponed. Fixed dates: until the next slot is due |
| **Not recorded** | Fixed dates only: the next slot is already due; waiting in the stack (≤ 3 days) or closed by the tick (older) |
| **Done**, **Skipped**, **Paused** | As today |

"Late" replaces "Overdue" in all user-facing copy (EN + FR). Stored statuses stay `pending` / `completed` / `skipped`; `close_reason` distinguishes `user`, `not_recorded`, `paused`, `covered`. Timing rule of D-CIE-003 (timed care) is unchanged apart from the word.

### 5.5 Plan another date (irregular care, boosters) — D-CSM-025

- Any item can get extra **planned** occurrences: **Plan another date** on the Care Item view, and in the form.
- **Change date** moves an existing occurrence; **Plan another date** adds one. They are different actions.
- Adding a date within half an interval of an existing open occurrence warns: "Another date is already open on 5 Jun. Add anyway?"
- **Vaccines:** the form shows **"Needs a booster first?"** (e.g. + 1 month). Example: first dose 1 Jun, booster planned 1 Jul, yearly Counts from done. First dose done → next is the planned booster (no computed date). Booster done, nothing planned → computed = booster date + 1 year.
- Completing a **later** open occurrence while an **earlier** one is still open (Counts from done): ask "The date on 1 Jun is still open: Mark it done / Skip it / Keep it". Fixed dates: slots are independent, no question.
- Deleting a planned date (cancelled appointment): if nothing else is open, the rule creates the next one and the user confirms the date.

### 5.6 Late completion with a waiting date — D-CSM-026

Trigger: an occurrence is done **late**, another open `planned` or `schedule` occurrence waits, and the gap to it has shrunk by **more than half** of the originally planned gap (`waiting.scheduled_date − closed.scheduled_date`). Time-based for timed slots, days otherwise.

Options:
- **Keep [date]** (default when dismissed)
- **Skip [date]**
- **Move this and following** by the lateness (Fixed dates: sets a new anchor, as §5.7 "This and following"; Counts from done: shifts every waiting planned date)
- ☐ **Remember my choice for this care item** → `health_entries.late_completion_choice` (`keep` | `skip_next` | `shift_following`; `null` = ask). Visible and resettable in Advanced settings as **"When done late"**.

For fixed multi-daily medication this is the pharmacist "almost time for the next dose" prompt (e.g. 08:00 dose given at 15:00 with 18:00 next).

The server completes first and returns `late_choice_needed` (with options) when the trigger fires and no remembered choice exists; the client then calls the choice endpoint (§7.2). A remembered choice is applied inside the completion transaction.

### 5.7 Moving dates — D-CSM-027 (amends D-ACP-007, D-ACP-009)

| Schedule | Change date | Scope |
|----------|-------------|-------|
| Fixed dates | Ask **This date only** (default: the occurrence becomes `planned`; the series is untouched) / **This and following** (new `schedule_anchor_date`; open future `schedule` occurrences regenerate) | "This date only" cannot pass the next series date (D-ACP-009 validation kept); further → offer "This and following" or Postpone |
| Counts from done | The occurrence moves and becomes `planned`; nothing else to move | Any future date |

### 5.8 Postpone until (single mechanism) — D-CSM-028 (amends D-CSM-005, D-CIE-018, absence `move_after`)

One command: **Postpone until [date]**, or with no date = **Pause** (paused indefinitely). Used by: Pause, Pause until, Absence "move after return", and moves beyond one step. Every use writes one ledger event `postponed { from, until, reason: pause | absence | manual, absence_id? }`.

| Schedule | Postpone until a date | Pause (no date) | Resume |
|----------|-----------------------|-----------------|--------|
| Counts from done | The open occurrence moves to the date (becomes `planned`); after it is done the rhythm continues from the completion | Item `status = 'paused'`; its open occurrence stays but is hidden from agenda and reminders | Ask the date. Default: step from the open occurrence's date by the interval until on/after today ("what it would have been"). The occurrence moves there |
| Fixed dates | `status = 'paused'`, `paused_until = date`; no new dates before it; open future `schedule` slots before it close as `paused`; the late stack stays; the care tick resumes on the date with the first series date on/after it | Same with `paused_until = null` | Ask the date. Default: first series date on/after today. Dates between are not created |

Past dates cannot be chosen. D-CSM-005 (no catch-up) still holds. `pauseSeries`/`resumeSeries` and the absence `move_after` write path become thin callers of this command.

### 5.9 Undo — D-CSM-029

Undo reverses the **whole last command** on the item:
- Complete/skip: reopen the closed occurrence; delete the `computed` occurrence that command created **if it is still `computed`** (untouched). `planned` and `schedule` occurrences are never deleted by undo — if the computed one was edited it became `planned` and stays (two open dates is valid in v2).
- A late-completion choice applied in the same command (skip next / shift following) is reversed with it (ledger-driven).
- Weight-entry deletion linked to a completion = undo of that completion.
- Postpone/pause/resume: restore the previous state from the ledger.

### 5.10 Early completion — D-CSM-030

Mark as done is allowed on any open occurrence from any surface. Confirmation when it is more than half an interval early ("This is due on 12 Mar. Mark it done now?"). Counts from done: next counts from the completion date. Fixed dates: other dates unchanged. `completion_timing = 'early'` (existing).

### 5.11 Care tick — D-CSM-031

A job every **15 minutes** (`server/scripts/care/care_tick.js`, run by cron on the host; `pg_try_advisory_lock` prevents overlap; idempotent):
1. Fixed-dates items: create slots that became due and the next series date (§5.3); close stack slots older than 3 days as `not_recorded`; auto-resume items whose `paused_until` is today or earlier.
2. Evaluates "today" per pet home timezone.

Every command runs the same **catch-up for its item first** (inside its lock), so correctness never depends on the tick's timing. Counts-from-done items need nothing from the tick.

### 5.12 Edits, cache, transactions — D-CSM-032, D-CSM-033

- **D-CSM-032:** `PUT /api/health-entries/:id` no longer writes `next_due_date`. Schedule fields are reconciled by commands: first/next date → Change date; frequency/interval → cadence change "this and following" from today; schedule type switch → §8 TS cases (with confirmation); times of day → rebuild open slots of today and the next date; end date → close occurrences after it; start date → locked once anything is closed (`start_date_locked`). `next_due_date` = earliest open occurrence date (derived cache, kept on the wire).
- **D-CSM-033:** every command runs in `withCareItemLock` (transaction + `SELECT … FOR UPDATE` on the item). Audit, pet activity and notifications run after commit. Closing a non-open occurrence returns **409** `occurrence_not_open`.

### 5.13 Agenda — D-CIE-025 (amends D-CIE-006 grouping)

Same layout on the **dashboard** (all pets) and the **pet profile** (one pet):

1. **Today**
   - **Late** first (both types). A Fixed-dates stack is one row: "3 doses not recorded" → review sheet (per dose **Given** / **Skipped**, plus **All given** / **Skip all**).
   - Then items due today, grouped **Morning** (< 12:00) / **Afternoon** (12:00–17:59) / **Evening** (≥ 18:00) / **Anytime**, with headings **only when at least two groups are non-empty**; otherwise one heading **"Today's list"**.
   - Items done today stay at the end, marked Done, until the day ends.
   - Each row has a **Mark as done** button.
2. **Due soon** — next 7 days after today.
3. **Upcoming** — later dates, collapsed, with a count.

Items repeating daily or more often appear only in **Today**. The reminder window never hides anything; it only drives notifications. Care Status ("worth a check") keeps its current rule.

### 5.14 Row and actions — D-CIE-026

One row component everywhere. Primary: **Mark as done**. Menu: **Skip**, **Change date**, **Postpone**, **Plan another date**, **View**. A multi-slot row acts on the most urgent open slot and opens the slot list when more than one slot is open.

### 5.15 New / Edit Care Item form — D-CIE-027 (fixes F34)

**Main section:** pet(s); **Plan something / Record something**; category; name; **dosage (medication only)**; repeat (frequency, times of day); **Plan → Due date only (required)** / **Record → Completed on only (required)**; reminder; notes; related health issue.

**Advanced settings** (collapsed; one-line summary, e.g. "At home · Essential · Counts from when it's done · When late: ask me"):
- Where
- Priority
- Schedule type: **Fixed dates** / **Counts from when it's done** (category default, §5.1)
- When done late: Ask me / Keep the next date / Skip the next date / Move this and following (§5.6)
- Provider (moved out of the Notes & documents box)
- Documents

Vaccination: **"Needs a booster first?"** helper (§5.5).

Category change updates only Advanced fields the user has not touched. Server: a **planned** create with `completed_on` → 400; a **record** create without `completed_on` → 400 (existing).

### 5.16 Server supplies "today" — D-CIE-028

List and detail responses include `as_of { date, time, timezone }` (pet home timezone) and a per-occurrence `status` (`coming_up` | `due` | `late` | `not_recorded`). The app shows them as delivered, may promote Due → Late locally for timed slots as minutes pass, and re-requests on app resume and every 15 minutes while a care surface is visible.

### 5.17 Absences — D-ACP-011 (supersedes D-ACP-010; amends D-ACP-003)

- Every active item has a real open occurrence with an id; `indeterminate_pending` only for paused items.
- **Plan another date** works inside a trip; "looked after by" attaches to real occurrences.
- **Move after return** = Postpone until (return + 1 day). **Move before** = Change date.
- Estimates only for Counts-from-done dates after the last open occurrence; Fixed-dates dates inside a window are computed from the anchor (`planned` basis) and stored as they become due (care tick) or when someone plans/assigns them.
- "Review date" no longer calls ensure-open.

---

## 6. Invariants and data model

### 6.1 Invariants

| id | Invariant | Enforced by |
|----|-----------|-------------|
| INV-1 | Every active planned item (`care_planning` ≠ `unplanned`, `status = 'active'`, not series-closed) has **≥ 1** open occurrence | `syncOpenOccurrences` after every command; DB property test; repair script |
| INV-2 | At most **one** open `computed` occurrence per item; a computed occurrence is only created when no other open occurrence exists | same |
| INV-3 | Fixed dates items: open `schedule` slots = exactly the set defined in D-CSM-023 at the item's `as_of` (after catch-up) | same + care tick |
| INV-4 | `status = 'completed'` or unplanned ⇒ no open occurrences. Paused ⇒ no **new** occurrences; existing ones hidden from agenda and reminders | commands |
| INV-5 | `next_due_date` = earliest open occurrence date (or null); only `syncNextDueDateFromOccurrences` writes it | tests |
| INV-6 | Commands hold `SELECT … FOR UPDATE` on the item inside one transaction | `withCareItemLock` |
| INV-7 | "Today" = pet home calendar day on every server path | `resolveOccurrenceAsOf` everywhere |
| INV-8 | No two open occurrences on the same (item, date, time slot) | existing unique index `047:30-36` |

### 6.2 Schema changes (child B, migration `083_care_occurrence_model`)

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `health_occurrences` | `origin` | `VARCHAR(16)` CHECK in (`schedule`,`computed`,`planned`) | backfilled (§6.3) |
| `health_occurrences` | `close_reason` | `VARCHAR(16)` NULL CHECK in (`user`,`not_recorded`,`paused`,`covered`,`system`) | null on open rows |
| `health_entries` | `schedule_anchor_date` | `DATE` NULL | Fixed dates anchor (D-CSM-023/024) |
| `health_entries` | `late_completion_choice` | `VARCHAR(16)` NULL CHECK in (`keep`,`skip_next`,`shift_following`) | null = ask |
| `health_entries` | `paused_until` | `DATE` NULL | Postpone until (fixed dates) |

Ledger (`care_schedule_events`) new types: `postponed`, `materialised` (with `cause`, `caused_by_occurrence_id`), `late_choice_applied`, `not_recorded_closed`, `schedule_scope_changed`. Existing `paused`/`resumed` rows stay readable.

### 6.3 Backfill (JS hook, same pattern as 047)

1. `origin`: open rows of Fixed-dates items → `schedule`; of Counts-from-done items → `computed`, or `planned` when a `rescheduled` ledger event targets the row.
2. `schedule_anchor_date` for Fixed-dates items = earliest open date, else `next_due_date`, else `start_date`.
3. **Category defaults:** reset `recurrence_anchor` to the new defaults (D-CSM-020). Allowed only because there is no production data (`care-schedule-management-decisions.md:14`; `docs/ops/prod-backup-restore-plan.md` says pre-launch). **Escalation item: reviewer + owner confirm.**
4. Run `syncOpenOccurrences` for every active planned item (creates missing occurrences, applies the 3-day stack window).
5. Idempotent; logs counts. Down migration drops the columns (pre-launch; documented).

Seeds (`server/db/seeds/scenarios/*.js`) call the same sync at the end; `server/test/db/seeds/*` assertions updated. Repair script `server/scripts/care/repair_occurrences.js --dry-run|--apply` reports INV-1…5 violations.

---

## 7. Architecture

### 7.1 Server layout (created in child B, completed in child F)

```
server/lib/care/
  schedule/                      # pure — no DB
    seriesRule.js                # entry row → { type: fixed|from_done|once, freq, interval, anchor, times, end, pausedUntil }
    seriesDates.js               # nth date from anchor, clamp, dates in window, next series date after T
    fixedSlots.js                # which schedule slots must be open at as_of (D-CSM-023)
    nextComputed.js              # Counts-from-done next date (D-CSM-022)
    lateCompletion.js            # trigger + options (D-CSM-026)
    occurrenceStatus.js          # coming_up | due | late | not_recorded at as_of
    …existing projectSchedule.js, estimateOccurrences.js, validateReschedule.js, scheduleFlexibility.js
  occurrence/                    # DB, transactional
    careItemLock.js              # withCareItemLock(pool, entryId, fn)
    occurrenceRepository.js
    syncOpenOccurrences.js       # restores INV-1…5 for one item at as_of (catch-up + create + close)
    commands/  complete.js  skip.js  recordAsGiven.js  changeDate.js  planAnotherDate.js
               postpone.js  resume.js  applyLateChoice.js  resolveStack.js  undo.js
    careTick.js                  # batch runner used by scripts/care/care_tick.js
  item/                          # child F (create, updateDetails, updateSchedule, finish, reopen, delete; list/get queries)
```

`advanceSeries.js`, `ensureOpenOccurrence.js`, `pauseResumeSeries.js`, `rescheduleOccurrence.js` become thin callers during child B and are removed in child F. Routes: parse → authorise → `withCareItemLock` → command → map → post-commit effects.

### 7.2 API (additive; installed clients keep working)

| Method | Path | Change |
|--------|------|--------|
| GET | `/api/health-entries[?pet_id=]`, `/api/health-entries/:id` | Add `open_occurrences[] { id, scheduled_date, scheduled_time, status, origin }`, `as_of`, `estimated_next { date, basis }` (Counts from done while late) |
| POST | `/:id/occurrences/:occId/complete` | Accept `next_choice?`; response adds `late_choice_needed?`, `open_occurrences`, `undo_token` |
| POST | `/:id/occurrences/:occId/skip` | Same response additions |
| POST | `/:id/occurrences` | **New** — Plan another date `{ scheduled_date, scheduled_time? }` |
| POST | `/:id/occurrences/:occId/reschedule` | Add `scope: 'this' \| 'following'` (default `this`) |
| POST | `/:id/occurrences/:occId/record` | **New** — record a Not recorded slot as given `{ completed_on }` |
| POST | `/:id/occurrences/resolve-stack` | **New** — `{ given: [ids], skipped: [ids] }` (replaces `skip-missed`, which stays as a wrapper) |
| POST | `/:id/late-choice` | **New** — `{ waiting_occurrence_id, choice, remember }` |
| POST | `/:id/postpone` | **New** — `{ until: date \| null, reason, absence_id? }` |
| POST | `/:id/resume` | Add `{ date }`; without it the default date is used (compat) |
| POST | `/:id/pause` | Compat wrapper → postpone `until: null` |
| POST | `/:id/occurrences/ensure-open` | Compat: returns current open occurrences, `created: false` |
| POST | `/:id/mark-taken` | Compat: completes the most urgent open slot; never 400 for active planned items |
| POST | `/:id/schedule/undo` | Origin-aware (§5.9) |

OpenAPI: add list/detail DTOs to `docs/architecture/openapi/pet-care-critical.json`; cases in `server/test/openapi/petCareContract.test.js`.

### 7.3 Flutter layout (created in child C, completed in child F)

```
flutter_app/lib/features/care_item/
  care_item.dart                 # public barrel — the only import other features use
  domain/     occurrence_status.dart  care_agenda.dart  schedule_type.dart
  data/       care_item_remote_datasource.dart  models/
  application/ care_items_controller.dart   # single owner of entries + open occurrences; optimistic updates
  presentation/
    agenda/     care_agenda_view.dart  today_section.dart  due_soon_section.dart  upcoming_section.dart
    row/        care_item_row.dart  care_item_actions_menu.dart
    sheets/     not_recorded_review_sheet.dart  late_choice_sheet.dart  change_date_scope_sheet.dart
                postpone_sheet.dart  resume_date_sheet.dart  plan_another_date_sheet.dart  early_completion_dialog.dart
    form/       (child D) advanced_settings_section.dart  schedule_type_field.dart  booster_helper.dart
    detail/     (child F moves the current care_item_detail/*)
```

Rule (child F): other features import only `features/care_item/care_item.dart`; checked by `scripts/check_care_item_boundary.sh`.

---

## 8. Case matrix (standard and edge) — each becomes a test

Dates are illustrative. "CFD" = Counts from when it's done; "FX" = Fixed dates.

### 8.1 Counts from done

| id | Case | Expected |
|----|------|----------|
| CFD-1 | Monthly flea due 5 Jun, done 5 Jun | Next `computed` 5 Jul, created in the same request |
| CFD-2 | Not done; today 7 Jun | "Late · 5 Jun"; "Estimated next: 7 Jul" |
| CFD-3 | Done on 6 Jun (recorded 7 Jun) | Next 6 Jul |
| CFD-4 | Skipped on 7 Jun | Next 7 Jul |
| CFD-5 | Done 20 May (16 days early of 30) | Confirmation dialog; next 20 Jun |
| CFD-6 | Yearly wellness review due 1 Mar, done 15 Apr | Next 15 Apr next year |
| CFD-7 | Daily brushing, not done for 3 days | One Late occurrence (no stack) |
| CFD-8 | "Twice a day, counts from done" | Rejected: `times_require_fixed_dates` (form prevents it) |
| CFD-9 | Created with due date 200 days away | Open occurrence exists; Mark as done works |

### 8.2 Fixed dates

| id | Case | Expected |
|----|------|----------|
| FX-1 | Twice daily 08:00/18:00, at 07:00 | Today's 08:00 and 18:00 and tomorrow's two slots exist; only today's are listed (Today) |
| FX-2 | 08:00 not logged at 12:00 | "Late · 08:00" |
| FX-3 | 08:00 still not logged at 18:01 | 08:00 → "Not recorded" (stack); 18:00 Due |
| FX-4 | Mon, Tue not logged; today Wed | Stack of 4 (review sheet); Wed slots Due |
| FX-5 | Window boundary: on Fri, Mon's slots | Closed by the tick as `not_recorded` (`scheduled_date < today − 3`) |
| FX-6 | Record a closed Not recorded dose from History | `completed`, `completed_on` kept; nothing else changes; tick does not touch it |
| FX-7 | Weekly Mondays, done Wednesday | Next Monday unchanged; no prompt (gap shrank 2/7 < half) |
| FX-8 | Weekly Mondays, done Saturday | Prompt: Keep Mon / Skip Mon / Move this and following by 5 days |
| FX-9 | Monthly injection not logged | Stack of 1; next month's slot created when due |
| FX-10 | Record next dose early | That slot completed; other dates unchanged; confirmation if > half interval early |
| FX-11 | End date passes | No slots after it; item finishes when nothing is open |

### 8.3 Month-end

| id | Case | Expected |
|----|------|----------|
| ME-1 | FX monthly anchored 31 Jan | 28 Feb (29 leap), 31 Mar, 30 Apr, 31 May |
| ME-2 | Every 6 months from 31 Aug | 28/29 Feb, 31 Aug |
| ME-3 | Yearly from 29 Feb 2028 | 28 Feb 2029 … 29 Feb 2032 |
| ME-4 | CFD monthly done 31 Jan | 28 Feb; then from each completion |
| ME-5 | FX "This and following" moved to 31 Oct | Anchor 31 Oct → 30 Nov, 31 Dec |

### 8.4 Planned dates and boosters

| id | Case | Expected |
|----|------|----------|
| PL-1 | Vaccine yearly CFD: first dose 1 Jun, booster planned 1 Jul | 1 Jun done → next = 1 Jul (no computed); booster done → computed 1 Jul next year |
| PL-2 | First dose done 20 Jun (due 1 Jun), booster 1 Jul waiting | Gap 11 < 15 → prompt Keep 1 Jul / Skip / Move by 19 days (→ 20 Jul) |
| PL-3 | Vet booked: Change date on the open computed 5 Jun → 20 Jun | Same occurrence, now `planned`; no second one |
| PL-4 | Plan another date 8 Jun while 5 Jun open | Warning (within half interval); add anyway → two open |
| PL-5 | CFD: mark the later 1 Jul done while 5 Jun still open | Ask: mark 5 Jun done / skip / keep |
| PL-6 | Delete the only planned date | Rule creates next; user confirms date (may be Late immediately) |
| PL-7 | FX: plan an extra one-off dose | `planned` occurrence independent of the series |

### 8.5 Postpone, pause, resume

| id | Case | Expected |
|----|------|----------|
| PP-1 | CFD postpone 5 Jun → 20 Jun | Occurrence at 20 Jun (`planned`); done 20 Jun → next 20 Jul |
| PP-2 | CFD pause; resume 1 Aug | Hidden while paused; resume sheet default 5 Aug (5 Jun + n months ≥ today); user picks 3 Aug |
| PP-3 | FX daily med postpone until 10 Jun (today 5 Jun) | 6–9 Jun not created; open future slots before 10 Jun closed `paused`; stack stays; tick resumes on 10 Jun |
| PP-4 | FX pause indefinitely; resume 20 Jun | Default = first series slot on/after now; dates between not created |
| PP-5 | Absence 10–15 Jun: "move after" on CFD flea due 12 Jun | Postpone until 16 Jun (reason `absence`, `absence_id`) |
| PP-6 | Postpone to a past date | 400 |
| PP-7 | Undo right after pause | Previous state restored |

### 8.6 Late choice and undo

| id | Case | Expected |
|----|------|----------|
| LC-1 | Remember "Skip the next date" on a medication | Later triggers skip automatically in the same transaction; Advanced shows "When done late: Skip the next date"; can reset to Ask |
| LC-2 | Dismiss the sheet | Keep; nothing remembered |
| UN-1 | CFD done → computed next → Undo | Reopen; computed next deleted |
| UN-2 | CFD done → next edited (now planned) → Undo | Reopen; planned kept (two open) |
| UN-3 | FX dose done → Undo | Reopen; nothing else |
| UN-4 | Done with "skip next" applied → Undo | Reopen and un-skip the next (whole command reversed) |
| UN-5 | Delete the weight entry of a weigh-in | Same as UN-1 |

### 8.7 Type switches and edits

| id | Case | Expected |
|----|------|----------|
| TS-1 | FX → CFD with 3 Not recorded + next scheduled | Confirm: latest Late one stays open, older close as `not_recorded`, future `schedule` slots removed |
| TS-2 | CFD → FX with a planned future date | Planned kept; anchor = open date; schedule slots generated; no duplicate slot |
| TS-3 | FX weekly → every 2 weeks | Cadence change "this and following" from today |
| TS-4 | Edit form changes the next date | Change date on the open occurrence (no direct `next_due_date` write) |

### 8.8 Agenda

| id | Case | Expected |
|----|------|----------|
| AG-1 | Only Anytime items today | Heading "Today's list", no sub-groups |
| AG-2 | Morning + Anytime items | Two headings |
| AG-3 | Late items | First in Today |
| AG-4 | Daily med after all doses done | Stays in Today as Done until the day ends; never in Due soon |
| AG-5 | Weekly item due in 3 days / 20 days | Due soon / Upcoming (collapsed) |
| AG-6 | Every-3-days item due tomorrow | Due soon |
| AG-7 | Stack of 3 | One row "3 doses not recorded" → review sheet |
| AG-8 | Pet profile | Same groups, one pet |
| AG-9 | Yearly vaccine due in 200 days, reminder 7 days | In Upcoming; no notification yet |

### 8.9 Absences, concurrency, time

| id | Case | Expected |
|----|------|----------|
| AB-1 | CFD done before a trip | Away plan lists it with its occurrence id |
| AB-2 | Plan a date inside the trip, looked after by Jamie | Real occurrence carries the assignment |
| AB-3 | FX twice-daily med over a 7-day trip | One rhythm row; dates from the anchor; slots stored as days arrive; carer records doses |
| AB-4 | Trip dates change | Resolution "needs review" (existing) |
| CR-1 | Tick overlaps itself | Advisory lock; no duplicates |
| CR-2 | Tick late by 2 hours | Next command on the item catches up first |
| CR-3 | Pet timezone differs from server | Day boundaries per pet timezone |
| CR-4 | Two carers complete the same slot | One 200, one 409 |
| CR-5 | Two carers complete different stack slots | Both 200 |

### 8.10 Form

| id | Case | Expected |
|----|------|----------|
| FM-1 | Plan mode | Only Due date (required) |
| FM-2 | Record mode | Only Completed on (required); switching mode clears the hidden field |
| FM-3 | API planned create with `completed_on` | 400 |
| FM-4 | Advanced collapsed | One-line summary matches values |
| FM-5 | Category change | Updates untouched Advanced fields only |
| FM-6 | Medication | Dosage in the main section; not for other categories |
| FM-7 | Vaccination | Booster helper creates a planned date |
| FM-8 | Multi-time-of-day + Counts from done | Not selectable |

---

## 9. Canonical documentation changes (child A)

| File | Change |
|------|--------|
| `docs/domains/pet_care/changes/care-schedule-management-decisions.md` | Add D-CSM-019…033; mark amended parts of D-CSM-001, 004, 005, 018 |
| `docs/domains/pet_care/features/care-schedule-management.md` | Primitives table (sync, commands, care tick), HTTP table (§7.2), anchor defaults (§5.1), remove T−1 |
| `docs/domains/health_tracking/changes/occurrence-scheduling.md` | Rewrite §Materialisation, §Zones & sort, §Surfaces for origins, stack, statuses |
| `docs/domains/pet_care/features/care-item-evolution.md` (canonical) | D-CIE-024…028; update tables "Where we start", "Occurrence status", "Needs attention", "Completing care", "Schedule", "Absences" (Review date, Move after), Lifecycle (Pause until) |
| `docs/domains/pet_care/changes/away-care-planning-decisions.md` | D-ACP-011; amend D-ACP-003, 007, 009; supersede D-ACP-010 |
| `docs/domains/pet_care/features/care-context.md` | Absence ↔ postpone link |
| `docs/design/terminology.md` | Late, Not recorded, Fixed dates, Counts from when it's done, Plan another date, Postpone |
| `docs/design/care-item-view-ui.md` | Agenda layout, row actions, sheets, form Advanced settings |
| `docs/architecture/api-reference.md` | §7.2 |
| `.agents/memory/health-entry-completion.md` + `MEMORY.md` | Replace stale `health_history`/sentinel description |

---

## 10. Child plans and phases

Order: **A → B → C → D → E → F**. Branches: integration `cursor/<child>-integration-c1a7`, phase `cursor/<child>-<phase>-c1a7`. Commits `phase(<n>/<m>): <type>: <description>`. Each child ends with one PR integration → `main` via `/babysit-uat`. Children estimated above 48h are split at approval.

### Child A — `care-occurrence-spec-c1a7` (docs only)

**Outcome:** the canonical Care Item and scheduling documents describe the v2 behaviour; later PRs implement a frozen spec.

| Phase | Scope | exit_checklist |
|-------|-------|----------------|
| A1 | All §9 files; decisions §5 pasted with IDs; case matrix §8 copied into `occurrence-scheduling.md` as the acceptance table | `governance` |

**allowed_paths:** `docs/**`, `.agents/memory/**` · **forbidden:** `server/**`, `flutter_app/**`, `.github/**` · **exceptions:** `docs`
**Exit:** `bash scripts/validate_docs.sh` green; owner approval on the PR.

### Child B — `care-occurrence-engine-c1a7` (server)

**Outcome:** after any action, every active planned item has real, correct open occurrences; fixed dates stack and clamp; postpone, plan-another-date, late choice and scoped moves work through the API; reminders and away plans see everything.

| Phase | Scope | exit_checklist |
|-------|-------|----------------|
| B1 | Pure `schedule/*` (seriesRule, seriesDates with clamp, fixedSlots, nextComputed, lateCompletion, occurrenceStatus) + table tests (§8.1–8.3, LC) | `default` |
| B2 | Migration 083 (§6.2) + backfill hook (§6.3) + seeds + repair script | `single-backend-route` (+ **escalation: migration, category-default reset**) |
| B3 | `withCareItemLock`, `syncOpenOccurrences`, route transactions, post-commit effects, 409s | `single-backend-route` |
| B4 | Rewire every path in §4.4: create (incl. recommendations), complete, skip, stack resolve, record, undo (§5.9), PUT reconcile (D-CSM-032), close/reopen, weight complete/delete, mark-taken and ensure-open compat | `single-backend-route` |
| B5 | New commands + routes: plan another date, change date with scope, postpone/resume, late choice (§7.2) | `single-backend-route` |
| B6 | Care tick runner + `server/scripts/care/care_tick.js` + ops note for the cron entry (coordinate with `docs/ops/prod-backup-restore-plan.md`) | `default` |
| B7 | Readers: reminders in pet TZ, skip paused; projection/planner "today" in pet TZ; list/detail DTO additions (§7.2 GET) | `single-backend-route` |
| B8 | DB integration tests `server/test/db/careOccurrences.integration.test.js`: property test (≥ 500 random steps, fixed seed) asserting INV-1…5; CR-1…5; migration idempotency; repair dry-run | `default` |
| B-int | Integration → `main` | `bdd-journey` |

**allowed_paths:** `server/lib/care/**`, `server/lib/occurrenceScheduling.js`, `server/lib/occurrenceLifecycle.js`, `server/lib/recurrenceHelper.js`, `server/lib/checkDueNotifications.js`, `server/lib/petHomeTimezone.js`, `server/routes/healthEntries/**`, `server/routes/weightEntries.js`, `server/routes/careIntelligence/recommendationsRouter.js`, `server/scripts/migrate.js`, `server/scripts/migrations/083_*`, `server/scripts/care/**`, `server/db/seeds/**`, `db/migrations/083_*`, `docs/architecture/openapi/**`, `docs/**`
**forbidden:** `flutter_app/**`, `.github/workflows/**`, `server/routes/careContext/**`
**exceptions:** `tests`, `docs`, `backend-route`, `file-split`

**Exit criteria:**
- [ ] Property test green in the PostgreSQL CI job ("Backend integration (PostgreSQL)" runs `server/test/db`)
- [ ] CFD-1, CFD-9, FX-1…FX-11, ME-1…5, PL-1…7, PP-1…7, LC-1…2, UN-1…5, TS-1…4 as Jest tests
- [ ] `mark-taken` and `ensure-open` compat never 400 for active planned items
- [ ] Reminder created for a due-soon occurrence after an on-time completion one interval earlier
- [ ] Away plan (existing endpoints) lists a CFD item done before the trip (AB-1)
- [ ] Repair dry-run on seeded DB: 0 violations
- [ ] `./scripts/pre-push.sh` green; files ≤ 500 lines

**Compatibility:** response additions only; installed clients regain next dates, reminders and a working Done immediately. Wire values of `recurrence_anchor` unchanged.

### Child C — `care-agenda-c1a7` (Flutter lists, row, sheets)

**Outcome:** dashboard and pet profile show Today / Due soon / Upcoming with the same rows and actions; every action hits a real occurrence.

| Phase | Scope | exit_checklist |
|-------|-------|----------------|
| C1 | `care_item` feature scaffold; models parse `open_occurrences`, `as_of`, `estimated_next`; single owner controller; no per-row fetch (F26) | `default` |
| C2 | `occurrence_status.dart` + `care_agenda.dart` (§5.13); delete the six old rules (F25) and `recurrence_advance.dart` usage in lists | `default` |
| C3 | Agenda view on dashboard (`experience/…/pet_care_upcoming_events_section.dart`, `pet_care_today_orientation.dart`, `pet_care_today_header.dart`, `pet_care_dashboard_helpers.dart`), pet profile (`pet_profile/presentation/widgets/pet_care_section/*`), global and per-pet All care (`global_events_list.dart`, `pet_care_due_events_screen.dart` minus `health_history` (F29), `all_care/*`), pet list (`due_events_section.dart`), nav badge (`events_nav_icon_button.dart`) | `flutter-screen-split` |
| C4 | Row + menu (§5.14); sheets: not recorded review, late choice, change date scope, postpone, resume date, plan another date, early completion; remove `mark-taken` client paths (F27) and placeholders (F28) | `flutter-screen-split` |
| C5 | Copy EN + FR: Late, Not recorded, groups, sheets (F36) | `default` |
| C6 | BDD `care_occurrences.feature` (AG-*, CFD-1/2, FX-2/3/4, PL-1, PP-1/2, UN-1) + Playwright `e2e/playwright/tests/care.occurrences.spec.ts`; update `flutter_app/test/bdd/features/health_tracking.feature` scenarios "Empty guardian due-events inbox shows all caught up", "Due events appear on the pet list screen", "No due events shows all caught up", "Marking a health entry as taken", "Multi-dose daily medication shows stack sheet for recording doses", "Undoing a completed entry", and retire "Snoozing a health entry" | `bdd-journey` |
| C-int | Integration → `main` | `bdd-journey` |

**allowed_paths:** `flutter_app/lib/features/{care_item,health_tracking,pet_care,pet_profile,experience}/**`, `flutter_app/lib/l10n/**`, `flutter_app/test/**`, `e2e/**`, `docs/**` · **forbidden:** `server/**` (except test fixtures), `.github/workflows/**` · **exceptions:** `tests`, `docs`, `file-split`

**Exit:** AG-1…9 widget tests; zero client calls to `/mark-taken`; one status function in `lib/`; BDD gate green; `flutter analyze`; `flutter test --exclude-tags=integration`.

### Child D — `care-item-form-c1a7` (form + detail actions)

**Outcome:** creating and editing a Care Item matches §5.15; the Plan/Record date bug is gone; boosters and planned dates are easy.

| Phase | Scope | exit_checklist |
|-------|-------|----------------|
| D1 | Plan → Due date only; Record → Completed on only; clear hidden field on switch (`entry_due_completed_row.dart`, `health_entry_form_content.dart`); server 400 for planned create with `completed_on` (`crudRouter.js` + `server/lib/care/taxonomy/classification.js`) | `flutter-screen-split` (+ `single-backend-route`) |
| D2 | Advanced settings section with one-line summary; move Where, Priority, Schedule type (`RecurrenceAnchorToggle`, F35), Provider, Documents; add "When done late"; category defaults applied to untouched fields | `flutter-screen-split` |
| D3 | Vaccination booster helper; Plan another date on the Care Item view; schedule summary uses server data (no client date math) | `flutter-screen-split` |
| D4 | Tests FM-1…8; BDD/Playwright for booster (PL-1) and plan/record modes | `bdd-journey` |
| D-int | Integration → `main` | `bdd-journey` |

**allowed_paths:** `flutter_app/lib/features/{care_item,health_tracking}/**`, `flutter_app/lib/l10n/**`, `server/routes/healthEntries/crudRouter.js`, `server/lib/care/taxonomy/**`, tests, `e2e/**`, `docs/**` · **forbidden:** `flutter_app/lib/features/{experience,pet_profile}/**`, `.github/workflows/**`

### Child E — `care-absence-real-occurrences-c1a7`

**Outcome:** Absences use real occurrences, Postpone and Plan another date; no placeholder or ensure-first paths remain.

| Phase | Scope | exit_checklist |
|-------|-------|----------------|
| E1 | `expandItemForWindow(item, openOccurrences, lastClosed, window, asOf)` → `[{ date, time, basis, occurrence_id? }]` | `default` |
| E2 | Projection, estimate, presentation, planner, per-item absence context, coverage use E1; delete unreachable branches (`presentation.js:116-130`, `projectSchedule.js:294-351` null-head paths, `from_completion_pending` for active items) keeping wire fields | `single-backend-route` |
| E3 | `move_after` → Postpone (`reason: absence`); "Review date" without ensure-open; planned dates + looked-after-by inside trips | `single-backend-route` |
| E4 | One read model `buildAbsenceCareView` behind the existing endpoints (split into its own child if > 48h) | `single-backend-route` |
| E5 | Flutter: away plan rows always have an occurrence id; remove `ensure_open_occurrence_result.dart` usage | `flutter-screen-split` |
| E6 | Corpus (`server/test/careContext/carePeriodProjectionCorpus.js`: AB-1, fixed moved then completed), BDD `care_item_absence.feature`, Playwright `care.item.absence.spec.ts`, `away.care.planning.spec.ts` | `bdd-journey` |
| E-int | Integration → `main` | `bdd-journey` |

**allowed_paths:** `server/lib/care/{schedule,absence,planner,awayPlan}/**`, `server/lib/care/carePeriod*.js`, `server/routes/careContext/**`, `server/routes/healthEntries/absenceContextRouter.js`, `flutter_app/lib/features/{care_item,health_tracking,pet_care}/**`, tests, `e2e/**`, `docs/**` · **forbidden:** `server/lib/care/occurrence/**`, `db/migrations/**`, `.github/workflows/**`

### Child F — `care-item-module-c1a7` (architecture)

**Outcome:** Care Item code lives in one component per side with a public API and an enforced boundary; dead code gone.

| Phase | Scope | exit_checklist |
|-------|-------|----------------|
| F1 | Flutter: move care-item files from `health_tracking`, `pet_care/domain` grouping and `pet_profile/domain/services/care_status_service.dart` into `features/care_item/`; barrel; imports | `flutter-screen-split` |
| F2 | Delete dead code (F30) and tests; move rules out of widgets (`pet_event_lifecycle.dart`, `health_entry_status.dart`) | `flutter-screen-split` |
| F3 | `scripts/check_care_item_boundary.sh` wired into `pre-push.sh` — **governance change, needs human approval** | `governance` |
| F4 | Server: move `lib/occurrenceScheduling.js`, `lib/occurrenceLifecycle.js`, `lib/recurrenceHelper.js` into `lib/care/*`; add `lib/care/item/*`; remove thin callers; thin routes | `single-backend-route` |
| F5 | "Care Item" component entry in `docs/architecture/index.md` (owned tables, public API, commands, queries, errors, dependencies, side effects) | `governance` |
| F-int | Integration → `main` | `bdd-journey` |

No wire or table renames (installed clients).

---

## 11. Test strategy

| Level | What | Where |
|-------|------|-------|
| Pure unit | §8 date/rule cases | `server/test/careSchedule/*.test.js` |
| Command unit (mock pool with `connect()`, pattern `server/test/pets/helpers.js:46`) | Every command, origin rules, 409s, undo, late choice | `server/test/careSchedule/`, `server/test/healthEntries/` |
| DB integration (real PostgreSQL in CI) | Property test INV-1…5; CR-*; migration idempotency; tick overlap | `server/test/db/` |
| Contract | List/detail DTOs | `server/test/openapi/petCareContract.test.js` |
| Flutter unit/widget | Agenda builder, groups (AG-*), row actions, sheets, form (FM-*) | `flutter_app/test/features/care_item/**` |
| BDD + Playwright | Journeys listed per child | `flutter_app/test/bdd/features/`, `e2e/playwright/tests/` |
| Baselines kept green | CSM projection corpus + `integrationGate.test.js`; `server/test/careContext/*`; care-item widget tests | existing |

Tests that invert on purpose (document in PR): `advanceSeries.test.js:294` ("does not materialise outside T-1"), `materialiseInitialOccurrences.test.js`, pause/resume tests, D-ACP-007 re-anchor expectations, grouping tests that hid far-future items.

---

## 12. Risks

| Risk | Mitigation |
|------|------------|
| Fixed-dates stacks confuse users | 3-day window; one row + review sheet; "All given / Skip all" |
| Care tick not running on the host | Per-command catch-up keeps data correct; ops checklist + repair script |
| Category-default reset changes seeded items | Pre-launch only; escalation sign-off (§6.3) |
| Copy change Overdue → Late breaks E2E selectors | Child C updates BDD/Playwright in the same phase |
| Scope size | Six children; split any child estimated > 48h at approval |
| Absence endpoints change shape | Wire fields kept; contract tests |
| Concurrency | Row lock per item; 409 semantics; tests CR-4/5 |

## 13. Out of scope (follow-ups)

- Clinical vaccination courses and lapse rules (e.g. restart after 18 months) — copy hint only, later.
- "As needed" medication (use Record something).
- Push reminder delivery (D-CIE-021); reminder dedupe per due date (observation in v1).
- Carer notifications on missed doses (People + notifications tracks).
- Renaming `health_entries` / wire fields.

## 14. Small open points for the reviewer

1. Time-of-day boundaries (Morning < 12:00, Afternoon 12:00–17:59, Evening ≥ 18:00).
2. PL-5: ask (proposed) vs automatically close the earlier open date as `covered`.
3. Care tick interval (15 min) and host cron registration owner.
4. Whether "Late" replaces "Overdue" in every surface, including notifications and PDFs.
5. "Keep the last 3 days open" is written as: today plus the three calendar days before it stay open; anything with `scheduled_date < today − 3` closes. Confirm this reading.

## 15. Review checklist for Cursor

1. **Facts (§4):** re-check each F-row on `main`; flag wrong or already-fixed ones.
2. **Write paths (§4.4):** anything that creates, deletes or re-dates `health_occurrences` missing?
3. **Invariants (§6.1):** sufficient and testable? Any legitimate state forbidden (once items with several slots, weight rhythms, unplanned records, paused items with stacks)?
4. **Rules (§5):** challenge D-CSM-022/023/026 with concrete schedules (every 3 weeks, multi-dose, yearly on 29 Feb, backdated completion, late choice + undo).
5. **Origins (§5.2):** can an item end up with two `computed` or zero open occurrences through any sequence in §8?
6. **Care tick (§5.11):** idempotency, overlap, time zones, DST, catch-up cost.
7. **Transactions (§5.12):** deadlock risk for multi-item operations (stack resolve, absence planner acceptance, pet deletion).
8. **Migration (§6.2–6.3):** safety, idempotency, down strategy, category-default reset.
9. **API (§7.2):** additive for installed clients; payload size for pets with many items and stacks.
10. **Phases (§10):** overlapping `allowed_paths` between children; one outcome per phase; any phase > 48h.
11. **Tests (§11):** gaps, especially undo, PUT reconcile, pause/resume, time zones.
12. **UX (§5.13–5.15):** consistency with `care-item-evolution.md` and `docs/design/*`.

Record findings as a table (finding, severity, proposed change) under a new "## Review findings" heading in this file.

## 16. Sources

- Todoist — [recurring dates](https://www.todoist.com/help/articles/introduction-to-recurring-dates-YUYVJJAV), [complete a recurring task](https://www.todoist.com/help/articles/complete-a-task-with-a-recurring-date-dmI6SVqdP), [Upcoming view](https://www.todoist.com/help/articles/plan-your-week-with-the-upcoming-view-OKOg1mR8)
- Things — [Repeating To-Dos, Refined](https://culturedcode.com/things/blog/2026/08/repeating-to-dos-refined/), [Today/Upcoming](https://culturedcode.com/things/support/articles/4001304/)
- Apple — [Track your medications](https://support.apple.com/guide/iphone/track-your-medications-iph811670c81/ios); [TidBITS on grouping by time](https://tidbits.com/2022/10/07/an-apple-a-day-ios-16-medications-feature-provides-alerts-logging-and-peace-of-mind/)
- Medisafe — [Med-Friend](https://app.medisafe.com/tips/med-friend-in-need-is-med-friend-indeed/)
- Habitica — [Cron](https://habitica.fandom.com/wiki/Cron)
- Pet apps — [Pet Care Reminder & Tracker](https://apps.apple.com/ye/app/pet-care-reminder-tracker/id6444908248), [PetTimely](https://pettimely.app/)
- Vet software — [ezyVet standards of care and reminders](https://www.ezyvet.com/blog/how-to-use-ezyvets-standards-of-care-to-drive-client-compliance)
- Missed doses — [Healthline](https://www.healthline.com/health/missed-antibiotic-dose); parasite labels: [NexGard PLUS](https://animalhealth.boehringer-ingelheim.com/pets/canine/products/parasiticides/nexgard-plus), [Simparica (DailyMed)](https://dailymed.nlm.nih.gov/dailymed/fda/fdaDrugXsl.cfm?setid=91fc9ba1-35e6-4e37-8c37-c5e40699bd5b)
- Vaccines — [Vet Help Direct](https://vethelpdirect.com/vetblog/2021/04/01/how-long-can-pets-go-without-booster-vaccines/), [Today's Veterinary Practice](https://todaysveterinarypractice.com/preventive-medicine/dog-cat-vaccination-recommendations/)
- Calendar standards — [RFC 5545 recurrence](https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html), [RFC 7529](https://datatracker.ietf.org/doc/html/rfc7529); [Google Calendar recurring events](https://developers.google.com/google-apps/calendar/recurringevents)

---

## Runtime state (draft — not started)

```yaml
autonomy: draft
current_phase: null
last_completed_phase: null
halt_reason: "awaiting Cursor review (§15) and owner sign-off on §14 and §6.3 escalation"
next_action: "review; then create child plan files + snapshots + control issue"
artifact_ref:
  branch: claude/eager-edison-mf34j6
  plan_path: .agents/plans/care-next-occurrence-c1a7.md
  plan_commit: null
  snapshot_path: null
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
