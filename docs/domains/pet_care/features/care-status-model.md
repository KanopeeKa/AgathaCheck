---
title: Care status model
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care-status-model
status: active
last_updated: 2026-11-11
related_prs: [2083, 2095, 2107, 2108, 2109, 2110, 2111]
---

# Care status model

## Summary / scope

- **Owns:** Care date outcomes (Open, Done, Skipped, Not recorded), care item lifecycle (Active, Paused, Closed), Close care, Closed care list, read-only closed details.
- **Does not own:** Care Intelligence copy, away-plan layout (see [care-context.md](./care-context.md)), taxonomy blocks.
- **Depends on:** [care-schedule-management.md](./care-schedule-management.md) (occurrence sync), [care-item-evolution.md](./care-item-evolution.md) (detail and agenda presentation).

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-STATUS-MODEL-R-001 | Care date stores one outcome: Open, Done, Skipped, or Not recorded; legacy `close_reason` retired | Live |
| CARE-STATUS-MODEL-R-004 | Not recorded replaces system-closed Skipped in History, agenda copy, and CSV | Live |
| CARE-STATUS-MODEL-R-005 | Fixed schedule: Open dose → Not recorded when next dose is due | Live |
| CARE-STATUS-MODEL-R-006 | Not recorded can be recorded as Done from History while item Active or Paused | Live |
| CARE-STATUS-MODEL-R-008 | Pause/close: started Open → Not recorded; not-yet-due Open removed | Live |
| CARE-STATUS-MODEL-R-009 | Item status: Active, Paused, Closed | Live |
| CARE-STATUS-MODEL-R-010 | Closed status label: **Ended** or **Closed by you** (detail chip and list pill; no `Closed · ` prefix) | Live |
| CARE-STATUS-MODEL-R-011 | Closed is final and read-only | Live |
| CARE-STATUS-MODEL-R-014 | Close care button on Active/Paused items | Live |
| CARE-STATUS-MODEL-R-015 | Owner-only close | Live |
| CARE-STATUS-MODEL-R-016 | Close confirmation with Record them first when needed | Live |
| CARE-STATUS-MODEL-R-018 | Close date matrix (started Open → Not recorded; future Open removed) | Live |
| CARE-STATUS-MODEL-R-020 | Closed leaves agenda; read-only detail | Live |
| CARE-STATUS-MODEL-R-021 | All care ends with **Closed care** link (count); closed list rows use R-026/R-027 (cadence subtitle, grey stop pill, no due dates on pill) | Live |
| CARE-STATUS-MODEL-R-024 | Other care holds paused only; finished/archived/recorded items appear under Closed care | Live |
| CARE-STATUS-MODEL-R-025 | Close care does not re-trigger Care Intelligence missing-care suggestions | Live |
| CARE-STATUS-MODEL-R-026 | Paused and closed list rows use the active-row format: title, then subtitle `category · cadence` (prefixed with the pet name on the all-pets Care events list, where the pill no longer holds the pet name); no tick | Live |
| CARE-STATUS-MODEL-R-027 | Paused and closed list rows show one neutral grey status pill (same grey as Not recorded, never success or warning colours, no dates): pause-in-circle icon + **Paused**; stop-in-circle icon + **Closed by you** (user-closed) or **Ended** (ended, finished one-off, recorded-only) | Live |
| CARE-STATUS-MODEL-R-028 | R-026 and R-027 apply identically on the all-pets Care events list, All care › Other care, and the Closed care list | Live |
| CARE-STATUS-MODEL-R-029 | Closed wording is **Closed by you** / **Ended** everywhere, including the Care details chip, with no `Closed · ` prefix; French: En pause, Fermé par vous, Terminé | Live |
| CARE-STATUS-MODEL-R-030 | Global **All care** (`/pc/events`): **Paused care** and **Closed care** as collapsible sections (collapsed by default); same row rules as R-026/R-027 | In delivery |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| Given a pet with a user-closed item, When All care is opened, Then Closed care (1) opens a list whose row shows **Closed by you** on a grey pill with no due date and read-only detail | CARE-STATUS-MODEL-R-021, CARE-STATUS-MODEL-R-027, CARE-STATUS-MODEL-R-029 | test: e2e/playwright/tests/care.agenda.spec.ts#Closed care link lists stopped care without dates |
| Given a paused care item, When All care Other care is shown, Then the row shows **Paused** on a grey pill and no Mark done control | CARE-STATUS-MODEL-R-026, CARE-STATUS-MODEL-R-027 | test: flutter_app/test/features/pet_profile/presentation/widgets/all_care/all_care_list_test.dart#planned care uses the agenda; paused care follows without a tick |
| Given a one-off Done item, When All care is opened, Then it is not under Other care and appears under Closed care | CARE-STATUS-MODEL-R-024 | test: flutter_app/test/features/pet_profile/presentation/widgets/all_care/all_care_list_test.dart#shows Closed care link for closed items not in Other care |
| Given owner closes recurring parasite prevention care, When S1 missing-recurring runs, Then no new suggestion for that item | CARE-STATUS-MODEL-R-025 | test: server/test/suggestions/s1MissingRecurringCare.test.js |

## UX surfaces

- **All care** (`/pet/:petId/events`): agenda, Other care (paused), **Closed care** footer link.
- **All care** (`/pc/events`, all pets): agenda (interim), collapsible **Paused care** and **Closed care**; pet chips + `?pet=` ([delivery plan](../changes/all-care-by-item-delivery-plan.md)).
- **Closed care** (pushed list): closed items only; tap → read-only Care details.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CARE-STATUS-MODEL-D-009 | List name **Closed care** | Matches status word | Live | 2026-11-03 | — |
| CARE-STATUS-MODEL-D-018 | Closed list rows show no dates | Clear archive rows | Live | 2026-11-04 | — |
| CARE-STATUS-MODEL-D-019 | Migration 104 uses `CURRENT_DATE` / `LOCALTIME` at apply time | Known limitation for TZ edge cases; run `node server/scripts/care/report_104_migration_impact.js` before PROD and attach grouped counts to the release | Live | 2026-11-06 | #2108 |
| CARE-STATUS-MODEL-D-020 | R-025: closed recurring care still counts for S1 missing-recurring | Close care must not re-open Care Intelligence parasite-prevention nudge | Live | 2026-11-06 | #2109 |
| CARE-STATUS-MODEL-D-021 | Ledger NNN SQL runs inside the migrate runner outer transaction | Strip semicolon-only top-level `BEGIN`/`COMMIT` at apply; lint changed files; `txid_current()` guard detects inner commits | Live | 2026-11-06 | #2107 |
| CARE-STATUS-MODEL-D-022 | R-014: Close care at end of detail page | Under History in the scrolling content; not pinned to the bottom of the screen | Live | 2026-11-07 | — |
| CARE-STATUS-MODEL-D-023 | R-027: paused and closed pills are neutral grey with their own icon and text | The pill took its icon and colour from stale dates (red overdue on paused, green tick on closed) and held the pet name on the all-pets list; paused and closed are not urgent and not a success | Live | 2026-11-10 | — |
| CARE-STATUS-MODEL-D-024 | R-027: closed icon is stop-in-circle | Pairs with the pause icon and reads as stopped; padlock suggests a permissions problem, archive box is unclear at pill size, no-entry reads as a warning | Live | 2026-11-10 | — |
| CARE-STATUS-MODEL-D-025 | R-029: **Closed by you** replaces **Stopped by you**; `Closed · ` prefix dropped | Matches the Close care action and the status word; the grey pill and icon already say closed | Live | 2026-11-10 | — |
| CARE-STATUS-MODEL-D-026 | R-026: closed rows show cadence | Same format as active rows; cadence is not a date, so D-018 still holds | Live | 2026-11-10 | — |
| CARE-STATUS-MODEL-D-027 | R-027: paused pill reads **Paused** only, without the resume date | Keeps the pill short; the resume date stays on Care details | Live | 2026-11-10 | — |

## Still open

None.
