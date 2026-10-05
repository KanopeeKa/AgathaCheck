# Care schedule status source (EX-11)

**Policy:** For any `HealthEntry` loaded from the API (list, detail, agenda), **`CareItemSchedule` on `HealthEntry.schedule`** is the only source for overdue / due-today / agenda grouping. The server sends `as_of` (calendar date, optional time, timezone) with `open_occurrences`; Flutter maps that wire shape through `care_item` (`CareItemSchedule`, `leadingOccurrence`, `CareTemporalGroupingService.groupForSchedule`).

**Device-clock fallbacks** in `HealthEntry.isOverdue` / `isDueToday` apply only when `schedule == null` — typically **widget tests**, **local form drafts**, or other in-memory entries that were never hydrated from a server read. They compare `nextDueDate` to `DateTime.now()` on the device. **Do not rely on those branches in production UI** after login; always pass server-backed entries with `schedule` populated.

**Production rule:** Pet Care surfaces that show care status must use entries from `CareItemsController` / health entry reads that include `schedule`. If `schedule` is missing on a live row, treat it as a bug (stale client or missing parse), not as an invitation to infer status from `next_due_date` + device clock.

**Related:** `care-next-occurrence-c1a7` EX-11 · `flutter_app/test/features/pet_care/domain/services/care_temporal_grouping_schedule_test.dart` · `docs/domains/pet_care/features/care-schedule-management.md`
