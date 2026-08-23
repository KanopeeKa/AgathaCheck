---
title: Calendar dates in Agatha Track
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-21
tags: [documentation]
---
# Calendar dates in Agatha Track

Some fields represent a **calendar day** (due date, date of birth, weight day,
health-issue start/end). Others represent an **instant in time** (`created_at`,
`marked_at`, notifications).

## Rules

| Kind | DB type | API wire format | Example fields |
|------|---------|-----------------|----------------|
| Calendar date | `DATE` | `YYYY-MM-DD` | see inventory below |
| Timestamp | `TIMESTAMPTZ` | ISO-8601 with timezone | `created_at`, `marked_at` |

**Do not** use `toISOString()` / `toIso8601String()` for calendar dates. A
PostgreSQL `DATE` read through node-pg becomes midnight UTC; serializing that
as `…T00:00:00.000Z` makes clients west of UTC display the **previous day**.

**Do not** store calendar dates in `TIMESTAMPTZ` columns. A `YYYY-MM-DD` insert
is interpreted in the session timezone; reading the instant back with UTC date
components shifts the day for users east of UTC. `health_entries.next_due_date`
is a `DATE` column (migration `011_next_due_date_to_date.sql`).

All Node DB connections set `TIME ZONE 'UTC'` on connect (`server/bin/server.js`).

## Calendar-date field inventory

### Personal pets (`pets`, health, weight)

| Field | Table / entity | Flutter model / screen |
|-------|----------------|------------------------|
| `date_of_birth` | `pets` | `PetModel`, `pet_form_screen`, `pet_dob_section` |
| `neutered_date` | `pets` | `PetModel`, `pet_form_screen` |
| `start_date` | `health_entries` | `HealthEntryModel`, health entry forms |
| `next_due_date` | `health_entries` | `HealthEntryModel`, due-date pickers |
| `completed_on` | `health_entries`, `health_history` | `HealthEntryModel`, `HealthHistoryModel` |
| `repeat_end_date` | `health_entries` | `HealthEntryModel`, repeat-end picker |
| `start_date` / `end_date` | `health_issues` | `HealthIssueModel`, health issues section |
| `due_date` | `health_history` | `HealthHistoryModel` |
| `date` | `weight_entries` | `WeightEntryModel`, weight tracking section |

### Organisation pets & events

| Field | Table / entity | Flutter model / screen |
|-------|----------------|------------------------|
| `date_of_birth` | `pets` (org-owned) | `organization_providers` → `Pet` |
| `from_date` | `family_events` | `FamilyEvent`, org family-event APIs |
| `to_date` | `family_events` | `FamilyEvent` (completed-on for foster/placement) |
| `due_date` / `completed_on` | `family_event_history` | server `pets.js` family-event mark-complete |

Org pets are created via `POST /api/pets` with `organization_id`; family events
via `POST /api/pets/:id/family-events`. Both paths normalize writes with
`normalizeCalendarDateInput`.

### Sharing (read-only calendar fields)

| Field | Route | Flutter |
|-------|-------|---------|
| `date_of_birth` | `sharing.js` shared pet view | `shared_pet_screen` (`parseCalendarDate`) |
| `start_date` / `next_due_date` | `sharing.js` health summary | n/a (display only) |

## Shared helpers

- **Flutter:** `flutter_app/lib/core/utils/calendar_date.dart`
  - `parseCalendarDate` — API → local `DateTime(y, m, d)`
  - `toCalendarDateString` — `DateTime` → `YYYY-MM-DD`
  - `calendarDateOnly` — normalize date-picker values
- **Node:** `server/lib/calendarDate.js`
  - `dateToIsoDate` — DB value → `YYYY-MM-DD` for JSON responses
  - `normalizeCalendarDateInput` — request body → `YYYY-MM-DD` for DB writes
  - `todayCalendarIso` — today's calendar date on the server

## Date pickers

After `showDatePicker`, always normalize:

```dart
onChanged(calendarDateOnly(picked));
```

For user-facing calendar dates, display as **dd/MM/yyyy** via
`formatCalendarDateDisplay`. Use `showCalendarDatePicker` (from
`calendar_date_picker.dart`) so manual entry in the picker matches that format;
it passes a day-first Material locale (`en_GB` / `fr_FR`) without changing app
language.

`calendarDateOnly` / `toCalendarDateString` convert UTC-flagged instants through
`toLocal()` before reading Y-M-D. On Flutter web, a picked calendar day can be
represented as a UTC `DateTime` (e.g. July 8 00:00 CEST → `…T22:00:00.000Z`);
reading UTC `.day` would shift the stored date back one day east of UTC.

## Tests

- `flutter_app/test/core/utils/calendar_date_test.dart`
- `flutter_app/test/core/utils/calendar_date_fields_test.dart` — inventory-driven regression for every calendar-date field in models (see field inventory above)
- `flutter_app/test/helpers/calendar_date_field_expectations.dart`
- `server/test/calendarDate.test.js`
- Model tests: `pet_model_test.dart`, `health_entry_model_test.dart`,
  `health_issue_model_test.dart`, `weight_entry_model_test.dart`,
  `family_event_test.dart`
- Route tests assert date-only JSON on read and `YYYY-MM-DD` params on write:
  `pets.test.js`, `healthEntries.test.js`, `healthIssues.test.js`,
  `weightEntries.test.js`
