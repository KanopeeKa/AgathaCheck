# Bug spec — "This date is no longer open" on Not recorded doses

Status: analysis only, no code yet · Surface: server (`server/lib/care/occurrence/**`, `server/routes/healthEntries/occurrencesRouter.js`) + Flutter (`flutter_app/lib/features/care_item/**`)

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

## 3. Is the care tick running?

The tick can't be checked from this repo: it runs from the host crontab (o2switch cPanel), see
`docs/ops/care-tick.md`. **The report itself strongly suggests it is not processing this item:** a
working tick closes the Sep 30 slots within 15 minutes of pet-home midnight on Oct 4. After that
they would no longer be listed under Needs attention. (This assumes the screenshot was taken on or
after Oct 4 in the pet's time zone.)

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
   If this prints `"closed": 2` (or more) and the Sep 30 rows disappear from the app, the tick
   code works and only the cron entry is broken.
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

1. **Server — consistency:** FR-1, FR-8, FR-10 (groups A, G, H; AC-I1, I3).
2. **Server — bulk partial success:** FR-6, FR-7 server side (group E; AC-I2).
3. **Flutter — states, actions, errors:** FR-3 to FR-5, FR-7 client side, FR-9 (groups B–F;
   AC-I4, I5).
