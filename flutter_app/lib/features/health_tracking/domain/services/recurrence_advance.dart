import '../../../../core/utils/calendar_date.dart';
import '../entities/health_entry.dart';

/// Calendar day difference (to − from), matching server `calendarDayDiff`.
int calendarDayDiff(DateTime from, DateTime to) {
  final fromDay = calendarDateOnly(from);
  final toDay = calendarDateOnly(to);
  return toDay.difference(fromDay).inDays;
}

DateTime addCalendarDays(DateTime date, int days) {
  return calendarDateOnly(date.add(Duration(days: days)));
}

/// Next calendar date after [base] for [entry]'s recurrence (server `advanceByFrequency`).
String advanceByFrequencyIso(DateTime base, HealthEntry entry) {
  final local = calendarDateOnly(base);
  final interval = entry.frequencyInterval < 1 ? 1 : entry.frequencyInterval;
  final customDays = entry.frequencyDays != null && entry.frequencyDays! > 0
      ? entry.frequencyDays!
      : interval;

  DateTime next;
  switch (entry.frequency) {
    case HealthFrequency.daily:
      next = DateTime(local.year, local.month, local.day + interval);
      break;
    case HealthFrequency.weekly:
      next = DateTime(local.year, local.month, local.day + 7 * interval);
      break;
    case HealthFrequency.monthly:
      next = DateTime(local.year, local.month + interval, local.day);
      break;
    case HealthFrequency.yearly:
      next = DateTime(local.year + interval, local.month, local.day);
      break;
    case HealthFrequency.custom:
      next = DateTime(local.year, local.month, local.day + customDays);
      break;
    case HealthFrequency.once:
      next = DateTime(local.year, local.month, local.day + interval);
      break;
  }
  return toCalendarDateString(calendarDateOnly(next))!;
}

/// One recurrence step in days from [today].
int intervalDaysForEntry(HealthEntry entry, DateTime today) {
  final base = calendarDateOnly(today);
  final nextIso = advanceByFrequencyIso(base, entry);
  final next = parseCalendarDate(nextIso)!;
  return calendarDayDiff(base, next).clamp(1, 366 * 5);
}
