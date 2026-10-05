import '../../../../core/utils/calendar_date.dart';
import 'entities/health_entry.dart';

/// Whether the event series is closed (W15 close or one-time completed).
bool isHealthEntrySeriesClosedAt(HealthEntry entry, DateTime now) {
  if (entry.status == 'completed') return true;
  if (entry.frequency == HealthFrequency.once) {
    return entry.isCompleted;
  }
  if (entry.repeatEndDate == null) return false;
  final today = calendarDateOnly(now);
  final end = calendarDateOnly(entry.repeatEndDate!);
  return end.isBefore(today);
}
