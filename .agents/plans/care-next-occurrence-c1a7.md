# Care Item next-occurrence guarantee and care agenda — roadmap plan

> **Status: DRAFT FOR REVIEW.** Not approved for `/execute-plan`. Written to be reviewed by Cursor (and the product owner) before any snapshot, control issue or branch is created. See §14 for the review checklist.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-next-occurrence-c1a7` |
| **plan_kind** | `roadmap` (parent orchestrator; five child plans, §7) |
| **title** | Every active Care Item always has a real next occurrence; every surface shows it; Absences rely on it |
| **author** | Claude Code session (requested by product owner, 2026-09-29) |
| **created** | 2026-09-29 |
| **base_branch** | `main` (each child uses its own integration branch, §7) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **programme_ref** | `docs/domains/pet_care/features/care-item-evolution.md` |
| **reviewed commit** | `f6b6285` (`main`, 2026-09-29) — all file:line references in this plan are against this commit |
| **supersedes** | PR [KanopeeKa/AgathaCheck#1439](https://github.com/KanopeeKa/AgathaCheck/pull/1439) (close it; see §13) |
| **amends (on approval)** | D-CSM-004, D-CSM-018, D-ACP-003, D-ACP-010, `occurrence-scheduling.md` §Materialisation, `care-item-evolution.md` rows "Future occurrences" and Absences "Review date" |

---

## 1. Goal

Make the Care Item model behave the way the product owner and leading apps expect:

1. **Every active planned Care Item always has exactly one real, stored next occurrence** (one calendar day; several time slots for multi-dose care). It is created in the **same database transaction** as the action that needs it (create, done, skip, resume, schedule change, undo, reopen). No background job, no "day before" window, no delay.
2. **Every surface shows every active item's next occurrence**, ordered Overdue → Due today → Upcoming (far-future included): dashboard, pet profile, All care (global and per pet). The reminder window only controls notifications.
3. **The next occurrence can be acted on immediately from anywhere**: Mark as done, Skip, Change date — always against a real occurrence id.
4. **Absences get simpler and more robust** because the head is always real: no placeholder occurrences, no "ensure first", no "date unknown" for active items.
5. **The code is organised as one Care Item component** (server and Flutter) with a public API and enforced dependency direction, so the model can evolve.

### 1.1 Product owner's requirements (verbatim, 2026-09-29)

| # | Requirement |
|---|-------------|
| R1 | "As a user, I want to immediately see the next date even if it is far in the future." |
| R2 | "The occurrence needs to be materialised then and as a user, I want to be able to manipulate that next occurrence immediately." |
| R3 | "That should also help making the 'absence' management easier." |
| R4 | "Dashboard: … I want to see every overdue, due and upcoming occurrences: ie I must see the next occurrence of every care item I have for my pet, from the moment I close one occurrence, the next one is materialised as the new 'next occurrence'. There is no delay (or a few seconds acceptable)." |
| R5 | "I want the code architecture to be organised cleanly under the Care Item Component domain with clean interactions that we can make evolve." |

### 1.2 Acceptance scenarios (become BDD + Playwright, §10)

| id | Given | When | Then |
|----|-------|------|------|
| AC-1 | Monthly flea treatment due today, fixed schedule | I mark it done today | Within the same request the item shows "Coming up · <today + 1 month>" on the dashboard, pet profile and All care |
| AC-2 | Yearly vaccine due in 200 days, reminder 7 days before | I open the dashboard | The vaccine is listed under Later with its date; no reminder notification exists yet |
| AC-3 | Weekly ear drops (after completion), done today | I open the care item | "Coming up · in 7 days" with Mark as done, Skip, Change date enabled; each succeeds |
| AC-4 | Any upcoming item on the dashboard | I tap Mark as done | It completes the real next occurrence (no `mark-taken`), and the following occurrence appears |
| AC-5 | Item completed a moment ago | I tap Undo | The previous occurrence is reopened and the auto-created next occurrence is removed; exactly one open day remains |
| AC-6 | Item paused, then resumed | I resume | A next occurrence exists immediately (per D-CSM-023) and is visible everywhere |
| AC-7 | I edit an item's "next date" in the form | I save | The open occurrence moves to that date (reschedule), the cache matches, no second open day exists |
| AC-8 | After-completion item done today; trip starts in 10 days for 5 days | I open the away plan | The item is listed with its scheduled date (not missing, not "date unknown") |
| AC-9 | Two carers tap Done on the same occurrence at the same moment | Both requests arrive | One succeeds; the other gets a clear "already done" response; exactly one next occurrence exists |
| AC-10 | Fixed monthly item anchored on 31 Jan | It advances | Dates are 28/29 Feb, 31 Mar, 30 Apr, 31 May … (clamp), never drifting to the 3rd |

---

## 2. Current state (verified facts)

Every row was verified by reading code at `f6b6285`; F1 was also reproduced with the server's own `advanceSeries` test harness (monthly item completed on its due date → no next occurrence inserted, `next_due_date` = `null`).

### 2.1 Server — write paths

| id | Fact | Evidence | Consequence |
|----|------|----------|-------------|
| F1 | After a close, the next occurrence is inserted only if it is due **by tomorrow** (T−1) or already past | `server/lib/care/schedule/advanceSeries.js:90-96`, `server/lib/occurrenceScheduling.js:100-103` | Weekly/monthly/yearly items done on time get no next occurrence |
| F2 | `next_due_date` is recomputed from pending rows only; with none it becomes `NULL` | `server/lib/occurrenceScheduling.js:156-173` | The item's next date disappears everywhere |
| F3 | **No T−1 job exists.** No scheduler/cron in `server/`; the only callers of materialisation are user actions | `grep -rn "setInterval\|node-cron\|cron.schedule" server/lib server/routes` → none; callers listed in §2.4 | The docs' "whichever is first" (`occurrence-scheduling.md:83`) and D-CSM-004's "T−1 materialisation is sufficient" (`care-schedule-management-decisions.md:67`) describe something that never runs |
| F4 | Create defers the first occurrence when `next_due_date` is in the future beyond T−1 (keeps `next_due_date`, inserts no row) | `server/lib/occurrenceScheduling.js:65-76`, `:212-228`; `server/routes/healthEntries/crudRouter.js:216-221` | New future items have a date but nothing to act on; Done falls to `mark-taken` → 400 |
| F5 | `PUT /api/health-entries/:id` writes `next_due_date`, `start_date`, `frequency`, `recurrence_anchor`, `repeat_end_date` directly, without touching occurrences | `server/routes/healthEntries/crudRouter.js:237-401` (UPDATE at ~`:351`) | Edit form and occurrences diverge (cache says one date, pending row another, or none) |
| F6 | Resume only flips status; creates nothing | `server/lib/care/schedule/pauseResumeSeries.js:81-110` | Resumed item may have no next occurrence |
| F7 | Reopen sets `next_due_date = NULL`, creates nothing | `server/routes/healthEntries/completionRouter.js:218-254` | Reopened item has no next occurrence |
| F8 | Undo complete/skip reopens the closed row but never removes an occurrence the close created; weight-entry delete does the same | `server/lib/care/schedule/undoLastAction.js:139-163`; `server/routes/weightEntries.js:207-229` | Once F1 is fixed, undo would leave two open days unless undo removes the auto-created head |
| F9 | Care commands run as many separate `pool.query` calls with no transaction; only weight completion/deletion use `BEGIN` | `server/routes/healthEntries/completeWeightRouter.js:135-173`; `server/routes/weightEntries.js:207-229`; the mandatory runner `server/lib/db/withTransaction.js` exists but no care command uses it | A failure between "close" and "create next" leaves an item with no next occurrence; concurrent Done can double-advance |
| F10 | Only one DB guard: unique pending **slot** per (entry, date, time) | `db/migrations/047_health_occurrences.sql:30-36` | Nothing prevents two pending **days** for one entry |
| F11 | Legacy `POST /:id/mark-taken` returns 400 when there is no pending occurrence; business logic `completeOldestPendingOccurrence` lives in a route file | `server/routes/healthEntries/completionRouter.js:18-73`; `server/routes/healthEntries/occurrencesRouter.js:425` | List "Done" fails on every item without a stored next occurrence |
| F12 | Monthly/yearly arithmetic overflows: 31 Jan + 1 month = 3 Mar; 29 Feb + 1 year = 1 Mar; fixed schedules chain from the previous date, so drift is permanent | `server/lib/recurrenceHelper.js:43-73` (`setMonth` at `:56-58`); Dart copy `flutter_app/lib/features/health_tracking/domain/services/recurrence_advance.dart:16-45` | Wrong dates for month-end anchors |
| F13 | Two "next date" functions exist: `nextOccurrence` (legacy) and `resolveNextSeriesDate` | `server/lib/recurrenceHelper.js:82-93`; `server/lib/care/schedule/advanceSeries.js:32-39` | Two sources of truth |
| F14 | Recommendations create path calls `materialiseInitialOccurrences` directly | `server/routes/careIntelligence/recommendationsRouter.js:~109` | Another create path to route through the new command |

### 2.2 Server — read paths

| id | Fact | Evidence | Consequence |
|----|------|----------|-------------|
| F15 | Reminders only consider entries with non-null `next_due_date`; "today" is the server clock | `server/lib/checkDueNotifications.js:84-96` | Reminders silently stop after an on-time completion (F1+F2) |
| F16 | Away-plan projection: after-completion item with no pending row and null `next_due_date` yields **no row and no uncertainty** | `server/lib/care/schedule/projectSchedule.js:294-351` | The item vanishes from the away plan; coverage can falsely say nothing is scheduled (contradicts the intent of D-ACP-001) |
| F17 | Fixed-schedule projection without a pending row chains from `start_date`, ignoring D-ACP-007 re-anchoring | `server/lib/care/schedule/projectSchedule.js:220-222` | Wrong planned dates after a moved occurrence |
| F18 | Absence design assumes a head exists ("CSM normally keeps one open") | `docs/domains/pet_care/changes/away-care-planning-decisions.md:60`; estimate fallback `server/lib/care/schedule/estimateOccurrences.js:33-46` | The "defensive" branch is actually the common case today |
| F19 | "Today" has three meanings: pet home TZ (occurrence routes), server clock (reminders, absence planner), device clock (Flutter) | `server/routes/healthEntries/occurrencesRouter.js:55`; `server/lib/care/planner/loadAbsenceCarePlan.js:46`; `server/lib/checkDueNotifications.js:96`; `flutter_app/lib/features/health_tracking/domain/entities/health_entry.dart:171-199` | Same item can be Due on one surface and Overdue on another around midnight / across time zones |
| F20 | Health entry list responses carry no occurrence data | `server/routes/healthEntries/crudRouter.js:32-62` → `healthEntryToMap` (`server/routes/healthEntries/shared.js`) | Client fetches occurrences per row (F24) |
| F21 | Seed `health-care.js` inserts entries with no occurrences | `server/db/seeds/scenarios/health-care.js:~56` | Seeded UAT/dev data violates the target invariant |

### 2.3 Flutter

| id | Fact | Evidence | Consequence |
|----|------|----------|-------------|
| F22 | Entry grouping hides future items beyond `remindDaysBefore` | `flutter_app/lib/features/pet_care/domain/services/care_temporal_grouping_service.dart:20-33` | Far-future items missing from profile/All care/dashboard (PR #1439 targeted this only) |
| F23 | Six different list rules decide what is "due": grouping service (profile, All care, dashboard), `isEntryDueOrOverdue`/`guardianDueEntries`/`hasDueOrOverdueEventsProvider` (nav badge), `isOverdue‖isDueToday` (pet list), manage-events status predicate (global All care), entity getters (status lines) | `health_providers.dart:226-260`; `pet_profile/presentation/widgets/pet_list/due_events_section.dart:33-40`; `pet_profile/presentation/screens/widgets/manage_events_filters.dart:216`; `experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart:44-80`; `health_entry.dart:163-199`; `health_entry_status.dart:68-86`; `care_event_status_line.dart:38-49` | Same item visible on one screen, missing on another |
| F24 | Each list row fetches its own open occurrences | `flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row_host.dart:38-39` | One HTTP request per row |
| F25 | Row "Done" paths end in legacy `mark-taken` when no occurrence is loaded | `pet_profile/presentation/widgets/pet_list/home_event_actions.dart:40-49`; `health_tracking/presentation/widgets/occurrence_care_actions.dart:73-76, 98-100`; `health_tracking/presentation/widgets/health_dashboard/health_dashboard_entry_list.dart:333-342`; `experience/presentation/screens/pet_care/pet_care_upcoming_events_section.dart` | Done fails (400) on items without a stored next occurrence |
| F26 | Placeholder occurrences with empty id + "ensure first" step | `health_tracking/presentation/widgets/occurrence_review_flow.dart:24-56` | Complexity that only exists because the head may be missing |
| F27 | Global All care filters still read retired `health_history` rows | `experience/presentation/screens/pet_care/pet_care_due_events_screen.dart:215-233` (`histories` → `matchesManageEventsFilters`) | Filters depend on a table D-CSM-003 retired |
| F28 | Unreachable screens/widgets | `PetEventViewScreen` (`health_tracking/presentation/screens/pet_event_view_screen.dart`), `HealthDashboardScreen` (`…/health_dashboard_screen.dart`), `PetEventsPreviewSection` (`pet_profile/presentation/screens/widgets/pet_events_preview_section.dart`) — not referenced by the router or other `lib/` code | Dead code with its own rules and tests |
| F29 | Client re-implements server rules | recurrence math `recurrence_advance.dart`; series-closed rule in a UI file `health_tracking/presentation/widgets/pet_event_lifecycle.dart:10-24` | Violates "backend authoritative" (`.cursor/rules/pet-care-architecture.mdc`) |
| F30 | Feature cycle: 44 files in `health_tracking` import `pet_care`/`pet_profile`/`experience`; 8 files in `pet_care` import `health_tracking` | `grep` over `flutter_app/lib/features/*` | Matches A04 in `docs/architecture/reviews/active-codebase-review.md`; entries have several state owners (A05) |
| F31 | No timezone package in the app; `Pet.homeTimezone` is parsed but not used for status | `flutter_app/pubspec.yaml`; `pet_care/presentation/providers/care_temporal_grouping_providers.dart:15` (`careNowProvider = DateTime.now()`) | Client cannot compute pet-local "today" today |

### 2.4 Every server call site that creates or removes open occurrences (must all go through the new primitive)

`materialiseInitialOccurrences` (create: `crudRouter.js:220`, recommendations `recommendationsRouter.js:109`), `advanceSeries` (`completeOccurrence.js:87`, `skipOccurrence.js:64`, `adjustCadence.js:114`, `undoLastAction.js:235`), `ensureOpenOccurrence` (`ensureOpenOccurrenceRouter.js:29`), `insertOccurrencesForDay` (`adjustCadence.js:111`), `closeHealthEntrySeries`/`skipAllPendingOccurrences` (`occurrenceLifecycle.js`), `reopenOccurrence` (`undoLastAction.js:92`), weight delete reopen (`weightEntries.js:212-221`), reschedule (`rescheduleOccurrence.js`), pause/resume (`pauseResumeSeries.js`), PUT edit (`crudRouter.js:237`), reopen route (`completionRouter.js:218`), backfill migration 047 (`server/scripts/migrations/047_health_occurrences_backfill.js`).

---

## 3. Research summary (why this target)

| Pattern | Who | Applied here |
|---------|-----|--------------|
| One live next copy always exists; completing (even early) creates the next copy immediately | Things 3.23, Todoist | INV-1 (§4) |
| Two schedule types in plain words: fixed vs after completion | Todoist `every` / `every!`, Things | Keep `from_due_date` / `from_completion` |
| Never schedule a fixed series into the past: overdue completion jumps to the next future date | Todoist | D-CSM-021 |
| One-off change vs rule change | Things "Make Exception" / "Update Rule"; Google Calendar "This event / This and following / All events" | Keep reschedule vs adjust-cadence; label them that way |
| Per-dose Taken / Skipped with follow-up reminder | Apple Health Medications | Existing per-slot statuses |
| Sitters log care; owner sees who did it and is told about misses | pet reminder apps with household sharing, PetTimely, Medisafe Medfriend | Absence = hand-over, not pause (§8.4) |
| Helpers sign up for a specific task on a specific date | Lotsa Helping Hands | "Looked after by" on real occurrences (deferred, D-ACP-012) |
| Holiday = pause in productivity apps | Todoist vacation mode, Habitica, Streaks | Explicitly **not** the pet-care model |
| Store rule + exceptions; explicit month-end semantics; optional rolling horizon | RFC 5545 / RFC 7529; calendar design practice | D-CSM-022; horizon materialisation deferred |

Sources are listed in the review conversation and in §15.

---

## 4. Target invariants

Definitions:

- **Planned item**: `health_entries.care_planning IS DISTINCT FROM 'unplanned'`.
- **Active**: `status = 'active'` and not series-closed (`isEntrySeriesClosed`, `server/lib/occurrenceLifecycle.js`).
- **Slots**: `scheduleTimesFromEntry(entry)` — `schedule_times` or one all-day slot.
- **Head day**: the calendar date that holds the item's pending occurrence(s).

| id | Invariant | Enforced by |
|----|-----------|-------------|
| INV-1 | Every active planned item has pending occurrences on **exactly one** calendar date (its head day), covering every slot not yet closed that day. No pending row exists on any other date. | `ensureHead` at the end of every command (§6.2); row lock (INV-4); DB integration property test (§10.2); repair script |
| INV-2 | `status = 'completed'` ⇒ zero pending rows. `status = 'paused'` ⇒ the head row may remain but is hidden from agenda lists and reminders. Unplanned (recorded) items ⇒ zero pending rows. Once items: one pending row until closed, then the entry completes (existing `finalizeOnceEntryIfNoPending`). | Commands + tests |
| INV-3 | `health_entries.next_due_date` = head day for active planned items (never null), else null. It is **only** written by `syncNextDueDateFromOccurrences`. | Remove direct writes (F5, F7); unit tests |
| INV-4 | Every command that reads or writes an item's occurrences runs inside one transaction holding `SELECT … FROM health_entries WHERE id = $1 FOR UPDATE`. Post-commit effects (audit log, pet activity, notifications) run after commit. | `withCareItemLock` (§6.3) |
| INV-5 | "Today" for care is the pet's home calendar day (D-CIE-023) on every server path; clients receive it rather than guess it. | `resolveOccurrenceAsOf` everywhere (§6.5); `as_of` in list responses (§8.1) |

Optional DB-level guard for INV-1 (reviewer to decide, §12 Q7): `EXCLUDE USING gist (health_entry_id WITH =, scheduled_date WITH <>) WHERE (status = 'pending')` (needs `btree_gist`; confirm the o2switch PostgreSQL allows the extension).

---

## 5. Proposed decisions (frozen in child A, phase A0)

Wording below is ready to paste into `docs/domains/pet_care/changes/care-schedule-management-decisions.md` (D-CSM-*), `care-item-evolution.md` (D-CIE-*) and `away-care-planning-decisions.md` (D-ACP-*). Items marked **product** need the owner's explicit yes (§12).

### D-CSM-019 — Next-occurrence guarantee (supersedes the T−1 parts of D-CSM-004 and `occurrence-scheduling.md` §Materialisation)

Every active planned Care Item always has one stored head day (INV-1). The head is created synchronously in the same transaction as the action that needs it. The T−1 materialisation window (`isWithinMaterialisationWindow`) is removed from all write paths. D-CSM-004's actual concern — no pre-generation of `anchor+1` batches at create — still holds: only the **head** is stored, never a chain.

### D-CSM-020 — `ensureHead` is the only way open occurrences are created

One server primitive restores INV-1 at the end of every command (table in §6.2). `ensureOpenOccurrence` (D-CSM-018) becomes a thin compatibility wrapper that returns the existing head with `created: false`; its route stays for installed clients.

### D-CSM-021 — Next head date rules (**product**)

| Schedule | Action on head | Next head day |
|----------|----------------|---------------|
| Fixed (`from_due_date`) | Complete | First series date **strictly after** `max(closed.scheduled_date, completed_on)` |
| Fixed | Skip | First series date **on or after** `max(closed.scheduled_date + 1 day, today)` |
| After completion (`from_completion`) | Complete | `completed_on + interval` (may be in the past if a past completion date is recorded — honest overdue) |
| After completion | Skip | `max(closed.scheduled_date, today) + interval` |
| Any | Head closed while other slots on the same day are still pending | Head day unchanged |

Series dates passed over by a fixed-schedule jump are **not** stored as rows. One ledger event `auto_skipped_range { from, to, count }` records them so History can say "3 dates not logged between 1 and 3 Oct". Consequence: a backlog of several overdue **days** can no longer form; only several overdue **slots on the head day** (multi-dose). The multi-day stack UX simplifies accordingly (child B).

### D-CSM-022 — Series dates from a stored anchor; month-end clamp (**product**)

Fixed schedules compute the n-th date from `health_entries.schedule_anchor_date` (new column) as `anchor + n × interval`, never by chaining from the previous date. When the anchor's day does not exist in the target month, clamp to the month's last day (31 Jan → 28/29 Feb → 31 Mar); 29 Feb yearly → 28 Feb in non-leap years. D-ACP-007 re-anchoring (moving a fixed occurrence moves the following ones) sets `schedule_anchor_date` to the moved date. After-completion schedules add the interval to the completion date with the same clamp.

### D-CSM-023 — Pause and resume keep one head (**product**)

Pause keeps the head row (no data loss, trivial undo) but paused items are excluded from agenda lists and reminders and shown as "Paused since …". Resume (no catch-up, D-CSM-005): fixed → head moves to the first series date on or after today if it is in the past; after completion → head moves to today if it is in the past. The move is recorded as a `rescheduled` ledger event with `reason_code: resume`.

### D-CSM-024 — Editing the schedule goes through commands

`PUT /api/health-entries/:id` no longer writes `next_due_date`. Schedule fields are reconciled by one server function:

| Field changed in the form | Effect |
|---------------------------|--------|
| Next date | `rescheduleOccurrence` on the head (D-ACP-009 validation; beyond-one-hop moves become an explicit cadence change prompt in the client) |
| Frequency / interval / schedule type | `adjustCadence` effective today |
| Times of day | Head day's pending slots rebuilt (closed slots untouched) |
| End date | Head removed and series auto-closed if the head falls after the new end |
| Start date | Allowed only when nothing has been closed yet; otherwise 400 `start_date_locked` |

### D-CSM-025 — `next_due_date` is a derived cache

INV-3. Kept on the wire for installed clients and for reminders. Never written by routes directly.

### D-CSM-026 — Early completion (**product**)

Mark as done is allowed on any head, from any surface. The client asks for confirmation when the head is more than half an interval away ("This is due on 12 Mar. Mark it done now?"). The server records `completion_timing = 'early'` (existing).

### D-CSM-027 — Undo removes the head it created

Every close that creates a new head writes a ledger event `materialised { caused_by_occurrence_id }`. Undo of that close (and weight-entry deletion) deletes the head it created **if untouched** (no notes, photos, reschedule, looked-after-by), then reopens the closed row. If the new head was modified, undo returns 409 `next_occurrence_modified` and the client explains why.

### D-CIE-024 — Agenda rule on every surface

Every list shows every active planned item's head: Overdue → Due today → Upcoming (date ascending). The reminder window (`remind_days_before`) only drives notifications and the Care Status "worth a check" signal; it never hides an item. Dashboard groups: **Overdue**, **Today**, **This week**, **Later** (Later collapsed by default, count shown). The "All caught up" state means "nothing overdue or due today", and still lists what is coming up.

### D-CIE-025 — One row, same actions everywhere

One row component. Primary action: **Mark as done** (per D-CIE-009, overdue asks "When was this done?"). Overflow menu: **Skip**, **Change date**, **View**. Multi-dose rows act on the worst open slot and open the slot list when more than one slot is open.

### D-CIE-026 — Server supplies "today" (**product/tech**)

List and detail responses include `as_of: { date, time, timezone }` in the pet's home timezone, and per-slot `status` (`coming_up` | `due` | `overdue`) computed server-side. The client re-requests on app resume and every 15 minutes while a care surface is visible, rather than adding a timezone library. Alternative for review: add `timezone` package and compute locally (§12 Q6).

### D-ACP-011 — Absences read real heads

The head is always `date_basis: scheduled` with an `occurrence_id`. `indeterminate_pending` and `UNCERTAINTY_REASON_FROM_COMPLETION_PENDING` apply only to paused items. Estimates (`estimated`) apply only to hops **after** the head for after-completion items; planned dates (`planned`) come from `schedule_anchor_date` for fixed items. "Review date" no longer calls ensure-open (amends D-ACP-010 and the Absences table in `care-item-evolution.md`).

### D-ACP-012 — Absence-window materialisation (deferred)

Storing fixed-schedule dates inside an absence window so "looked after by" can attach to each occurrence is **out of scope**; revisit after child D (§11).

---

## 6. Server design (child A unless noted)

### 6.1 Module layout (created in A, completed in E)

```
server/lib/care/
  schedule/                 # pure, no DB
    seriesRule.js           # entry row → { kind: once|fixed|after_completion, freq, interval, anchorDate, times, endDate }
    seriesDates.js          # (child C) nthDate, firstOnOrAfter, firstAfter, datesInWindow, month-end clamp
    nextHead.js             # D-CSM-021 rules; pure; uses advanceByFrequency until child C swaps in seriesDates
    advanceSeries.js        # becomes a thin caller of occurrence/ensureHead (kept for imports), then removed in E
    … existing projectSchedule.js, estimateOccurrences.js, validateReschedule.js, scheduleFlexibility.js …
  occurrence/               # DB, transactional
    careItemLock.js         # withCareItemLock(pool, entryId, fn) = withTransaction + SELECT … FOR UPDATE
    headRepository.js       # loadPendingDays, loadLastClosed, insertHeadSlots, deleteHead, syncNextDueCache
    ensureHead.js           # the only function that creates/removes pending rows to restore INV-1
    assertHeadInvariant.js  # throws in test/dev; logs structured warning in prod
  item/                     # (child E) item-level commands + list query
```

### 6.2 `ensureHead(client, entry, { todayIso, cause, lastCloseContext })`

Pure decision + write, called as the **last step** of every command inside the lock:

1. Not planned, not active, or series-closed → delete stray pending rows (should be none), sync cache, return `{ head: null }`.
2. Paused → leave any head as is, sync cache, return.
3. Pending rows exist:
   - one day → keep; add missing slots only when `cause = times_changed`.
   - several days (legacy data) → keep the earliest; delete later days only when untouched; write ledger `normalised`; otherwise log and keep (repair script reports them).
4. No pending rows → compute the head date with `nextHead` (D-CSM-021) from `lastCloseContext` (or last closed row), or for a new item from `next_due_date ?? max(start_date, today)`; stop if beyond `repeat_end_date` (then `tryAutoCloseRecurringWithEndDate`).
5. Insert slots (`insertOccurrencesForDay`), write ledger `materialised { cause, caused_by_occurrence_id }`, `syncNextDueDateFromOccurrences`.

| Command | Where | Change |
|---------|-------|--------|
| Create | `crudRouter.js` POST, `recommendationsRouter.js` | Replace `materialiseInitialOccurrences` with `ensureHead(cause: created)`; remove `initialMaterialisationAnchor` deferral (keep explicit past `next_due_date` = overdue head) |
| Complete / skip | `completeOccurrence.js`, `skipOccurrence.js` | Replace `advanceSeries` materialisation with `ensureHead(cause: closed)` |
| Skip missed (same-day slots) | `occurrencesRouter.js:221` | Same |
| Reschedule | `rescheduleOccurrence.js` | Unchanged logic; add lock + `assertHeadInvariant`; for fixed items set `schedule_anchor_date` (child C) |
| Pause / resume | `pauseResumeSeries.js` | Resume applies D-CSM-023 then `ensureHead(cause: resumed)` |
| Adjust cadence | `adjustCadence.js:84-114` | Remove T−1 gate at `:109`; delete pending ≥ effective date; `ensureHead(cause: cadence_adjusted)` |
| Undo | `undoLastAction.js` | D-CSM-027 for complete/skip; cadence undo already calls `advanceSeries` → `ensureHead` |
| Close / reopen | `occurrenceLifecycle.js` `closeHealthEntrySeries`; `completionRouter.js:218` | Close unchanged (skips pending → zero); reopen calls `ensureHead(cause: reopened)` and stops writing `next_due_date` |
| Edit (PUT) | `crudRouter.js:237-401` | D-CSM-024 `reconcileSchedule` |
| Mark-taken (compat) | `completionRouter.js:18` | Complete the earliest pending slot on the head via the complete command; never 400 for active planned items; move `completeOldestPendingOccurrence` out of the route |
| Ensure-open (compat) | `ensureOpenOccurrence.js` | Returns current head (`created: false`) after `ensureHead` |
| Weight complete / delete | `completeWeightRouter.js`, `weightEntries.js:207-229` | Use the lock; delete applies D-CSM-027 |

### 6.3 Transactions and concurrency

- `withCareItemLock(pool, entryId, fn)` wraps `server/lib/db/withTransaction.js` and runs `SELECT * FROM health_entries WHERE id = $1 FOR UPDATE` first; `fn` receives the locked row and the client.
- Every command in §6.2 runs inside it. Audit (`logAuditEventSafe`), pet activity (`recordPetActivityForPet`) and notifications move **after** commit (align with Batch B3 "stable committed command results").
- Completing or skipping a non-pending occurrence returns **409** `occurrence_not_pending` (today it is a 400/404 mix — confirm and normalise).
- Route handlers become: parse → authorise → `withCareItemLock` → command → map → post-commit effects.
- Tests: mock pools must implement `connect()` (pattern exists: `server/test/pets/helpers.js:46`).

### 6.4 Backfill and repair

- Migration `db/migrations/083_care_next_occurrence.sql` (+ `_down.sql` no-op with explanation) registered in `server/scripts/migrate.js` with a JS hook `server/scripts/migrations/083_care_next_occurrence_backfill.js` (same pattern as 047) that, for every active planned entry, runs `ensureHead` inside `withCareItemLock`. Idempotent; logs counts (created, normalised, skipped-closed).
- Child C adds `084_schedule_anchor_date.sql` (column + backfill from current head for fixed items).
- Repair script `server/scripts/care/repair_next_occurrences.js --dry-run|--apply` for UAT and for the future prod launch; prints entries violating INV-1/INV-3.
- Seeds (`server/db/seeds/scenarios/*.js`) create heads through `ensureHead` (or call the repair function at the end of seeding); `server/test/db/seeds/*` assertions updated.
- Pre-launch note: `docs/ops/prod-backup-restore-plan.md` says `migrate.js up` runs on deploy without a snapshot; if prod launches before child A merges, run the repair in dry-run on a copy first.

### 6.5 Readers

- `checkDueNotifications.js`: use pet home TZ via `server/lib/petHomeTimezone.js`; skip paused items (INV-2). Observation for a debt issue: the unread-dedupe (`hasRecentUnread`) can suppress next month's reminder if the previous one was never read — key dedupe on `(entry, type, due date)`.
- `projectSchedule.js` / `loadAbsenceCarePlan.js` / `carePeriodCoverage.js`: switch `todayCalendarIso()` to pet TZ. Structural cleanup waits for child D.

---

## 7. Child plans and phases

Order: **A → B → C → D → E**. C may start after A merges if its paths stay disjoint from B (C is mostly server); D depends on C (`seriesDates`); E last.

Branch naming: integration `cursor/<child>-integration-c1a7`; phase `cursor/<child>-<phase>-c1a7`. Commits: `phase(<n>/<m>): <type>: <description>`. Each child: phase PRs → integration; one PR integration → `main` with `/babysit-uat`.

### Child A — `care-next-occurrence-core-c1a7` (server + docs; no Flutter)

**Outcome (one sentence):** after any action, every active planned Care Item has exactly one stored next occurrence, created in the same request, and reminders/away plans see it.

| Phase | Title | exit_checklist | Depends |
|-------|-------|----------------|---------|
| A0 | Decisions + docs | `governance` | — |
| A1 | Pure `nextHead` + `seriesRule` | `default` | A0 |
| A2 | `withCareItemLock` + `ensureHead` + route transactions | `single-backend-route` | A1 |
| A3 | Wire every write path (§6.2 table) incl. undo, resume, reopen, PUT reconcile, mark-taken compat | `single-backend-route` | A2 |
| A4 | Backfill migration 083 + repair script + seeds | `single-backend-route` (+ escalation: migration) | A3 |
| A5 | Readers: reminders + projection "today" in pet TZ | `single-backend-route` | A3 |
| A6 | DB integration property + concurrency tests | `default` | A4 |
| A-int | Integration → `main` | `bdd-journey` (pre-UAT) | all |

**A0 scope:** add D-CSM-019…027 to `docs/domains/pet_care/changes/care-schedule-management-decisions.md`; rewrite `docs/domains/health_tracking/changes/occurrence-scheduling.md` §Materialisation (head rule table from §6.2) and §Intent materialisation (compat note); update `docs/domains/pet_care/features/care-schedule-management.md` primitives table (`ensureHead`, ensure-open compat, mark-taken compat); add D-CIE-024…026 to `docs/domains/pet_care/features/care-item-evolution.md` and fix rows "Future occurrences", "Schedule — Next", Absences "Review date"; add D-ACP-011/012 and amend D-ACP-003 base text in `docs/domains/pet_care/changes/away-care-planning-decisions.md`; `docs/architecture/api-reference.md` (409 codes, compat notes); refresh stale `.agents/memory/health-entry-completion.md` (still describes `health_history` and sentinel dates) and add a `MEMORY.md` pointer.

**A1 scope:** `server/lib/care/schedule/seriesRule.js`, `nextHead.js` + `server/test/careSchedule/nextHead.test.js` (table-driven: every row of D-CSM-021 × daily/weekly/monthly/yearly/custom × early/on-time/late/very-late × with/without end date × multi-dose).

**A2 scope:** `server/lib/care/occurrence/{careItemLock,headRepository,ensureHead,assertHeadInvariant}.js`; migrate `advanceSeries.js` to delegate; wrap routes in `server/routes/healthEntries/{occurrencesRouter,completionRouter,rescheduleOccurrenceRouter,ensureOpenOccurrenceRouter,crudRouter,completeWeightRouter}.js` and `server/routes/weightEntries.js`; move post-commit effects after commit; tests `server/test/careSchedule/ensureHead.test.js`, update mock pools.

**A3 scope:** every row of the §6.2 table; delete `isWithinMaterialisationWindow` and `initialMaterialisationAnchor` deferral; `reconcileSchedule` for PUT; D-CSM-027 undo; 409 normalisation; update tests `advanceSeries.test.js` (the "does not materialise when next date is outside T-1 window" case at `:294` inverts), `materialiseInitialOccurrences.test.js`, `undoLastAction.test.js`, `pauseResumeSeries.test.js`, `adjustCadence.test.js`, `ensureOpenOccurrence.test.js`, `completeOccurrence.test.js`, `skipOccurrence.test.js`, `integrationGate.test.js`, `server/test/healthEntries.test.js`, `server/test/weightEntries.test.js`, `server/test/healthEntries/*`.

**A4 scope:** §6.4.

**A5 scope:** §6.5; tests `server/test/checkDueNotifications.test.js`, `server/test/careContext/*` corpus expectations that change because heads now exist (document each changed expectation in the PR).

**A6 scope:** `server/test/db/careNextOccurrence.integration.test.js` (runs in the "Backend integration (PostgreSQL)" CI job, which executes `test/db`): seeded pet; random sequences of create/complete/skip/undo/pause/resume/cadence/reschedule/edit/close/reopen with a fixed seed; assert INV-1…3 after every step; concurrency: two parallel completes on one head → one 200, one 409, one head.

**allowed_paths:**
```
server/lib/care/**
server/lib/occurrenceScheduling.js
server/lib/occurrenceLifecycle.js
server/lib/recurrenceHelper.js
server/lib/checkDueNotifications.js
server/lib/petHomeTimezone.js
server/routes/healthEntries/**
server/routes/weightEntries.js
server/routes/careIntelligence/recommendationsRouter.js
server/scripts/migrate.js
server/scripts/migrations/083_*
server/scripts/care/**
server/db/seeds/**
db/migrations/083_*
docs/domains/pet_care/**
docs/domains/health_tracking/**
docs/architecture/api-reference.md
.agents/memory/**
```
**forbidden_paths:** `flutter_app/**`, `.github/workflows/**`, `server/routes/careContext/**` (no absence route changes in A)
**allowed_exceptions:** `tests`, `docs`, `backend-route`, `file-split`

**Exit criteria:**
- [ ] INV-1…4 hold in the DB integration property test (≥ 500 random steps, fixed seed, CI)
- [ ] Monthly item completed on time → `GET /api/health-entries` returns `next_due_date` = +1 month in the same request
- [ ] New item with a date 200 days out has a pending occurrence; Mark done via occurrence API succeeds
- [ ] `mark-taken` on any active planned item succeeds (compat)
- [ ] `ensure-open` returns `created: false` for every active item after backfill
- [ ] Undo after complete leaves exactly one open day (AC-5); modified-head undo returns 409
- [ ] Reminder created for a due-soon head after an on-time completion one interval earlier
- [ ] Away plan (existing endpoints) lists an after-completion item done before the trip (AC-8)
- [ ] Repair script dry-run on seeded UAT DB reports 0 violations after migration
- [ ] `./scripts/pre-push.sh` green; file sizes ≤ 500

**Client compatibility:** no response shape change. Installed clients immediately regain next dates, reminders and working Done; lists still hide far-future items until child B.

**Rollback:** revert the integration PR; migration 083 is additive (rows only) and the down file is a documented no-op; the extra head rows are harmless to the old code (it reads earliest pending).

---

### Child B — `care-agenda-everywhere-c1a7` (API read addition + Flutter)

**Outcome:** the dashboard, pet profile and All care all list every active item's next occurrence in the same order, with the same actions, and no row fetches its own data.

| Phase | Title | exit_checklist |
|-------|-------|----------------|
| B1 | List/detail API embeds open occurrences + `as_of` + slot status | `single-backend-route` |
| B2 | Flutter model + single owner of entries/heads | `default` |
| B3 | `care_item` agenda domain: one status function, one agenda builder | `default` |
| B4 | Surfaces migrated (dashboard, profile, All care ×2, pet list, nav badge) | `flutter-screen-split` |
| B5 | One row + actions; remove `mark-taken` usage; early-completion confirm | `flutter-screen-split` |
| B6 | BDD + Playwright | `bdd-journey` |
| B-int | Integration → `main` | `bdd-journey` |

**B1:** `GET /api/health-entries[?pet_id=]` and `GET /api/health-entries/:id` add per entry:
```json
{
  "open_occurrences": [
    { "id": "uuid", "scheduled_date": "2026-10-29", "scheduled_time": "08:00", "status": "coming_up" }
  ],
  "as_of": { "date": "2026-09-29", "time": "14:05", "timezone": "Europe/Paris" }
}
```
One query with `LEFT JOIN LATERAL (… json_agg … WHERE status = 'pending' ORDER BY scheduled_date, scheduled_time)`; status per D-CIE-003 computed with the pet's TZ (`isOccurrenceMissed` + pet `as_of`). Additive only. Add the list/detail DTOs to `docs/architecture/openapi/pet-care-critical.json` and a case to `server/test/openapi/petCareContract.test.js`. Files: `server/routes/healthEntries/crudRouter.js`, `server/routes/healthEntries/shared.js`, new `server/lib/care/item/queries/listWithHeads.js`.

**B2:** `HealthEntryModel` parses `open_occurrences`/`as_of`; seed `entryOccurrencesProvider` from list data so `CareEventRowHost` stops fetching per row (F24); one canonical owner for entries (resolves A05 for care: `healthEntriesNotifierProvider` + derived selectors; `petHealthEntriesByIdProvider` derives from it).

**B3:** new `flutter_app/lib/features/care_item/` with `care_item.dart` (public barrel), `domain/care_slot_status.dart` (reads server status; recomputes only from `as_of` + elapsed minutes for timed slots), `domain/care_agenda.dart` (Overdue / Today / This week / Later). Delete or reduce to delegates: `HealthEntry.isOverdue/isDueToday/isDueSoon` (`health_entry.dart:171-199`), `isEntryDueOrOverdue`/`guardianDueEntries` (`health_providers.dart:226-251`), window logic in `care_temporal_grouping_service.dart:20-33`, `due_events_section.dart:33-40`, the status predicate in `manage_events_filters.dart:216`, `PetCareTodayCarePriorities` bucketing in `pet_care_dashboard_helpers.dart`. Care Status ("worth a check") keeps its reminder-window rule, now computed from the agenda.

**B4 surfaces (each gets a widget test proving the same far-future item appears):**

| Surface | File(s) |
|---------|---------|
| Dashboard Care block + counts + pet rail order | `experience/presentation/screens/pet_care/pet_care_upcoming_events_section.dart`, `experience/presentation/widgets/pet_care_today_orientation.dart`, `…/pet_care_today_header.dart`, `experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart` |
| Global All care (`/pc/events`) | `experience/presentation/screens/pet_care/global_events_list.dart`, `…/pet_care_due_events_screen.dart` (drop `health_history` dependency, F27) |
| Pet profile care section | `pet_profile/presentation/widgets/pet_care_section/*` |
| Per-pet All care (`/pet/:id/events`) | `pet_profile/presentation/widgets/all_care/*`, `pet_profile/presentation/screens/pet_manage_events_screen.dart` |
| Pet list due section (non-shell) | `pet_profile/presentation/widgets/pet_list/due_events_section.dart` |
| Nav badge | `health_tracking/presentation/widgets/events_nav_icon_button.dart` (badge = overdue or due today) |

Copy (EN + FR, `flutter_app/lib/l10n/app_en.arb`, `app_fr.arb`): group titles, "Later (n)", revised empty state ("Nothing due today" + next item), early-completion confirmation.

**B5:** evolve `CareEventRow` into `care_item/presentation/care_item_row.dart`; overflow menu Skip / Change date / View; Mark as done uses the head id; delete `MarkEntryTaken` usecase, `markEntryTakenProvider`, `HomeEventActions.commitCompletion`, the `mark-taken` fallback in `OccurrenceCareActions.persistCompletion`; multi-day stack sheet reduced to same-day slots (D-CSM-021); D-CSM-026 confirmation.

**B6:** update `flutter_app/test/bdd/features/health_tracking.feature` scenarios "Empty guardian due-events inbox shows all caught up", "Due events appear on the pet list screen", "No due events shows all caught up", "Marking a health entry as taken", "Multi-dose daily medication shows stack sheet for recording doses", "Undoing a completed entry" (and retire "Snoozing a health entry" if still present); new feature `care_next_occurrence.feature` with AC-1…AC-5, AC-9 (client side); new Playwright `e2e/playwright/tests/care.next.occurrence.spec.ts` with `/** @bdd … */` headers; `node e2e/scripts/check_bdd_coverage.js`.

**allowed_paths:** `flutter_app/lib/features/{care_item,health_tracking,pet_care,pet_profile,experience}/**`, `flutter_app/lib/l10n/**`, `flutter_app/test/**`, `server/routes/healthEntries/crudRouter.js`, `server/routes/healthEntries/shared.js`, `server/lib/care/item/**`, `server/test/**`, `docs/architecture/openapi/**`, `e2e/**`, `docs/**`
**forbidden_paths:** `server/lib/care/schedule/**` (except read helpers), `db/migrations/**`, `.github/workflows/**`
**allowed_exceptions:** `tests`, `docs`, `file-split`, `backend-route`

**Exit criteria:**
- [ ] One far-future item appears on dashboard, profile, global and per-pet All care (widget tests + AC-2 Playwright)
- [ ] Zero calls to `/mark-taken` from the Flutter client (`grep` in CI step of the PR)
- [ ] No per-row occurrence fetch on list surfaces (provider test)
- [ ] Only one status function in `lib/` (grep for the deleted names returns nothing)
- [ ] BDD gate green; `flutter analyze`; `flutter test --exclude-tags=integration`

---

### Child C — `care-schedule-dates-c1a7` (date correctness)

**Outcome:** fixed schedules produce correct dates at month-end and after moves; the client no longer does recurrence arithmetic.

| Phase | Title | exit_checklist |
|-------|-------|----------------|
| C1 | `schedule_anchor_date` column (migration 084) + backfill | `single-backend-route` (+ escalation: migration) |
| C2 | `seriesDates.js` (nth date, clamp, windows) + swap into `nextHead`, `projectSchedule`, `estimateOccurrences`, `validateReschedule`, `scheduleFlexibility` | `single-backend-route` |
| C3 | Remove `nextOccurrence` legacy and chained `advanceByFrequency` for fixed schedules | `default` |
| C4 | `GET /api/health-entries/:id/schedule-preview?count=` (next N dates with basis) + Flutter uses it; delete `recurrence_advance.dart` and client date maths in reschedule preview | `single-backend-route` |
| C-int | Integration → `main` | `bdd-journey` |

Tests: table cases 31 Jan monthly, 30 Aug every 6 months, 29 Feb yearly, every 2 months from 31 Aug, custom days, re-anchor after move (D-ACP-007), cadence change mid-series; projection corpus cases for F17. Flutter: `reschedule_occurrence_preview.dart` tests updated to use the endpoint.

**allowed_paths:** `server/lib/care/schedule/**`, `server/lib/recurrenceHelper.js`, `server/routes/healthEntries/**`, `db/migrations/084_*`, `server/scripts/migrate.js`, `server/scripts/migrations/084_*`, `flutter_app/lib/features/{care_item,health_tracking}/**`, `server/test/**`, `flutter_app/test/**`, `docs/**`
**forbidden_paths:** `flutter_app/lib/features/{experience,pet_profile}/**`, `.github/workflows/**`

**Exit criteria:** AC-10 green; zero recurrence arithmetic in `flutter_app/lib` (grep for `advanceByFrequencyIso`, `intervalDaysForEntry` returns nothing or only the preview adapter); corpus updated.

---

### Child D — `care-absence-real-occurrences-c1a7`

**Outcome:** absences read real next occurrences through one expansion function; no placeholder or "ensure first" paths remain.

| Phase | Title | exit_checklist |
|-------|-------|----------------|
| D1 | `expandItemForWindow(entry, head, lastClosed, window, asOf)` → `[{date, time, basis, occurrence_id?}]` in `server/lib/care/schedule/` | `default` |
| D2 | Route projection, estimate, presentation, planner, per-item absence context and coverage through D1; delete unreachable branches (`presentation.js:116-130` fallback, `projectSchedule.js:294-351` null-head branches, `from_completion_pending` for active items) keeping wire fields populated | `single-backend-route` |
| D3 | One absence read model `buildAbsenceCareView(absence, pets, asOf)`; existing endpoints (`carePeriodProjection`, `carePeriodCoverage`, `absenceCarePlan`, away-plan readiness/presentation, `GET /:id/absence-context`) format from it | `single-backend-route` |
| D4 | Flutter: remove ensure-open pre-step and empty-id placeholders (`occurrence_review_flow.dart`), "Schedule — Next" no-row fallback, `ensure_open_occurrence_result.dart` usage; away plan rows always have an occurrence id | `flutter-screen-split` |
| D5 | Corpus + BDD: `server/test/careContext/carePeriodProjectionCorpus.js` new cases (after-completion done before trip — previously vanished; fixed item moved then completed — previously chained from start); `care_item_absence.feature` "Review date" scenario updated; Playwright `care.item.absence.spec.ts`, `away.care.planning.spec.ts` | `bdd-journey` |
| D-int | Integration → `main` | `bdd-journey` |

D3 may exceed 48h; if so split it into its own child plan at approval.

**allowed_paths:** `server/lib/care/{schedule,absence,planner,awayPlan}/**`, `server/lib/care/carePeriod*.js`, `server/routes/careContext/**`, `server/routes/healthEntries/absenceContextRouter.js`, `flutter_app/lib/features/{care_item,health_tracking,pet_care}/**`, tests, `e2e/**`, `docs/**`
**forbidden_paths:** `server/lib/care/occurrence/**` (head logic frozen after A), `db/migrations/**`, `.github/workflows/**`

**Exit criteria:** AC-8 green end-to-end; no `occurrence_id: null` for active items in any absence response (contract test); `indeterminate_pending` only for paused items; away plan and care item agree (existing agreement tests pass).

---

### Child E — `care-item-module-c1a7` (architecture)

**Outcome:** Care Item code lives in one component per side with a public API and an enforced boundary.

| Phase | Title | exit_checklist |
|-------|-------|----------------|
| E1 | Flutter: move care-item files from `health_tracking` (entity, occurrences, detail screen, form, actions, sheets) and `pet_care/domain` (grouping) and `pet_profile/domain/services/care_status_service.dart` into `features/care_item/`; barrel exports; update imports | `flutter-screen-split` |
| E2 | Delete dead code (F28) and their tests; move business rules out of widgets (`pet_event_lifecycle.dart`, `health_entry_status.dart`) into `care_item/domain` | `flutter-screen-split` |
| E3 | Boundary check `scripts/check_care_item_boundary.sh` (other features import only `features/care_item/care_item.dart`), wired into `pre-push.sh` — **governance change, needs human approval** | `governance` |
| E4 | Server: move `lib/occurrenceScheduling.js`, `lib/occurrenceLifecycle.js`, `lib/recurrenceHelper.js` into `lib/care/{occurrence,schedule}`; add `lib/care/item/commands/*` and `queries/*`; routes thin; remove `advanceSeries.js` shim | `single-backend-route` |
| E5 | Docs: "Care Item" component entry in `docs/architecture/index.md` (owned tables, public API, commands, queries, errors, allowed dependencies, side effects), update `docs/architecture/modularity.md` if needed | `governance` |
| E-int | Integration → `main` | `bdd-journey` |

No wire or table renames (installed clients; `pet-care-architecture.mdc` §API). `HealthEntry` may be aliased as `CareItem` in Dart; full rename is a separate decision.

**Exit criteria:** boundary script passes; cycle count between `care_item` and `pet_care`/`pet_profile`/`experience` = 0 in one direction (consumers → `care_item` only); all moved files ≤ 500 lines; no behaviour change (full test suites unchanged apart from import paths).

---

## 8. Client design notes

### 8.1 Status and "today"

The server is authoritative (INV-5). The client shows `open_occurrences[].status` as delivered; for timed slots it may promote Due → Overdue locally when `as_of.time` + elapsed minutes passes the slot time (no date arithmetic across days). Surfaces re-request on app resume and every 15 minutes while visible.

### 8.2 Optimistic updates

Mark as done / Skip: optimistic "Done · Undo" row, then replace with the server's returned item (`{ entry, occurrence, next_occurrences }` — extend complete/skip responses in B1 to include the new head so no refetch is needed).

### 8.3 Removal list (client)

`MarkEntryTaken` usecase, `markEntryTakenProvider`, `HealthRepository.markTaken`, `HomeEventActions.commitCompletion`, `OccurrenceCareActions` mark-taken fallback, `guardianDueEntries`, `isEntryDueOrOverdue`, `hasDueOrOverdueEventsProvider` (replaced), entity due getters, `recurrence_advance.dart`, dead screens (F28), empty-id placeholder handling.

### 8.4 Absence model (context for D and later)

Absence = hand-over, not pause. With real heads: "Keep with Jamie" and "Change date / Skip" act on real occurrences; multi-dose care inside a trip is shown as one rhythm row ("Twice a day · 08:00 and 18:00 · looked after by Jamie") with per-date estimates behind it. Sitter logging and owner notifications on misses (Medfriend pattern) belong to the People/notifications track and are listed in §11.

---

## 9. Data migration summary

| Migration | Child | Kind | Reversible |
|-----------|-------|------|------------|
| `083_care_next_occurrence` | A | Inserts head rows; normalises legacy multi-day pending | Down = documented no-op (rows are valid under old code) |
| `084_schedule_anchor_date` | C | Adds nullable `health_entries.schedule_anchor_date` + backfill for fixed items | Down drops the column |

Both idempotent; both log counts; both covered by `server/test/db/*` integration tests. Router protocol: `.cursor/agent-kernel/protocols/database-and-migrations.md`. Do not use `gen_random_uuid()` in SQL — generate UUIDs in JS (AGENTS.md).

---

## 10. Test strategy

### 10.1 Unit (Jest, mock pool)
`nextHead` table, `seriesDates` table, `ensureHead` branches, each command's head effect, 409 paths, undo D-CSM-027 both branches, PUT reconcile per field.

### 10.2 DB integration (real PostgreSQL, CI job "Backend integration (PostgreSQL)" runs `server/test/db`)
Property test (seeded RNG, ≥ 500 steps) asserting INV-1…3 after every step; concurrency test (two parallel completes); migration 083 idempotency (run twice → same state); repair script dry-run on seeded data.

### 10.3 Flutter
Agenda builder table tests; surface agreement test (the same entry list renders the same order on dashboard, profile, All care — extends `care_temporal_grouping_agreement_test.dart`); row actions; early-completion confirmation; optimistic replace.

### 10.4 BDD + Playwright
AC-1…AC-10 mapped to scenarios; `@smoke` on AC-1 and AC-4. Seed helpers in `e2e/playwright/support/api.ts` must stop relying on T−1 behaviour (serialize edits across agents, per `docs/architecture/index.md`).

### 10.5 Regression baselines to keep green
CSM projection corpus and integration gate (`server/test/careSchedule/integrationGate.test.js`), Away Care Planning tests (`server/test/careContext/*`), care-item evolution widget tests.

---

## 11. Out of scope (tracked as follow-ups)

- Absence-window materialisation of fixed dates (D-ACP-012).
- Sitter logging permissions and owner notifications on missed doses (People + notifications tracks).
- Reminder delivery upgrades (D-CIE-021) and the unread-dedupe observation in §6.5 (open a debt issue).
- Renaming `health_entries` / wire fields to "care item".
- Rolling-horizon materialisation for calendar views.

---

## 12. Open questions for the product owner (answer before A0 freezes)

| # | Question | Recommendation |
|---|----------|----------------|
| Q1 | Fixed item completed after its next date already passed: jump to the next future date and log the skipped dates as one event (D-CSM-021)? | Yes (Todoist behaviour) |
| Q2 | Month-end: clamp to last day, or skip months without that day (RFC default)? | Clamp |
| Q3 | Early completion: allow everywhere with a confirmation beyond half an interval (D-CSM-026)? | Yes |
| Q4 | Resume after pause: move a past head to today / next series date (D-CSM-023)? | Yes |
| Q5 | Dashboard grouping Overdue / Today / This week / Later (collapsed)? | Yes |
| Q6 | "Today": server-supplied `as_of` + slot status (D-CIE-026), or add a timezone library to the app? | Server-supplied |
| Q7 | Add the `btree_gist` exclusion constraint as a DB guard for INV-1? | Only if the host allows the extension; row lock + tests are sufficient otherwise |
| Q8 | Undo when the new head was already modified: refuse with an explanation (D-CSM-027)? | Yes |

---

## 13. PR #1439 disposition

Close [KanopeeKa/AgathaCheck#1439](https://github.com/KanopeeKa/AgathaCheck/pull/1439) with a comment linking this plan. Its grouping change ("all future dates → upcoming") is re-implemented in B3 against real heads; its detail-page fallback row is not needed once A merges (and its Mark done would call `mark-taken` → 400 today). Its CI failures (format, file size 531 > 500) make it unmergeable as is.

---

## 14. Review checklist for Cursor

Please verify and comment on each:

1. **Facts (§2):** re-check every F-row against `main`; flag any that are wrong or already fixed.
2. **Missing write paths:** is any code path that creates, deletes or re-dates `health_occurrences` rows absent from §2.4 / §6.2? (Include organisation/shelter frozen code only if active.)
3. **Invariants (§4):** are INV-1…5 sufficient and testable? Any legitimate state they forbid (e.g. once items with several slots, weight rhythms, `care_planning = 'unplanned'`)?
4. **Decisions (§5):** challenge D-CSM-021 rules with concrete schedules (daily multi-dose, every 3 weeks, yearly on 29 Feb, after-completion backdated completion).
5. **Transactions (§6.3):** lock ordering or deadlock risk (commands that touch several entries: skip-missed, absence planner acceptance, pet deletion)?
6. **Migration (§9):** safety on real data; idempotency; runtime on large tables; down strategy.
7. **API (§B1):** additive and safe for installed native clients; payload size for pets with many items.
8. **Phase boundaries (§7):** overlapping `allowed_paths` between children that run in parallel; each phase = one verifiable outcome (atomic-PR policy); any phase likely > 48h.
9. **Tests (§10):** gaps, especially around undo, edit reconciliation, pause/resume and time zones.
10. **Out of scope (§11):** anything here that is actually required for R1–R5.

Record findings as a table (finding, severity, proposed change) appended to this file under "## Review findings" or on the control issue once created.

---

## 15. Sources (research)

- Todoist — [Complete a task with a recurring date](https://www.todoist.com/help/articles/complete-a-task-with-a-recurring-date-dmI6SVqdP), [Introduction to recurring dates](https://www.todoist.com/help/todoist/features/introduction-to-recurring-dates-YUYVJJAV), [vacation mode](https://www.todoist.com/help/articles/turn-on-or-off-vacation-mode-in-todoist-pAQmRp)
- Things — [Repeating To-Dos, Refined](https://culturedcode.com/things/blog/2026/08/repeating-to-dos-refined/), [Using Repeating To-Dos](https://culturedcode.com/things/support/articles/2803564/)
- Apple — [Track your medications in Health](https://support.apple.com/guide/iphone/track-your-medications-iph811670c81/ios)
- Medisafe — [Med-Friend](https://app.medisafe.com/tips/med-friend-in-need-is-med-friend-indeed/)
- Pet apps — [Pet Care Reminder & Tracker](https://apps.apple.com/us/app/pet-care-reminder-tracker/id6444908248), [PetTimely](https://pettimely.app/)
- Lotsa Helping Hands — [How it works](https://sgk.lotsahelpinghands.com/how-it-works/)
- Habitica — [Rest in the Inn](https://habitica.fandom.com/wiki/Rest_in_the_Inn)
- Google Calendar API — [Recurring events](https://developers.google.com/google-apps/calendar/recurringevents)
- RFC 5545 — [Recurrence Rule](https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html); RFC 7529 — [Non-Gregorian recurrence and SKIP](https://datatracker.ietf.org/doc/html/rfc7529)
- Calendar design — [PracHub guide](https://prachub.com/resources/calendar-system-design-interview-guide-recurrence-time-zones-conflicts-and-notifications)

---

## Runtime state (draft — not started)

```yaml
autonomy: draft
current_phase: null
last_completed_phase: null
halt_reason: "awaiting review (Cursor) and product answers to §12"
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
