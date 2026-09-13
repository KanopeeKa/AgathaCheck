import '../../../../core/utils/calendar_date.dart';
import 'entities/health_occurrence.dart';

/// Whether [occ] is missed relative to [now] (device local calendar).
bool isOccurrenceMissed(HealthOccurrence occ, DateTime now) {
  if (!occ.isPending) return false;
  final today = calendarDateOnly(now);
  final dueDay = calendarDateOnly(occ.scheduledDate);
  if (dueDay.isBefore(today)) return true;
  if (dueDay.isAfter(today)) return false;
  final time = occ.scheduledTime;
  if (time == null || time.isEmpty) return false;
  final parts = time.split(':');
  if (parts.length < 2) return false;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final dueInstant = DateTime(today.year, today.month, today.day, hour, minute);
  return now.isAfter(dueInstant);
}
