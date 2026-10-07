# Care schedule status source (EX-11)

**Canonical rule:** CARE-SCHEDULE-MANAGEMENT-R-011 in `docs/domains/pet_care/features/care-schedule-management.md` §Client schedule status (Flutter).

**Agent lesson:** If `schedule` is missing on a live API row in production UI, treat it as a bug (stale client or parse failure) — do not infer status from `next_due_date` + device clock.

**Tests:** `flutter_app/test/features/pet_care/domain/services/care_temporal_grouping_schedule_test.dart`
