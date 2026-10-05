import '../../../../core/utils/calendar_date.dart';

/// First calendar day strictly after [asOf] that is not already reserved.
DateTime defaultPlanAnotherDate({
  required DateTime asOf,
  Iterable<DateTime> reservedDates = const [],
}) {
  final reserved = reservedDates.map(calendarDateOnly).toSet();
  var candidate = calendarDateOnly(asOf).add(const Duration(days: 1));
  final limit = DateTime(asOf.year + 6);
  while (reserved.contains(candidate) && candidate.isBefore(limit)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
