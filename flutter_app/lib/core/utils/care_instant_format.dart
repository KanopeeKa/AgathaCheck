import 'package:intl/intl.dart';

import '../../features/health_tracking/presentation/widgets/health_entry_status.dart';

/// Wall-clock time for care UI (`HH:mm`, 24-hour, not locale 12h).
final DateFormat careWallClockTimeFormat = DateFormat('HH:mm');

/// Calendar label (`dd MMM yy`) for a wall-clock instant in the local zone.
String formatCareRecordedCalendarDate(DateTime markedAt) =>
    formatHealthEntryStatusDate(markedAt);

/// 24-hour time for a wall-clock instant in the local zone.
String formatCareWallClockTime24(DateTime markedAt) =>
    careWallClockTimeFormat.format(markedAt);

/// Normalises API `scheduled_time` (`HH:mm` or `HH:mm:ss`) for display.
String formatCareScheduledTime24(String? time) {
  if (time == null || time.isEmpty) return '';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Due instant for history-style rows: `{date}` or `{date} at {time}`.
String formatCareDueInstant({
  required DateTime scheduledDate,
  String? scheduledTime,
  required String Function(String date) dateOnly,
  required String Function(String date, String time) dateAtTime,
}) {
  final date = formatHealthEntryStatusDate(scheduledDate);
  final time = formatCareScheduledTime24(scheduledTime);
  if (time.isEmpty) return dateOnly(date);
  return dateAtTime(date, time);
}
