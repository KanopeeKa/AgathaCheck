---
title: Bug spec — Not recorded stale open / TZ DATE shift
owner: Product / Agent
audience: both
status: active
last_updated: 2026-10-05
tags: [pet_care, care_planning, bugs]
---

# Bug spec — "This date is no longer open" on Not recorded doses

Status: analysis + remediation plan. UAT care tick suspended 2026-10-05 until §8 ships. ·
Surface: server (`server/lib/care/occurrence/**`, `server/routes/healthEntries/occurrencesRouter.js`,
DB connection setup) + Flutter (`flutter_app/lib/features/care_item/**`) + data (§9)

> **Read §2.8 first.** On the o2switch hosts the primary cause is a server time-zone bug in how
> PostgreSQL `DATE` values are read. §2.1–2.6 are real but secondary: they explain why the app
> can't recover, not why the dose was rejected in the first place.

## 1. Report

Care item "Weekly antibiotic course" (Buddy, Fixed schedule, two times a day, with an Absence).
**Needs attention** lists:

| Row | Status pill | Tick |
|---|---|---|
| Sep 30, 2026 · 08:00 | Not recorded | yes |
| Sep 30, 2026 · 20:00 | Not recorded | yes |
| Oct 6 / Oct 7 · 08:00 and 20:00 | Coming up | yes |

Tapping **Mark all as done**, **Skip all**, or the tick on either Not recorded row shows
`{"error":"This date is no longer open","code":"occurrence_not_open"}` and nothing changes.

## 2. Root cause

### 2.1 Read and commands disagree on what is open

- **Reads** (`GET /api/health-entries/:id/occurrences`, `occurrencesRouter.js:164`, and the care
  item read in `server/lib/care/item/wire.js`) return every `pending` row as it is stored. They do
  **not** run `syncOpenOccurrences`.
- **Every command** (complete, skip, resolve-stack, …) first runs the catch-up
  `syncOpenOccurrences` (`commandRunner.js:99`). For a Fixed schedule it closes as
  *Not recorded* (`status='skipped'`, `close_reason='not_recorded'`) every slot whose next series
  slot is on or before **today − 3** (`closeStackOutsideWindow`, `STACK_WINDOW_DAYS = 3`).
- The command then looks the occurrence up in the post-catch-up open list. It is gone, so it
  throws `notOpen()` (`complete.js:84`, `skip.js:16`, `stack.js:24`) → HTTP 409.

With today = 2026-10-04 the window start is 2026-10-01, so both Sep 30 slots are closed by the
catch-up the moment any button is pressed.

### 2.2 The failure rolls back the catch-up too, so the screen never heals by itself

The command runs inside `withCareItemLock`, and a thrown `CareCommandError` rolls back the **whole**
transaction (`careCommandError.js:3`), including the catch-up close. The rows stay `pending`, the
app refreshes, gets the same stale list, and the user is stuck in a loop. Only the 15-minute
**care tick** (`server/scripts/care/care_tick.js`) commits that close outside a command.

### 2.3 Bulk actions are all-or-nothing

`resolveStackCommand` rejects the whole request if **any** id is not open (`stack.js:23-25`).
The app sends the *started* rows (`startedOccurrences` — here exactly the two Sep 30 rows), so one
stale row blocks the whole stack, including rows that are genuinely open.

### 2.4 Closed Not recorded doses have no action in the app

The server has `recordAsGivenCommand` (`stack.js:51`, route in `occurrencesRouter.js:277`) for a
dose closed as Not recorded, but the Flutter app never calls it. There is no command to turn a
closed Not recorded dose into an intentional skip.

### 2.5 Two client paths, two error behaviours

- New path (`care_item/application/care_completion_service.dart:287`) maps 409
  `occurrence_not_open` to the "Already updated" snackbar.
- Legacy path (`health_tracking/data/datasources/health_occurrence_remote_datasource.dart`, used
  by the occurrence screen, dates section, stack sheet) passes the raw response body through, which
  is the JSON the user saw. Which surface produced the message in the report is not confirmed.

### 2.6 Same word, two meanings

"Not recorded" is used for:

- **Open, Not recorded:** an open (`pending`) slot whose next slot has already started
  (`occurrenceStatus.js:114`). It can still be marked done or skipped.
- **Closed, Not recorded:** a slot auto-closed after the 3-day window (`status='skipped'`,
  `close_reason='not_recorded'`). It can only be *recorded as given*.

The UI shows the same pill for both, so the user can't tell an actionable dose from a closed one.

### 2.7 Secondary suspicion (to confirm, out of scope here)

The Sep 30 20:00 row shows *Not recorded* although the next dose shown is Oct 6. The status rule
uses `nextSeriesSlotAfter`, which knows nothing about the Absence. The next series slot is
probably computed as Oct 1 08:00, even if the absence moved or removed the Oct 1–5 doses.
The same rule decides auto-closing, so absence-covered stretches may close doses as Not recorded
earlier than a person would expect. This should get its own ticket.

> Re-check §2.7 after §8 ships: the dates in the report are shifted by §2.8, so the "Sep 30" and
> "Oct 6" rows are really Oct 1 and Oct 7.

### 2.8 Primary cause on the hosts: `DATE` columns are read one day early (confirmed on UAT)

**Mechanism.**
- node-pg turns a PostgreSQL `DATE` (OID 1082) into a JS `Date` at **midnight in the Node
  process's local time zone**. The repo registers no type parser.
- `dateToIsoDate` (`server/lib/calendarDate.js:30-43`) then reads it with `getUTC*`, assuming
  midnight UTC.
- On a host in a zone **east of UTC** this gives the previous day. `Europe/Paris` in October is
  UTC+2, so `2026-09-30` comes back as `2026-09-29`.
- Verified with pg 8: `TZ=UTC` → `2026-09-30`; `TZ=Europe/Paris` → `2026-09-29`.
- CI and local development run in UTC, so no test sees it.
- Zones west of UTC are not affected (local midnight is still the same UTC day).
- `TIMESTAMPTZ` columns are unaffected (they are absolute instants). The schema has no
  `timestamp without time zone` columns; it has 32 `DATE` columns.

**Host evidence (UAT, 2026-10-04/05).**
- `date` on the host → `CEST`; Node `Intl…timeZone` → `Europe/Paris`.
- `care_tick_uat.log` shows `created:3, closed:3` on **every** run from 17:15Z, then
  `created:8, closed:8` from 22:00Z (pet-home midnight). A converged tick should report `0/0`
  between midnights.
- `health_occurrences` has 24 rows for each of three slots (23 closed as `not_recorded`, 1
  pending):
  - item `…0020`: 2026-10-01 08:00 and 2026-10-01 20:00
  - item `…0112`: 2026-09-30, untimed

  Three more items (`…0101`, `…0102`, `…0108`) started duplicating at 22:00Z.
- `care_schedule_events` has 23 `not_recorded_closed` events in 24 h for each looping item.

**How it produces the loop** (each run of `syncOpenOccurrences`, tick or command):
1. **Close step.** `closeStackOutsideWindow` reads the open Oct 1 row as Sep 30, which is before
   the window start (Oct 1 when today is Oct 4). It closes the row as Not recorded, although its
   true date is **inside** the window.
2. **Create step.** `existingSeriesSlotKeys` reads every row's date one day early, so no row
   matches the Oct 1 key. `createMissingFixedSlots` inserts a new pending Oct 1 row. The only
   unique index, `idx_health_occurrences_open_slot`, covers `status = 'pending'` rows only, so
   the insert succeeds.
3. The next run closes that new row, and so on: one new closed duplicate per slot per run. The
   loop grows each pet-home midnight as more slots fall within reach of the shifted dates.

**How it produces the reported error.**
- The app process runs in the same zone, so the screen also shows every date one day early.
  "Sep 30 · 08:00/20:00" are the Oct 1 rows; "Oct 6/Oct 7" are Oct 7/Oct 8.
- A tap sends the id of the current pending copy. The command's catch-up closes that copy and
  inserts a new one with a **different id**. The command no longer finds the id it was sent, so
  it answers 409 `occurrence_not_open`. This happens on every tap, for every button.

**Wider effects of the same bug** (assessment for §9):
- **Series computed on the wrong day.** `schedule_anchor_date` is read one day early, so weekly
  and every-N-days series are computed one day early, creating off-series slots. This plausibly
  explains doses on two consecutive days (Oct 6 and Oct 7) in a *weekly* course. Daily series are
  unaffected.
- **Server writes store shifted values.**
  - `syncOpenOccurrences` sets `schedule_anchor_date` from a shifted open date when it is missing.
  - `writeNextDueDate` stores the shifted earliest open date in `next_due_date`.
  - Other code that reads a `DATE` and writes it back (pause/resume, completion dates) can store
    it one day early.
- **App round-trips store shifted values.** Every API that serialises a `DATE` through
  `dateToIsoDate` sends the previous day. A form saved unchanged in the app writes that earlier
  day back. Each edit moves the date one more day. This affects all features, not only care.

## 3. Is the care tick running?

**Answered (2026-10-05):** yes, the cron runs every 15 minutes, but it loops because of §2.8. The
first version of this section guessed it was not running; that was wrong. The checks below remain
the runbook. The tick is suspended on UAT until §8 ships; re-enable it with §9 step 6.

The tick runs from the host crontab (o2switch cPanel), see `docs/ops/care-tick.md`.

**Running SQL on the host without psql or phpPgAdmin access.** phpPgAdmin logs in as a user that
does not own the app's tables, so it gets *permission denied*. No grant is needed for the app.
Run read-only queries as the app user from the cPanel Terminal instead:
`cd ~/uat.agathatrack.com/backend && echo "<SQL>" | ~/nodevenv/uat.agathatrack.com/backend/22/bin/node ~/agatha_sql.cjs`.
The helper `~/agatha_sql.cjs` loads the backend `.env`, opens a `BEGIN READ ONLY` transaction and
prints the rows. It is not in the repo; §9 asks for a committed equivalent.

### How to check (UAT; for production use `agathatrack.com` and `care_tick_prod.log`)

1. **Cron entry exists:** cPanel → Advanced → Cron Jobs, or `crontab -l` over SSH. Expect
   `*/15 * * * *` running `scripts/care/care_tick.js` from `~/uat.agathatrack.com/backend`.
   Check that the Node path's `<version>` (e.g. `/22/`) still exists in `~/nodevenv/...`. A Node
   version change in cPanel silently breaks the cron.
2. **Log is moving:**
   ```bash
   tail -n 5 ~/logs/care_tick_uat.log
   ```
   Expect one JSON line every 15 minutes:
   `{"at":"…","skipped":false,"processed":N,"created":…,"closed":…}`.
   - No recent lines → the cron isn't firing (wrong path, wrong Node binary, removed entry).
   - `care tick failed` → it can't reach the DB (check `.env` / `DATABASE_URL`).
   - `"skipped":true` on every line → a stuck advisory lock (a hung previous run is holding
     lock key `7311015`); check `SELECT * FROM pg_locks WHERE locktype='advisory'`.
   - `"processed":0` → no item matches the candidate query (active/paused, planned, recurring,
     Fixed schedule).
3. **Run it once by hand:**
   ```bash
   cd ~/uat.agathatrack.com/backend && ~/nodevenv/uat.agathatrack.com/backend/22/bin/node scripts/care/care_tick.js
   ```
   - **Before §8 ships, on a Paris host:** expect non-zero `created` and `closed` on every run,
     with the same rows reappearing in the app (§2.8). This is the loop, not a broken cron.
   - **After §8 and §9:** the first run after pet-home midnight may close and create slots. Any
     later run that day should print `created: 0, closed: 0`. If the cron log has no new lines
     but this manual run works, only the cron entry is broken.
4. **Database evidence** (psql / phpPgAdmin):
   ```sql
   -- Last automatic Not recorded closes, all items
   SELECT occurred_at, health_entry_id, payload
   FROM care_schedule_events
   WHERE event_type = 'not_recorded_closed'
   ORDER BY occurred_at DESC LIMIT 10;

   -- Stale pending slots the tick should already have closed (window = today − 3)
   SELECT health_entry_id, scheduled_date, scheduled_time
   FROM health_occurrences
   WHERE status = 'pending' AND scheduled_date < CURRENT_DATE - 3
   ORDER BY scheduled_date;
   ```
   A healthy tick gives recent `not_recorded_closed` events. On Fixed-schedule items, the second
   query should then return little or nothing beyond rows whose next slot is still inside the
   window.
5. **Invariants:** `scripts/care/repair_occurrences.js --dry-run` should report
   `0 with violations`.

**Even with a healthy tick the bug remains.** For up to 15 minutes after pet-home midnight, and
whenever the tick is late or fails, the read shows rows that commands reject. The fix must not
depend on the tick.

## 4. Functional requirements

**FR-1 — One truth for reads and commands.** Every surface that lists occurrences (Care Item view,
occurrence screen, agenda/home, stack sheet) must show the state a command would see *now*: the
same catch-up rules, applied at read time or immediately before it. A stale read is never the only
thing the user can act on.

**FR-2 — Open doses are always actionable.** A dose that is open (Due, Overdue, Open Not recorded,
or Coming up where early completion is allowed today) can be marked done and skipped without a
409.

**FR-3 — Closed Not recorded doses can be resolved after the fact.** The user can:
- **Record as given** (with a date, defaulting to the scheduled date and never in the future).
  This already exists on the server.
- **Confirm as skipped**, turning an automatic Not recorded into an intentional skip
  (*product decision, see §6 Q1*).
- **Reopen** it (*product decision, see §6 Q2*). Reopening a dose older than the 3-day window
  conflicts with the auto-close rule; the next catch-up would close it again.

**FR-4 — Visible, honest states.** Every listed dose shows exactly one clear state:
Coming up · Due · Overdue · Not recorded (open) · Not recorded (closed) · Done · Skipped.
Open and closed Not recorded must look different (label and/or icon, not colour alone).

**FR-5 — No dead buttons.** A dose that is Done, Skipped, or closed Not recorded shows **no** tick
or skip control. A closed Not recorded dose shows only the actions from FR-3. The Care Item view's
Needs attention section lists only open doses; closed ones either appear in a clearly labelled
"Closed / not recorded" group or not at all (*see §6 Q3*).

**FR-6 — Bulk actions act on what is still open.** **Mark all as done** and **Skip all** apply to
every dose that is open *at the time the server runs the command* and in the bulk scope (§6 Q4).
Doses already closed are ignored, not errors. The command fails only when nothing in scope is
open, and it is still atomic: all of the open ones change, or none do.

**FR-7 — Truthful feedback.** After a bulk action the snackbar says what actually happened, e.g.
"2 doses marked done" or "2 marked done · 1 was already closed". One Undo reverts exactly the doses
this command changed, not the auto-closes.

**FR-8 — Self-healing after a conflict.** When a command is rejected because the state moved, the
app refreshes and the next screen shows the true state. The catch-up a command runs is not lost
when the action itself is refused. Either commit the catch-up separately, or make reads apply it
(FR-1).

**FR-9 — Human errors only.** Raw server bodies, JSON or codes never reach the user. A 409
`occurrence_not_open` always shows "Already updated" (or the FR-7 message) on every surface, and
all care Done/Skip actions go through the one care client path.

**FR-10 — Tick is an optimisation, not a dependency.** Correctness (FR-1 to FR-9) holds with the
tick stopped. The tick still closes doses on schedule for reminders and counts, and its health is
observable (log line per run plus a monitoring check, §5 group H).

## 5. Acceptance criteria

Default fixture unless stated: Fixed schedule, daily, 08:00 and 20:00, pet-home zone
Europe/Paris, today = 2026-10-04 12:00 (window start 2026-10-01). **Tick not run** unless stated.

**All dates in §5, §8 and §9 are true dates as stored in the database, on a correctly configured
server (§8 shipped).** They are not the shifted labels the app showed on the hosts before §8. In
the report (§1), the label "Sep 30" was the stored date Oct 1, and "Oct 6/Oct 7" were Oct 7/Oct 8.
The §5 fixtures use stored Sep 30 dates on purpose: those slots really are outside the window.

**Precondition:** every integration test that runs the occurrence sync (groups A, B, E, G, H) runs
under both `TZ=UTC` and `TZ=Europe/Paris` once §8 ships (AC-TZ2).

### A. Read / command consistency (FR-1, FR-8, FR-10)

- **AC-A1** Given pending slots Sep 30 08:00 and 20:00 whose next slots are on or before Oct 1,
  when the Care Item view loads, they are **not** shown as open doses with a tick.
- **AC-A2** Given the same data, when the occurrence list endpoint is called with
  `status=open`, those slots are not in the response.
- **AC-A3** Given any open dose shown with a tick, when the user taps it immediately, the server
  does **not** answer 409 `occurrence_not_open` (no stale gap between read and command).
- **AC-A4** Given the tick has not run for 24 hours, every AC in groups A–F still passes.
- **AC-A5** Given a command is refused with 409, when the app refreshes, the refused dose is shown
  in its true state and no longer offers the refused action.
- **AC-A6** Reads stay safe under concurrency: two simultaneous reads and a command on the same
  item give no duplicate slots, no deadlock, and no double ledger event (reuse
  `withCareItemLock` / `SKIP LOCKED` semantics).
- **AC-A7** Reads that apply the catch-up write at most one `not_recorded_closed` ledger event per
  batch of closed slots, the same as the tick.
- **AC-A8** Read latency stays within the existing budget for the Care Item view and the agenda
  (measured on the UAT data set; no N+1 across items on list endpoints).

### B. Open doses (FR-2)

- **AC-B1** Given an Overdue dose, tick → marked Done, snackbar with Undo, row leaves Needs
  attention.
- **AC-B2** Given an **open** Not recorded dose (next slot started, still inside the window), tick
  → marked Done with completion date = its scheduled date (or the date chosen in the date sheet).
- **AC-B3** Given an open Not recorded dose, Skip → marked Skipped (`close_reason='user'`).
- **AC-B4** Given a Due dose today, tick → Done today, no 409.
- **AC-B5** Undo after B1–B4 restores the exact previous state.

### C. Closed Not recorded doses (FR-3, FR-4, FR-5)

- **AC-C1** Given a dose closed as Not recorded, it shows the label "Not recorded" with a
  *closed* marker distinct from the open Not recorded pill. Text/icon carry the difference;
  colour is not the only cue (accessibility).
- **AC-C2** It shows **no** Done tick and **no** Skip control.
- **AC-C3** It offers **Record as given**. Choosing it opens a date picker defaulting to the
  scheduled date, with future dates disabled. Confirming sets it Done
  (`recordAsGivenCommand`), and Undo restores closed Not recorded.
- **AC-C4** Record as given with a future date is refused with a validation message, not a raw
  error.
- **AC-C5** *(if Q1 = yes)* It offers **Mark as skipped**, which sets `close_reason='user'`. The
  dose then counts as an intentional skip in history/adherence, and Undo restores closed Not
  recorded.
- **AC-C6** *(if Q2 = yes)* **Reopen** returns it to open, and the next read or catch-up does
  **not** close it again until the user acts (requires a "reopened" exemption).
- **AC-C7** Screen readers announce the state ("Not recorded, closed") and the available actions.

### D. Done / skipped doses (FR-4, FR-5)

- **AC-D1** A dose already Done is never listed under Needs attention. Where it is listed
  (history, occurrence screen), it shows "Done" + date and no tick.
- **AC-D2** A dose already Skipped shows "Skipped" and no tick or skip button.
- **AC-D3** Opening the occurrence screen of a closed dose (deep link, notification, stale tab)
  shows its state and only the actions valid for it. No Done button that fails.

### E. Bulk actions (FR-6, FR-7)

- **AC-E1** Given 2 open started doses and 4 Coming up, **Mark all as done** marks the 2 started
  doses Done (each with its own scheduled date as completion date) and leaves Coming up untouched
  *(scope per Q4)*.
- **AC-E2** Given 3 doses in scope where 1 was closed after the screen loaded, **Mark all as done**
  succeeds for the 2 still open. The snackbar says "2 marked done · 1 was already closed", and no
  error is shown.
- **AC-E3** Same as E2 for **Skip all**.
- **AC-E4** Given every dose in scope is already closed, the command returns a "nothing to update"
  result. The app shows "Already updated" and refreshes; no raw error appears.
- **AC-E5** Undo after a partial bulk action reverts only the doses that action changed. Doses
  auto-closed as Not recorded stay closed.
- **AC-E6** The bulk buttons are shown only when ≥ 2 doses in scope are open (the stack rule). They
  are hidden or disabled when none are, and never offered on a section containing only closed
  doses.
- **AC-E7** Bulk is atomic for the open set: a server failure midway leaves no dose changed.
- **AC-E8** Double-tap or a second device acting concurrently gives no duplicate Done and no 500.
  The second request reports what was already closed.
- **AC-E9** The response lists the ids actually changed and the ids ignored, so the app and
  analytics (`care_stack_resolved` count) use the real number.

### F. Errors and client paths (FR-9)

- **AC-F1** On every care surface (Care Item view, occurrence screen, dates section, stack sheet,
  agenda, home), a 409 `occurrence_not_open` shows "Already updated" and triggers a refresh.
- **AC-F2** No surface shows a server response body, JSON, or error code to the user.
- **AC-F3** Done/Skip/bulk on care items go through `CareCompletionService` (one path). The legacy
  `health_occurrence_remote_datasource` Done/Skip calls are removed or wrapped with the same
  mapping.

### G. Edge cases

- **AC-G1** Time-zone midnight: at 00:05 pet-home time on the day a slot crosses the window, the
  read and a command agree (no 409), with the tick not yet run.
- **AC-G2** Untimed (date-only) Fixed schedule: same behaviour as timed.
- **AC-G3** Weekly / every-N-days series: the window and "next slot" rules give the same result
  on read and on command.
- **AC-G4** Paused item, or an item with an Absence: reads do not auto-close doses the absence
  postponed. Track §2.7 separately, but no new 409s may appear here.
  *Known limitation:* while §2.7 is open, Not recorded status and auto-close still ignore the
  Absence (`nextSeriesSlotAfter`). §8 alone does not satisfy AC-G4; it is fully met only when the
  §2.7 ticket lands.
- **AC-G5** After It's Done (non-Fixed) items are unaffected: no auto-close, existing behaviour
  unchanged.
- **AC-G6** Finished item (end date passed): closed doses show as closed, and no actions except
  Record as given where allowed.
- **AC-G7** A user with view-only access sees states but no action buttons (authorization
  unchanged).

### H. Tick operations (FR-10)

- **AC-H1** Each tick run logs one JSON line with `processed / created / closed / skipped`. This
  already exists; it stays as is.
- **AC-H2** An ops check documented in `docs/ops/care-tick.md` alerts or is easy to run when no
  tick line has appeared for > 1 hour.
- **AC-H3** Running the tick after the fix changes nothing the read already applied (idempotent,
  no duplicate ledger events).

### I. Tests to add

- **AC-I1** Server integration test: stale pending slots outside the window + no tick → read
  excludes them; complete/skip/resolve-stack on remaining open doses succeed.
- **AC-I2** Server test: resolve-stack with a mix of open and closed ids → partial success with
  changed/ignored lists; all closed → "nothing to update".
- **AC-I3** Server test: a refused command does not leave the item permanently stale (FR-8).
- **AC-I4** Flutter widget tests: closed Not recorded row has no tick and offers Record as given;
  partial bulk snackbar text; 409 shows "Already updated" on each surface.
- **AC-I5** BDD scenario (E2E) for the reported case: two Sep 30 doses, test clock 2026-10-04,
  Mark all as done → no error, true state shown.

## 6. Open product decisions

| # | Question | Recommendation |
|---|---|---|
| Q1 | Can a closed Not recorded dose be turned into an intentional **Skip**? | Yes. It's cheap (one new command), and history then shows the dose as a deliberate skip rather than "not recorded". |
| Q2 | Should **Reopen** exist for a closed Not recorded dose? | No. Record as given + Mark as skipped cover the outcomes, and reopen conflicts with the 3-day rule. |
| Q3 | Should closed Not recorded doses appear in Needs attention? | Only inside the 3-day window, in a separate "Not recorded" group with Record as given. Older ones go to history. |
| Q4 | Bulk scope: "all open" or "all open **and started**"? | Started only. Marking future (Coming up) doses done is almost always wrong. Make the button label explicit if needed ("Mark past doses as done"). |
| Q5 | Fix FR-1 by running the catch-up on read (writes under lock) or by filtering on read (pure, the tick commits later)? | Run the catch-up under the item lock on single-item reads; filter on list reads. This is an engineering decision to confirm in the PR. |

## 7. Suggested delivery (atomic PRs)

0. **Server — calendar dates independent of the host time zone (§8).** Ships first, then the data
   cleanup (§9) runs on each host before the tick is re-enabled.
1. **Server — consistency:** FR-1, FR-8, FR-10 (groups A, G, H; AC-I1, I3).
2. **Server — bulk partial success:** FR-6, FR-7 server side (group E; AC-I2).
3. **Flutter — states, actions, errors:** FR-3 to FR-5, FR-7 client side, FR-9 (groups B–F;
   AC-I4, I5).

PR 1 + 2 are drafted as KanopeeKa/AgathaCheck#1558. Before merge, it needs:
- PR 0 merged underneath it. Its single-item reads run the catch-up, so without PR 0 every page
  view would feed the §2.8 loop.
- Fix the `clock` temporal-dead-zone error in `careItemsWire`
  (`server/lib/care/item/wire.js`). Today it makes `GET /api/health-entries` answer 500.
  - **Repro:** the new `const clock = byZone.get(zone);` inside the `entries.map` callback is
    declared *after* the line `byZone.set(zone, careAsOfForZone(zone, clock, now))`, which reads
    `clock`. That inner `clock` shadows the outer one for the whole callback, so the read throws
    `ReferenceError: Cannot access 'clock' before initialization` for any non-empty list.
  - **CI evidence** (head `bc5298c`): `sharedPetAccess.test.js › allows shared user to list
    health entries` expects 200 and gets 500.
  - **Fix:** rename the inner variable (e.g. `asOf`).
- Return 409 (not 400) when nothing in a bulk request is still open (AC-E4).
- Make `closeStackOutsideWindow` use `wouldAutoCloseAsNotRecorded`, so the rule exists in one
  place.
- Pass the synced item (not the pre-sync row) to `careItemWire` on single-item reads.
- AC-A6/A7 tests, and green CI.

## 8. Code fix spec — calendar dates independent of the host time zone

### 8.1 Requirements

**TZ-1 — A `DATE` is a string end to end.** Every `DATE` value read from PostgreSQL reaches
application code as the `YYYY-MM-DD` string stored in the database, whatever the Node process
time zone (`TZ`, system zone, or cPanel/Passenger setting). This holds for the API server, the
care tick, and every script under `server/scripts/**` and `server/db/**` that opens a pool.

**TZ-2 — One place configures it.**
- The `DATE` type parser (`pg.types.setTypeParser(1082, (v) => v)`) is registered in one shared
  module, e.g. `server/lib/db/pgTypes.js`.
- Every entry point that creates a pool imports it before its first query:
  - `server/bin/server.js`
  - `server/scripts/care/care_tick.js` and `server/scripts/care/repair_occurrences.js`
  - `server/scripts/migrate.js`, `seed.js`, `seed-migration-ledger.js`,
    `run-cleanup-jobs.js`, `audit-retention.js`, `reconcilePeopleVets.js`
  - `server/db/seeds/truncate-data.js`
- Better still: one shared `createPool()` used by all of them, replacing the eleven copies.

**TZ-3 — No silent regression.** A check script, in the style of
`scripts/check_occurrence_writes.js` and run by pre-push and CI, fails when a file creates a
`pg.Pool`/`pg.Client` without the shared module.

**TZ-4 — Code that relied on `Date` objects keeps working.**
- Audit every read of the 32 `DATE` columns for use as a `Date`: `.getTime()`, `getFullYear()`,
  date arithmetic, `<`/`>` comparisons between `Date` objects, `instanceof Date` branches, and
  `res.json(row)` that sends a raw `DATE`.
- After TZ-1 these receive strings. Update each one, or confirm it already accepts strings.
  `dateToIsoDate` already does.
- **Deliverable:** an inventory table in the PR description, one row per `DATE` column:
  `table.column` · server read sites · server write sites · API fields that expose it · Flutter
  model/parser that consumes it · change made (or "no change: already string-safe"). Columns no
  code reads as a `Date` still get a row, so the audit is visibly complete.
- **Deliverable:** rewrite the header comment and `dateToIsoDate` in `server/lib/calendarDate.js`.
  Today they say node-pg reads `DATE` as *midnight UTC*, which is false: it is *local* midnight.
  After TZ-1 the `Date` branch only serves non-pg inputs. The comment must say so, so nobody
  "fixes" the wrong layer again.

**TZ-5 — Writes never depend on the zone.** `DATE` parameters are always passed as `YYYY-MM-DD`
strings, never JS `Date` objects (node-pg serialises a `Date` in local time with an offset).
The audit in TZ-4 covers the write paths too.

**TZ-6 — The care tick converges.**
- With a fixed clock, a second `runCareTick` creates and closes nothing (`created: 0,
  closed: 0`).
- Add an invariant to `repair_occurrences` (**INV-6**): at most one row per
  `(health_entry_id, COALESCE(series_date, scheduled_date), scheduled_time)` for
  `origin = 'schedule'`.
- Optional, after §9 has removed the duplicates: enforce INV-6 with a unique index, if the
  data model allows it. Postpone keeps `series_date`, so check moved rows first.

**TZ-7 — Loud on a broken host.** At start-up the server and the tick run `SELECT
'2026-09-30'::date` and verify the value is the string `2026-09-30`; otherwise they log an error
and exit non-zero. The tick log line also carries `tz`: the process zone as reported by
`Intl.DateTimeFormat().resolvedOptions().timeZone` (e.g. `"tz":"Europe/Paris"`), not
`process.env.TZ`, which is usually unset on the hosts.

**TZ-8 — No API contract change beyond the fix.** Fields that were sent as `YYYY-MM-DD` stay
`YYYY-MM-DD`, now with the correct day. A field that was sent as a full ISO timestamp because a
raw `DATE` went through `res.json` becomes `YYYY-MM-DD`. List such fields in the PR (the TZ-4
inventory covers it), and check the Flutter parser for each one.

Contract changes from the other PRs are documented in the API reference in the same PR as the
server change. In particular, PR 2 (§7) answers **409** `occurrence_not_open` when nothing in a
bulk request is still open (AC-E4), where #1558 currently answers 400 `nothing_to_update`.

**TZ-9 — Process time zone is not the fix.** Setting `TZ=UTC` on the hosts may be added as
defence in depth, but correctness must not depend on it: cron, cPanel Node apps and future hosts
each set their own environment.

### 8.2 Acceptance criteria

- **AC-TZ1** With `TZ=Europe/Paris` (and `TZ=Asia/Tokyo`, `TZ=America/New_York`), reading a row
  whose `DATE` is `2026-09-30` yields `'2026-09-30'` in application code and on the wire.
- **AC-TZ2** The backend Jest suite and the care DB integration suites pass under
  `TZ=Europe/Paris` in CI, as an extra job or matrix entry alongside UTC.
- **AC-TZ3** Under `TZ=Europe/Paris`, with the §2.8 fixture (twice-daily item, today 2026-10-04,
  Oct 1 rows pending): two consecutive ticks give `created: 0, closed: 0` on the second run. The
  Oct 1 rows stay open (they are inside the window), and no duplicate slot exists. The second run
  also writes **no** `care_schedule_events` row: count ledger events, not only occurrence rows.
- **AC-TZ4** Under `TZ=Europe/Paris`, a weekly Fixed-schedule item anchored on a Wednesday only
  ever has slots on Wednesdays.
- **AC-TZ5** Under `TZ=Europe/Paris`, completing an open dose from the Care Item view succeeds
  (no 409), and the completed row keeps its true `scheduled_date`.
- **AC-TZ6** Under `TZ=Europe/Paris`, reading and saving an entity unchanged (care item, pet with
  birth date, weight entry) leaves every `DATE` column unchanged in the database.
- **AC-TZ7** `next_due_date` and `schedule_anchor_date` written by the sync equal the true dates
  under `TZ=Europe/Paris`.
- **AC-TZ8** The TZ-3 check fails on a file that opens a pool without the shared module, and
  passes on the repo after the change.
- **AC-TZ9** Starting the server or the tick with a deliberately broken parser (test only) logs
  the TZ-7 error and exits non-zero.
- **AC-TZ11** Regression guard: a test creates a pool **without** the shared module under
  `TZ=Europe/Paris` and asserts that a `DATE` reads back shifted. It then asserts the shared
  `createPool()` reads it correctly. If node-pg ever changes its default, the first assertion
  fails and tells us.
- **AC-TZ12** Flutter: every model that reads a `DATE`-backed field parses a plain `YYYY-MM-DD`
  string and does not depend on a timestamp form (`…T…Z`). Covered by a model test per field in
  the TZ-4 inventory that previously received a timestamp.
- **AC-TZ10** `repair_occurrences --dry-run` reports INV-6 on a DB containing a duplicate slot,
  and reports 0 after §9.

## 9. Data cleanup spec

### 9.1 Context and scope

- Both hosts run in `Europe/Paris` (UAT confirmed; check production in step 1 below).
- The product is pre-launch. Production was emptied on 2026-10-01 (`docs/e2e/uat-demo-data.md`,
  "Resetting care data"). So the affected data is UAT demo data, plus whatever was created on
  production since 2026-10-01.

| # | Damage (§2.8) | Detectable? |
|---|---|---|
| D1 | Duplicate schedule rows: one slot with many rows closed `not_recorded` | Yes, exactly (INV-6) |
| D2 | Doses wrongly closed as Not recorded while inside the window | Yes: recompute with true dates |
| D3 | Off-series slots from a shifted `schedule_anchor_date` (weekly / every-N-days) | Yes: check each row against the series |
| D4 | Item `DATE` fields written shifted by the server (`schedule_anchor_date`, `next_due_date`, `series_resumed_on`, `paused_*`, `completed_on`) | Partly: `next_due_date` via INV-5; others need review |
| D5 | `DATE` fields round-tripped through app forms (any feature) | No; only candidates via `updated_at` |
| D6 | `not_recorded_closed` ledger events created by the loop | Yes (they reference D1 rows) |

### 9.2 Requirements

**DC-1 — UAT is reset, not repaired.** UAT holds demo data only. After §8 is deployed to UAT,
run **Actions → UAT reset demo data** (`scripts/db/uat-refresh-demo.sh`), as already documented.
No cleanup script is needed for UAT.

**DC-2 — Measure production before deciding.** First confirm production's zone (the `date` /
`Intl…timeZone` check from §2.8). Then, with the read-only helper (DC-7), run on production:
- the duplicate-slot query (§3);
- the `not_recorded_closed` count for the last 24 h;
- a count of rows per table created or updated since 2026-10-01 in tables with `DATE` columns.

If production has no D1/D6 rows and no data that real people entered, reset it like UAT (DC-1).
Otherwise apply DC-3 to DC-6.

**DC-3 — Repair script, dry run by default.**
`server/scripts/care/repair_tz_shift.js`:
- `--dry-run` is the default. `--apply` writes.
- `--apply` is refused on `APP_ENV=uat` (DC-1) and when the dry-run reports no repair work (reset / empty DB after DC-1).
- One transaction per care item, under `withCareItemLock`.
- Idempotent: a second `--apply` changes nothing.
- Prints a per-item report: rows deleted, reopened and flagged.
- Requires §8 to be deployed. It refuses to run if the TZ-7 check fails.

**DC-4 — Rules, applied per care item in this order:**
1. **D1 duplicates.** For each slot with more than one row, keep exactly one, choosing in this
   order:
   - a row a person acted on (`completed`, or `skipped` with `close_reason = 'user'`, or
     `marked_by_user_id` set);
   - else the `pending` row;
   - else the oldest row.

   Delete the others **only if** all of these hold: `close_reason = 'not_recorded'`,
   `marked_by_user_id IS NULL`, and no `weight_entries` / `health_event_photos` row references
   them (those foreign keys are `ON DELETE SET NULL`, so a deletion would silently orphan the
   link). A duplicate that fails these checks is flagged, not deleted.
2. **D3 off-series slots.** Using the true anchor, a `schedule` row whose series date is not on
   the series and that no person acted on is deleted. A row a person acted on is flagged for
   manual review.
3. **D2 wrongly closed.** For each remaining row with `close_reason = 'not_recorded'` and no
   person action, recompute with true dates whether `closeStackOutsideWindow` would close it
   today. If not, and the slot has no pending row, reopen it: `status = 'pending'`,
   `close_reason = NULL`, `marked_at = NULL`.
4. **D4 item fields.**
   - Recompute `next_due_date` (as INV-5 repair does).
   - Flag items whose `schedule_anchor_date` is not on the series implied by `start_date` and the
     earliest person-acted row; don't change them automatically.
5. **D6 ledger.**
   - Remove deleted occurrence ids from `not_recorded_closed` payloads. Delete events whose
     id list becomes empty.
   - Never touch events with an `actor_user_id` (a person's command; Undo depends on them).
6. Run the sync once (`syncOpenOccurrences`, true dates) so INV-1…INV-6 hold.

**DC-5 — Every change is auditable.** `--apply` writes one `care_schedule_events` row per
repaired item (`event_type = 'data_repair'`, `reason_code = 'tz_shift_2026_10'`) with a payload
listing deleted, reopened and flagged ids and the before values of changed item fields. Undo
ignores this event type.

**DC-6 — D5 is reviewed, not auto-fixed.** The script (or a separate `--report-d5` mode) lists
rows updated since the first deploy on the host in tables with `DATE` columns, with their current
`DATE` values. The owner decides per record. There is no safe automatic rule, because an edit may
also have been a genuine change.

**DC-7 — A committed read-only SQL helper.**
- `server/scripts/ops/sql_readonly.js` reads SQL from stdin, uses the backend `.env`, runs inside
  `BEGIN READ ONLY`, and prints the rows. It replaces the ad-hoc `~/agatha_sql.cjs`.
- Document it in `docs/ops/care-tick.md`.
- Note in the same runbook that phpPgAdmin's login does not own the app tables, so it can't
  query them (*permission denied*). Grants are optional and host-specific: never put them in
  migrations.

**DC-8 — Runbook order, per host:**
1. Keep the care tick cron suspended (done on UAT 2026-10-05; suspend on production if affected).
2. Deploy §8 and confirm the TZ-7 start-up check passes in the app log.
   **Gate:** do not deploy PR 1 (#1558, read-sync) to a host before this step passes there.
3. Run DC-2 and decide: reset (DC-1) or repair (DC-3). **Gate (production):** the zone check in
   DC-2 is done and recorded before any reset or repair.
4. If repairing: take a backup (`pg_dump`, or the phpPgAdmin export per `docs/ops/care-tick.md`),
   run `--dry-run`, review the report, run `--apply`, then `--dry-run` again (expect no changes).
5. `repair_occurrences.js --dry-run` → `0 with violations` (including INV-6).
6. Re-enable the cron. Watch `care_tick_*.log` for 24 h: `created: 0, closed: 0` on every run
   except right after pet-home midnight, and no INV-6 violations the next day.

### 9.3 Acceptance criteria

- **AC-DC1** *(CI fixture, not an ops step: on UAT itself the procedure is reset, DC-1.)* On a
  snapshot fixture reproducing the UAT data before reset, `--dry-run` reports for items `…0020` and
  `…0112`: 23 deletions each per looping slot, the pending row kept, no reopen needed.
- **AC-DC2** After `--apply`, the duplicate-slot query returns no rows. A second `--apply`
  reports no changes.
- **AC-DC3** Rows a person acted on are never deleted or reopened. They appear only as
  "flagged".
- **AC-DC4** No `weight_entries` or `health_event_photos` row loses its `health_occurrence_id`.
- **AC-DC5** A dose wrongly closed inside the window (D2 fixture) is open again after `--apply`.
  A dose correctly closed outside the window stays closed.
- **AC-DC6** A weekly item with Tuesday slots created from a shifted Wednesday anchor (D3 fixture)
  keeps only Wednesday slots, apart from flagged rows a person acted on.
- **AC-DC7** Each repaired item has exactly one `data_repair` event, and its payload lets an
  operator see every change.
- **AC-DC8** Without §8 deployed (TZ-7 check failing), the script exits non-zero before any write.
- **AC-DC9** After DC-8 step 6, the tick log shows `0/0` between midnights for 24 h, and
  `repair_occurrences --dry-run` reports 0 violations.
- **AC-DC10** The read-only helper refuses a write (`CREATE`, `UPDATE`, `DELETE`) with an error
  and changes nothing.
