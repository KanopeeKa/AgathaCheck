import '../../../../core/utils/calendar_date.dart';
import '../entities/health_entry.dart';
import '../entities/health_occurrence.dart';
import '../entities/recurrence_anchor.dart';
import 'recurrence_advance.dart';

class RescheduleGapPreview {
  const RescheduleGapPreview({
    this.actualGapDays,
    required this.usualGapDays,
    required this.hasPriorDose,
  });

  final int? actualGapDays;
  final int usualGapDays;
  final bool hasPriorDose;

  bool get hasComparison =>
      hasPriorDose && actualGapDays != null && actualGapDays != usualGapDays;
}

/// Reference date for gap math (R-C2), aligned with server `loadLastClosedOccurrenceDateIso`.
DateTime? lastClosedReferenceDate(
  HealthEntry entry,
  List<HealthOccurrence> pastOccurrences,
) {
  if (pastOccurrences.isEmpty) return null;
  final sorted = List<HealthOccurrence>.from(pastOccurrences)
    ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  final row = sorted.first;
  if (entry.recurrenceAnchor == RecurrenceAnchor.fromDueDate) {
    return calendarDateOnly(row.scheduledDate);
  }
  return calendarDateOnly(row.completedOn ?? row.scheduledDate);
}

RescheduleGapPreview computeGapPreview({
  required HealthEntry entry,
  required DateTime newDate,
  required DateTime today,
  DateTime? lastClosedDate,
}) {
  final usual = intervalDaysForEntry(entry, today);
  if (lastClosedDate == null) {
    return RescheduleGapPreview(usualGapDays: usual, hasPriorDose: false);
  }
  final actual = calendarDayDiff(lastClosedDate, newDate);
  return RescheduleGapPreview(
    actualGapDays: actual,
    usualGapDays: usual,
    hasPriorDose: true,
  );
}

List<DateTime> previewNextCalendarDates(
  HealthEntry entry,
  DateTime newDate, {
  int count = 2,
}) {
  if (entry.frequency == HealthFrequency.once) return const [];
  var cursor = calendarDateOnly(newDate);
  final dates = <DateTime>[];
  for (var i = 0; i < count; i++) {
    final nextIso = advanceByFrequencyIso(cursor, entry);
    final next = parseCalendarDate(nextIso);
    if (next == null) break;
    dates.add(calendarDateOnly(next));
    cursor = next;
  }
  return dates;
}

DateTime? previewNextCompletionEstimate(HealthEntry entry, DateTime newDate) {
  if (entry.frequency == HealthFrequency.once) return null;
  final iso = advanceByFrequencyIso(newDate, entry);
  return parseCalendarDate(iso);
}

/// Allowed pick range for reschedule (past disabled; server enforces the rest).
({DateTime firstDate, DateTime? lastDate}) reschedulePickerBounds({
  required HealthEntry entry,
  required HealthOccurrence occurrence,
  required DateTime today,
  DateTime? lastClosedDate,
}) {
  var first = calendarDateOnly(today);
  if (lastClosedDate != null) {
    final afterClosed = addCalendarDays(lastClosedDate, 1);
    if (afterClosed.isAfter(first)) {
      first = afterClosed;
    }
  }

  DateTime? last;
  if (entry.frequency != HealthFrequency.once) {
    final nextHopIso = advanceByFrequencyIso(
      calendarDateOnly(occurrence.scheduledDate),
      entry,
    );
    final nextHop = parseCalendarDate(nextHopIso);
    if (nextHop != null) {
      last = addCalendarDays(nextHop, -1);
      if (last.isBefore(first)) {
        last = first;
      }
    }
  }

  return (firstDate: first, lastDate: last);
}

/// Away-plan prefill: S−1, or E+1 when S−1 is not viable (R-C8).
DateTime awayPlanReschedulePrefillDate({
  required String startsOn,
  required String endsOn,
  required DateTime today,
  required DateTime minDate,
  DateTime? maxDate,
}) {
  final start = parseCalendarDate(startsOn);
  final end = parseCalendarDate(endsOn);
  final todayDay = calendarDateOnly(today);

  DateTime candidate;
  if (start != null) {
    candidate = addCalendarDays(start, -1);
  } else if (end != null) {
    candidate = addCalendarDays(end, 1);
  } else {
    candidate = todayDay;
  }

  bool isViable(DateTime d) {
    if (d.isBefore(minDate)) return false;
    if (maxDate != null && d.isAfter(maxDate)) return false;
    return true;
  }

  if (isViable(candidate)) return candidate;

  if (end != null) {
    final afterReturn = addCalendarDays(end, 1);
    if (isViable(afterReturn)) return afterReturn;
  }

  if (maxDate != null && !candidate.isAfter(maxDate)) {
    return maxDate.isBefore(minDate) ? minDate : maxDate;
  }
  return minDate;
}
