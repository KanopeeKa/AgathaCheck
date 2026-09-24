import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/domain/services/recurrence_advance.dart';
import 'package:pet_profile_app/features/health_tracking/domain/services/reschedule_occurrence_preview.dart';

HealthEntry _monthlyEntry({RecurrenceAnchor anchor = RecurrenceAnchor.fromDueDate}) {
  return HealthEntry(
    id: 'e1',
    petId: 'p1',
    name: 'Heartworm',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: parseCalendarDate('2026-01-01')!,
    nextDueDate: parseCalendarDate('2026-03-01'),
    recurrenceAnchor: anchor,
  );
}

void main() {
  test('advanceByFrequencyIso advances monthly', () {
    final entry = _monthlyEntry();
    final next = advanceByFrequencyIso(parseCalendarDate('2026-03-01')!, entry);
    expect(next, '2026-04-01');
  });

  test('gap preview compares actual vs usual when history exists', () {
    final entry = _monthlyEntry();
    final past = [
      HealthOccurrence(
        id: 'o1',
        entryId: 'e1',
        scheduledDate: parseCalendarDate('2026-02-01')!,
        status: 'completed',
        completedOn: parseCalendarDate('2026-02-01'),
      ),
    ];
    final last = lastClosedReferenceDate(entry, past);
    expect(last, parseCalendarDate('2026-02-01'));

    final preview = computeGapPreview(
      entry: entry,
      newDate: parseCalendarDate('2026-03-15')!,
      today: parseCalendarDate('2026-03-01')!,
      lastClosedDate: last,
    );
    expect(preview.hasComparison, isTrue);
    expect(preview.actualGapDays, 42);
    expect(preview.usualGapDays, greaterThan(0));
  });

  test('away plan prefill prefers day before absence start', () {
    final today = parseCalendarDate('2026-09-01')!;
    final prefill = awayPlanReschedulePrefillDate(
      startsOn: '2026-09-20',
      endsOn: '2026-09-27',
      today: today,
      minDate: today,
    );
    expect(prefill, parseCalendarDate('2026-09-19'));
  });

  test('previewNextCalendarDates returns two hops from due-date anchor', () {
    final entry = _monthlyEntry();
    final dates = previewNextCalendarDates(
      entry,
      parseCalendarDate('2026-05-10')!,
    );
    expect(dates, hasLength(2));
    expect(toCalendarDateString(dates[0]), '2026-06-10');
    expect(toCalendarDateString(dates[1]), '2026-07-10');
  });
}
