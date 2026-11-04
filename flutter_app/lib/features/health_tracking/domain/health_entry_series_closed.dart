import '../../../../core/utils/calendar_date.dart';
import 'entities/health_entry.dart';

/// Wire values for care item closed reason (CARE-STATUS-R-010).
const kCareClosedReasonEnded = 'ended';
const kCareClosedReasonStoppedByUser = 'stopped_by_user';

/// Whether the event series is closed (API `closed` or natural end).
bool isHealthEntrySeriesClosedAt(HealthEntry entry, DateTime now) {
  if (entry.status == 'closed' || entry.status == 'completed') return true;
  if (entry.frequency == HealthFrequency.once) {
    return entry.isCompleted;
  }
  if (entry.repeatEndDate == null) return false;
  final today = calendarDateOnly(now);
  final end = calendarDateOnly(entry.repeatEndDate!);
  return end.isBefore(today);
}

/// User-visible closed subtitle (English copy lives in detail layer for l10n).
String careItemClosedSubtitleLabel(String? careClosedReason) {
  final reasonLabel = careClosedReason == kCareClosedReasonStoppedByUser
      ? 'Stopped by you'
      : 'Ended';
  return 'Closed · $reasonLabel';
}
