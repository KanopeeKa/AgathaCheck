# Calendar dates in Agatha Track

Some fields represent a **calendar day** (due date, date of birth, weight day,
health-issue start/end). Others represent an **instant in time** (`created_at`,
`marked_at`, notifications).

## Rules

| Kind | DB type | API wire format | Example fields |
|------|---------|-----------------|----------------|
| Calendar date | `DATE` (or date-only semantics) | `YYYY-MM-DD` | `next_due_date`, `date_of_birth`, `from_date` |
| Timestamp | `TIMESTAMPTZ` | ISO-8601 with timezone | `created_at`, `marked_at` |

**Do not** use `toISOString()` / `toIso8601String()` for calendar dates. A
PostgreSQL `DATE` read through node-pg becomes midnight UTC; serializing that
as `…T00:00:00.000Z` makes clients west of UTC display the **previous day**.

## Shared helpers

- **Flutter:** `flutter_app/lib/core/utils/calendar_date.dart`
  - `parseCalendarDate` — API → local `DateTime(y, m, d)`
  - `toCalendarDateString` — `DateTime` → `YYYY-MM-DD`
  - `calendarDateOnly` — normalize date-picker values
- **Node:** `server/lib/calendarDate.js`
  - `dateToIsoDate` — DB value → `YYYY-MM-DD` for JSON responses

## Date pickers

After `showDatePicker`, always normalize:

```dart
onChanged(calendarDateOnly(picked));
```

## Tests

- `flutter_app/test/core/utils/calendar_date_test.dart`
- `server/test/calendarDate.test.js`
- Model/route tests assert date-only JSON for calendar fields.
