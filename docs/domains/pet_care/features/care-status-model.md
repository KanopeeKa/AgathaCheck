---
title: Care status model
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care-status-model
status: active
last_updated: 2026-11-06
related_prs: []
---

# Care status model

## Summary / scope

- **Owns:** Care date outcomes (Open, Done, Skipped, Not recorded), care item lifecycle (Active, Paused, Closed), Close care, Closed care list, read-only closed details.
- **Does not own:** Care Intelligence copy, away-plan layout (see [care-context.md](./care-context.md)), taxonomy blocks.
- **Depends on:** [care-schedule-management.md](./care-schedule-management.md) (occurrence sync), [care-item-evolution.md](./care-item-evolution.md) (detail and agenda presentation).

Delivered by execute-plan `care-status-model` (six vertical slices, 2026-11).

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-STATUS-MODEL-R-001 | Care date stores one outcome: Open, Done, Skipped, or Not recorded; legacy `close_reason` retired | Live |
| CARE-STATUS-MODEL-R-004 | Not recorded replaces system-closed Skipped in History, agenda copy, and CSV | Live |
| CARE-STATUS-MODEL-R-005 | Fixed schedule: Open dose → Not recorded when next dose is due | Live |
| CARE-STATUS-MODEL-R-006 | Not recorded can be recorded as Done from History while item Active or Paused | Live |
| CARE-STATUS-MODEL-R-008 | Pause/close: started Open → Not recorded; not-yet-due Open removed | Live |
| CARE-STATUS-MODEL-R-009 | Item status: Active, Paused, Closed | Live |
| CARE-STATUS-MODEL-R-010 | Closed subtitle: Ended or Stopped by you | Live |
| CARE-STATUS-MODEL-R-011 | Closed is final and read-only | Live |
| CARE-STATUS-MODEL-R-014 | Close care button on Active/Paused items | Live |
| CARE-STATUS-MODEL-R-015 | Owner-only close | Live |
| CARE-STATUS-MODEL-R-016 | Close confirmation with Record them first when needed | Live |
| CARE-STATUS-MODEL-R-018 | Close date matrix (started Open → Not recorded; future Open removed) | Live |
| CARE-STATUS-MODEL-R-020 | Closed leaves agenda; read-only detail | Live |
| CARE-STATUS-MODEL-R-021 | All care ends with **Closed care** link (count); list rows show Closed · Ended/Stopped by you with no dates | Live |
| CARE-STATUS-MODEL-R-024 | Other care holds paused only; finished/archived/recorded items appear under Closed care | Live |
| CARE-STATUS-MODEL-R-025 | Close care does not re-trigger Care Intelligence missing-care suggestions | Live |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| Given a pet with a user-closed item, When All care is opened, Then Closed care (1) opens a list without due dates and read-only detail | CARE-STATUS-MODEL-R-021 | test: e2e/playwright/tests/care.agenda.spec.ts#Closed care link lists stopped care without dates |
| Given a one-off Done item, When All care is opened, Then it is not under Other care and appears under Closed care | CARE-STATUS-MODEL-R-024 | test: flutter_app/test/features/pet_profile/presentation/widgets/all_care/all_care_list_test.dart#shows Closed care link for closed items not in Other care |

## UX surfaces

- **All care** (`/pet/:petId/events`): agenda, Other care (paused), **Closed care** footer link.
- **Closed care** (pushed list): closed items only; tap → read-only Care details.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CARE-STATUS-MODEL-D-009 | List name **Closed care** | Matches status word | Live | 2026-11-03 | — |
| CARE-STATUS-MODEL-D-018 | Closed list rows show no dates | Clear archive rows | Live | 2026-11-04 | — |
| CARE-STATUS-MODEL-D-019 | Migration 104 uses `CURRENT_DATE` / `LOCALTIME` at apply time | Known limitation for TZ edge cases; run `node server/scripts/care/report_104_migration_impact.js` before PROD and attach grouped counts to the release | Live | 2026-11-06 | — |

## Still open

None.
