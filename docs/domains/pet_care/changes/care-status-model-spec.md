---
title: Care status model — care item and care date (simplification)
owner: Product / Agent
audience: both
status: proposed
status_since: 2026-11-03
folds_into: docs/domains/pet_care/features/care-item-evolution.md
last_updated: 2026-11-04
---

# Care status model — care item and care date

**Status:** Proposed — agreed with product owner 2026-11-03, amended 2026-11-04 after the delivery-plan review. Part of
a wider plan still being written; do not implement from this doc alone.
**Folds into:** [care-item-evolution.md](../features/care-item-evolution.md) (lifecycle, occurrence status) and,
for schedule rules, [care-schedule-management.md](../features/care-schedule-management.md).
**Will supersede (on fold):** D-CIE-002 (no extra stored status), D-CIE-018 (lifecycle), D-CIE-024 (Not recorded as
an open status), D-CIE-034 / CARE-ITEM-R-008 (stack), CARE-ITEM-R-002 / D-CIH-013 (Finished/Archived chip), Restore
and `/reopen`.

**Guiding principle:** keep it simple — fewer types, fewer states, no transitional layers.

## Problem

- A care date has three stored statuses (`pending`, `completed`, `skipped`) and four hidden close reasons (`user`,
  `not_recorded`, `paused`, `system`). History does not receive the reason, so dates the system closed show as
  **Skipped** — the user never skipped them.
- A care item has five lifecycle words (Active, Paused, Finished, Archived, Deleted). Finished and Archived are
  identical on the wire (`status = 'completed'`), so a "closed care" list cannot be built.
- "Not recorded" is both an open status (stack, Review, Record earlier doses) and a close reason.

## Care date — outcome and timing

Two layers. The **outcome** is stored. The **timing** is computed and only applies to Open dates.

| Outcome (stored) | Meaning | Set by |
|---|---|---|
| Open | Still to do | — |
| Done | It happened | User |
| Skipped | Someone decided not to do it | User only |
| Not recorded | The date passed and nobody recorded it — the one thing we know | System only |

| Timing (computed, Open only) | When |
|---|---|
| Coming up | Future (existing wording and wire value `coming_up` kept) |
| Due | Today, before its time |
| Overdue | Past its time, still open |

There is no "closed" status for a care date, and no "cancelled": dates that had not come due when a schedule
changes, pauses or ends are removed, not kept.

## Care item — three statuses

| Status | Meaning | Subtitle |
|---|---|---|
| Active | Scheduling normally | — |
| Paused | No new dates; can resume | "Paused since 1 Sep" / "Paused until 12 Oct" |
| Closed | Nothing more will happen; read-only and final | **Ended** (one-off done — planned or recorded after the fact — or recurring care that reached its end) · **Stopped by you** (user closed it) |

Delete remains an action, not a status. There is no separate type for care recorded after the fact ("Record
something"): it is a one-off that is Done, so it is Closed · Ended like any other.

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-STATUS-R-001 | A care date stores exactly one outcome: Open, Done, Skipped or Not recorded; `close_reason` is retired with no replacement audit field (the outcome says who: Skipped = user, Not recorded = system) | Planned |
| CARE-STATUS-R-002 | Timing words **Coming up**, Due, Overdue are computed in the pet's home timezone and shown only on Open dates; wire values unchanged (`coming_up`, `due`, `overdue`) | Planned |
| CARE-STATUS-R-003 | Skipped is written only by a user action; the system never writes Skipped | Planned |
| CARE-STATUS-R-004 | Not recorded is written only by the system; it replaces every system-closed "Skipped" in History, agenda copy and CSV export (wording only, no new CSV columns) | Planned |
| CARE-STATUS-R-005 | Fixed schedule: an Open dose becomes Not recorded when the next dose of the same item is due; it leaves Needs attention and appears in History only | Planned |
| CARE-STATUS-R-006 | A Not recorded date can be recorded as **Done** (only) from History while its care item is Active or Paused | Planned |
| CARE-STATUS-R-007 | After it's done schedules have no next dose to trigger R-005: an Overdue date stays Open until the user acts or the item is paused or closed | Planned |
| CARE-STATUS-R-008 | Pausing or closing a care item: Open dates whose time has passed become Not recorded; Open dates not yet due are removed, with no history or ledger trace | Planned |
| CARE-STATUS-R-009 | Care item status is one of Active, Paused, Closed | Planned |
| CARE-STATUS-R-010 | A Closed item carries a closed reason shown as subtitle: Ended (one-off done or recurring end reached, no distinction) or Stopped by you | Planned |
| CARE-STATUS-R-011 | Closed is final and read-only: no reopen, no restore, no edit, no date actions; History is frozen | Planned |
| CARE-STATUS-R-012 | No reason is asked when the user skips a date | Planned |
| CARE-STATUS-R-013 | Existing data migrates: `skipped/user` → Skipped; `skipped/not_recorded` → Not recorded; `skipped/system` or `skipped/paused` already due → Not recorded, not yet due → removed; `completed` → Done. Items: `completed` with a `health_entry.closed` audit entry → Closed · Stopped by you; every other `completed` item (finished, recorded after the fact) → Closed · Ended. No other heuristic | Planned |
| CARE-STATUS-R-014 | Care details shows a **Close care** button at the bottom of the screen, in danger colour, on Active and Paused items; not shown on Closed items | Planned |
| CARE-STATUS-R-015 | Only the pet's owner can close a care; other people with access (carers, shared users) do not see the button and the server refuses the command | Planned |
| CARE-STATUS-R-016 | Close care asks for confirmation. The dialog says the care cannot be reopened. When Open dates have already started, it says "N dates will be marked Not recorded" and offers **Record them first** (closes the dialog and shows those dates in Needs attention) alongside **Close care** and Cancel | Planned |
| CARE-STATUS-R-017 | Closing sets the item to Closed · Stopped by you with a closed date and time (pet's home timezone); the schedule ends at that instant and no new dates are generated; reminders for the item stop | Planned |
| CARE-STATUS-R-018 | On close: Done, Skipped and Not recorded dates are unchanged and frozen; Open dates that have started become Not recorded; Open dates not yet started (later today, future, planned boosters) are removed. An untimed date has started from the beginning of its day | Planned |
| CARE-STATUS-R-019 | A Paused care can be closed; R-018 applies to any Open dates it still has | Planned |
| CARE-STATUS-R-020 | A Closed care leaves the agenda, Actions counts and dashboard. Care details is read-only: no app-bar Edit (pencil), no Edit / Pause / Resume / Plan another date / Restore / Delete in the ⋯ menu (Delete hidden for now), no **Edit schedule** link, no **Needs attention** section, no date actions. Details, Schedule summary and History stay visible | Planned |
| CARE-STATUS-R-021 | All care for a pet ends with a **Closed care** link (with count) when the pet has Closed items. It opens a list of Closed items using the care list row design, showing **Closed · Ended** or **Closed · Stopped by you** and **no dates**. Tapping a row opens the read-only Care details | Planned |
| CARE-STATUS-R-022 | Away plans: a Closed care is dropped from away plans that have not started; away plans already started or past keep it as it was | Planned |
| CARE-STATUS-R-023 | A care reaches Closed · Ended without user action when a one-off is Done (including care recorded after the fact, which is Closed · Ended at creation) or a recurring care passes its end date; R-020 and R-021 apply | Planned |
| CARE-STATUS-R-024 | The "Other care" section of All care no longer holds finished, archived or recorded items; they are in Closed care | Planned |
| CARE-STATUS-R-025 | Closing a care must not make Care Intelligence suggest that care again; verify, and add a guard only if it does | Planned |

## Delivery constraints

| ID | Constraint |
|----|------------|
| CARE-STATUS-R-026 | No compatibility layer: the Flutter web app ships with the server (single origin), so no dual-write, no legacy columns kept alongside, no value aliases and no "one release" deprecation window. Each migration changes values in place |
| CARE-STATUS-R-027 | Vertical slices: each PR delivers a user-visible outcome with its server, app, BDD and Playwright changes together. E2E is never deferred to a later PR |
| CARE-STATUS-R-028 | Slice order: (1) truthful History — care date outcome migration, Not recorded shown, record as Done; (2) Not recorded at the next dose, stack / Review / Record earlier doses removed; (3) pause and schedule rule R-008; (4) care item Closed status, natural Ended, read-only details; (5) Close care button, dialog, owner-only, R-018, reminders, away plans, Care Intelligence check; (6) Closed care list and canonical docs fold |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CARE-STATUS-D-001 | Care date = stored outcome (Open, Done, Skipped, Not recorded) + computed timing (Coming up, Due, Overdue) | Separates "what happened" from "how urgent"; removes hidden close reasons | Planned | 2026-11-03 | — |
| CARE-STATUS-D-002 | Skipped means a human decision only | "Skipped" on system-closed dates misleads users | Planned | 2026-11-03 | — |
| CARE-STATUS-D-003 | System outcome wording is **Not recorded** (FR existing string), not "Unknown" | It states the one fact we know: nothing was recorded | Planned | 2026-11-03 | — |
| CARE-STATUS-D-004 | A Fixed-schedule dose does not "close": it becomes Not recorded when the next dose is due, and can still be recorded | No "closed" status for care dates; removes open stacks and Review | Planned | 2026-11-03 | — |
| CARE-STATUS-D-005 | No "cancelled" outcome: not-yet-due dates are removed when a schedule changes, pauses or closes | Dates that never came due never existed for the pet | Planned | 2026-11-03 | — |
| CARE-STATUS-D-006 | Care item statuses: Active, Paused, Closed | Merges Finished, Archived and "close care" into one final state | Planned | 2026-11-03 | — |
| CARE-STATUS-D-007 | Closed subtitle: **Ended** (natural end, one-off or recurring, no distinction) or **Stopped by you** | One status, reason as context | Planned | 2026-11-03 | — |
| CARE-STATUS-D-008 | No skip reason for now | Keep the first version simple | Planned | 2026-11-03 | — |
| CARE-STATUS-D-009 | List name: **Closed care** | Simpler; matches the status word | Planned | 2026-11-03 | — |
| CARE-STATUS-D-010 | An untimed date today counts as started when closing → Not recorded | Same "started" rule as timed slots (beginning of day) | Planned | 2026-11-03 | — |
| CARE-STATUS-D-011 | Close confirmation counts dates becoming Not recorded and offers Record them first | Closing freezes them; give one last chance to record | Planned | 2026-11-03 | — |
| CARE-STATUS-D-012 | Owner only can close a care | Irreversible action | Planned | 2026-11-03 | — |
| CARE-STATUS-D-013 | Paused care can be closed | No reason to resume first | Planned | 2026-11-03 | — |
| CARE-STATUS-D-014 | Delete hidden on Closed care for now | Closed is the archive; revisit later | Planned | 2026-11-03 | — |
| CARE-STATUS-D-015 | Away plans not yet started drop a Closed care; started or past plans keep it | Past plans are history | Planned | 2026-11-03 | — |
| CARE-STATUS-D-016 | Keep **Coming up** (not "Upcoming") and wire `coming_up` | Existing UI word; a rename adds churn with no user benefit | Planned | 2026-11-04 | — |
| CARE-STATUS-D-017 | A Not recorded date can only be recorded as Done | The case discussed is "I actually gave it"; no new skip path | Planned | 2026-11-04 | — |
| CARE-STATUS-D-018 | Closed care list rows show no dates | Original request: "clearly closed with no dates associated" | Planned | 2026-11-04 | — |
| CARE-STATUS-D-019 | Care recorded after the fact is a one-off Done → Closed · Ended; no separate record-only type | Fewer types; whether it was recorded after or not does not matter, and a separate type adds data complexity | Planned | 2026-11-04 | — |
| CARE-STATUS-D-020 | No compatibility layer or dual-write; in-place migrations | Single-origin Flutter web: server and app ship together | Planned | 2026-11-04 | — |
| CARE-STATUS-D-021 | Backfill Stopped by you only from the `health_entry.closed` audit; everything else Ended | Archive was hidden in the ⋯ menu; misclassification is harmless; no heuristics | Planned | 2026-11-04 | — |
| CARE-STATUS-D-022 | Deliver in six vertical slices, Not recorded mechanism first, tests and E2E in each slice | Matches the original request to build the mechanism first; avoids a deferred E2E PR | Planned | 2026-11-04 | — |

## Open questions

None at present (2026-11-04).
