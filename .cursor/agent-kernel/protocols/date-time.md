# Protocol: date-time

**When:** Reminders, recurrence, medications, schedules, fostering sessions, notifications, timeline dates.

**Canonical:** `docs/architecture/calendar-dates.md`.

---

## 1. Distinguish

| Concept | Wire / storage |
|---------|----------------|
| Calendar date (user-facing day) | `YYYY-MM-DD` |
| Local time / schedule | Document timezone semantics |
| UTC instant | Only when true instant required |

## 2. Invariants

- Do not blindly convert calendar dates to UTC midnight timestamps
- DST and timezone edges considered for notifications/recurrence
- API and Flutter use same calendar-date contract

## 3. Tests

- Boundary: month/year rollover, DST transition (where applicable)
- Invalid date strings rejected (`validation.md`)

## 4. Verification

Jest + Flutter tests for affected parsers/schedulers; calendar date helpers in `calendarDate.js`.
