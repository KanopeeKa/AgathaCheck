import '../../../../../core/utils/calendar_date.dart';

/// Validation rules aligned with server planned-absence window checks.
class PlannedAbsenceDateRules {
  const PlannedAbsenceDateRules._();

  static const maxHorizonDays = 366;

  static DateTime todayCalendar() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime maxEndDate([DateTime? today]) {
    final base = today ?? todayCalendar();
    return base.add(const Duration(days: maxHorizonDays));
  }

  static bool isValidRange(DateTime? startsOn, DateTime? endsOn) {
    if (startsOn == null || endsOn == null) return false;
    if (endsOn.isBefore(startsOn)) return false;
    return !endsOn.isAfter(maxEndDate());
  }

  static String? startsOnWire(DateTime? date) => toCalendarDateString(date);

  static String? endsOnWire(DateTime? date) => toCalendarDateString(date);
}
